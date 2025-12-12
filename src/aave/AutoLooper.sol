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
