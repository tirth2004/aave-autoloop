// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {WETH, USDC, UNISWAP_V3_POOL_FEE_WETH_USDC, POOL} from "../Constants.sol";

import {Borrow} from "./Borrow.sol";
import {Swap} from "./Swap.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";

contract AutoLooper is Borrow, Swap {
    uint16 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant HF_SCALE = 1e18;

    IPool public constant aavePool = IPool(POOL); // just for view helpers / events

    struct OpenParams {
        uint256 initialCollateralWeth; // WETH user sends in
        uint8 loops; // how many loop iterations
        uint16 borrowBps; // % of max borrow to use each loop (e.g. 7000 = 70%)
        uint256 minHealthFactor; // e.g. 1.3e18
        uint256 minSwapOut; // min out per swap, 0 for now
    }

    event LoopStep(
        uint8 indexed step,
        uint256 borrowedUsdc,
        uint256 swappedToWeth,
        uint256 healthFactor
    );

    event LoopOpened(
        address indexed user,
        uint8 loopsDone,
        uint256 finalHealthFactor,
        uint256 totalCollateralBase,
        uint256 totalDebtBase
    );

    event PositionUnwound(
        address indexed user,
        address indexed recipient,
        uint256 usdcRepaid,
        uint256 wethReturned,
        uint256 usdcLeftover
    );

    /// @notice user opens a leveraged long WETH position (WETH collateral, borrow USDC, swap -> WETH, resupply)
    function openPosition(OpenParams calldata params) external {
        require(params.initialCollateralWeth > 0, "no collateral");
        require(params.loops > 0, "no loops");
        require(
            params.borrowBps > 0 && params.borrowBps < BPS_DENOMINATOR,
            "borrowBps out of range"
        );

        // 1) Pull WETH from user into THIS contract (AutoLooper)
        IERC20(WETH).transferFrom(
            msg.sender,
            address(this),
            params.initialCollateralWeth
        );

        // 2) Supply initial collateral to Aave (Borrow.supply)
        supply(WETH, params.initialCollateralWeth);

        // 3) Loop a few times:
        uint8 loopsDone = 0;

        for (uint8 i = 0; i < params.loops; i++) {
            // How much USDC could we borrow at most right now?
            uint256 maxBorrowUsdc = approxMaxBorrow(USDC);
            if (maxBorrowUsdc == 0) break;

            uint256 amountToBorrow = (maxBorrowUsdc * params.borrowBps) /
                BPS_DENOMINATOR;
            if (amountToBorrow == 0) break;

            // 3a) Borrow USDC against existing WETH collateral
            borrow(USDC, amountToBorrow);

            // 3b) Swap USDC -> WETH (your working swapExactInputSingle)
            uint256 amountOutWeth = swapExactInputSingle(
                USDC,
                WETH,
                UNISWAP_V3_POOL_FEE_WETH_USDC,
                amountToBorrow,
                params.minSwapOut,
                address(this)
            );

            // 3c) Resupply extra WETH as more collateral
            supply(WETH, amountOutWeth);

            // 3d) Check health factor, fail fast if too risky
            uint256 hf = getHealthFactor();
            emit LoopStep(i, amountToBorrow, amountOutWeth, hf);

            require(hf >= params.minHealthFactor, "HF below min");

            loopsDone++;
        }

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            ,
            ,
            uint256 finalHf
        ) = aavePool.getUserAccountData(address(this));

        emit LoopOpened(
            msg.sender,
            loopsDone,
            finalHf,
            totalCollateralBase,
            totalDebtBase
        );

        require(finalHf >= params.minHealthFactor, "final HF below min");
    }

    /// @notice Unwind the leveraged position using user-provided USDC:
    ///         1) User sends USDC to this contract
    ///         2) Contract repays all USDC debt on Aave
    ///         3) Contract withdraws all WETH collateral
    ///         4) Sends all WETH + leftover USDC to `recipient`
    /// @dev Assumes the position is: collateral = WETH, debt = USDC.
    function unwindWithUserUSDC(address recipient) external {
        require(recipient != address(0), "bad recipient");

        // 1) How much USDC debt does this contract have?
        // Reuses Borrow.getVariableDebt(address token)
        uint256 debt = getVariableDebt(USDC);
        require(debt > 0, "no debt to unwind");

        // 2) Pull USDC from the caller. They must have approved this contract first.
        IERC20(USDC).transferFrom(msg.sender, address(this), debt);

        // 3) Approve Aave Pool & repay all USDC variable debt
        IERC20(USDC).approve(address(pool), debt);

        uint256 repaid = pool.repay({
            asset: USDC,
            amount: type(uint256).max, // repay full variable debt
            interestRateMode: 2, // 2 = variable rate
            onBehalfOf: address(this)
        });

        // Double-check that the debt is really gone
        uint256 remainingDebt = getVariableDebt(USDC);
        require(remainingDebt == 0, "debt not fully repaid");

        // 4) Withdraw all WETH collateral back to this contract
        IPool.ReserveData memory reserve = aavePool.getReserveData(WETH);
        uint256 aTokenBal = IERC20(reserve.aTokenAddress).balanceOf(
            address(this)
        );

        if (aTokenBal > 0) {
            // type(uint256).max = withdraw full aToken balance
            aavePool.withdraw({
                asset: WETH,
                amount: type(uint256).max,
                to: address(this)
            });
        }

        // 5) Send all WETH + leftover USDC to recipient
        uint256 wethReturned = IERC20(WETH).balanceOf(address(this));
        uint256 usdcLeftover = IERC20(USDC).balanceOf(address(this));

        if (wethReturned > 0) {
            IERC20(WETH).transfer(recipient, wethReturned);
        }
        if (usdcLeftover > 0) {
            IERC20(USDC).transfer(recipient, usdcLeftover);
        }

        emit PositionUnwound(
            msg.sender,
            recipient,
            repaid,
            wethReturned,
            usdcLeftover
        );
    }

    // ---------- OPTIONAL VIEW HELPERS FOR TESTS / UI ----------

    function getPositionData()
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 healthFactor
        )
    {
        (totalCollateralBase, totalDebtBase, , , , healthFactor) = aavePool
            .getUserAccountData(address(this));
    }
}
