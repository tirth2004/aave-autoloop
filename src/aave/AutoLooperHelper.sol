// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";
import {WETH, USDC, POOL} from "../Constants.sol";
import {AutoLooper} from "./AutoLooper.sol";

/// @notice Helper contract for AutoLooper that can be called from Reactive Network
/// @dev This contract manages opening/closing positions and checking health factors
contract AutoLooperHelper {
    IPool public constant aavePool = IPool(POOL);

    AutoLooper public immutable autoLooper;
    address public immutable owner;
    address public immutable recipient;

    bool public isActive;

    uint256 public constant UNWIND_THRESHOLD_HF = 1.05e18; // Can change acc to needs

    event PositionOpened(
        address indexed caller,
        uint8 loopsDone,
        uint256 finalHealthFactor
    );
    event PositionClosed(
        address indexed caller,
        uint256 usdcRepaid,
        uint256 wethReturned
    );
    event HealthFactorChecked(uint256 healthFactor, bool shouldUnwind);
    event PositionOpenFailed(string reason);
    event UnwindFailed(string reason);

    constructor(address _autoLooper, address _owner, address _recipient) {
        require(_autoLooper != address(0), "bad autolooper");
        require(_owner != address(0), "bad owner");
        require(_recipient != address(0), "bad recipient");

        autoLooper = AutoLooper(_autoLooper);
        owner = _owner;
        recipient = _recipient;
        isActive = false;
    }

    /// @notice Opens a position via AutoLooper using WETH from owner
    /// @dev Called by reactive contract via callback, or manually from frontend
    /// @param params AutoLooper.OpenParams struct
    function openPositionForReactive(
        AutoLooper.OpenParams calldata params
    ) external {
        require(!isActive, "position already open");
        require(params.initialCollateralWeth > 0, "no collateral");

        IERC20(WETH).transferFrom(
            owner,
            address(this),
            params.initialCollateralWeth
        );

        IERC20(WETH).approve(address(autoLooper), params.initialCollateralWeth);

        try autoLooper.openPosition(params) {
            isActive = true;

            (, , uint256 finalHf) = autoLooper.getPositionData();
            emit PositionOpened(msg.sender, params.loops, finalHf);
        } catch Error(string memory reason) {
            isActive = false;
            emit PositionOpenFailed(reason);

            IERC20(WETH).transfer(owner, params.initialCollateralWeth);
        } catch {
            isActive = false;
            emit PositionOpenFailed("unknown error");
            // Return WETH to owner if position opening failed
            IERC20(WETH).transfer(owner, params.initialCollateralWeth);
        }
    }

    /// @notice Checks health factor and unwinds if below threshold
    /// @dev Called by reactive contract on each price feed update
    function checkAndUnwind() external {
        require(isActive, "position not open");

        (, , , , , uint256 healthFactor) = aavePool.getUserAccountData(
            address(autoLooper)
        );

        emit HealthFactorChecked(
            healthFactor,
            healthFactor < UNWIND_THRESHOLD_HF
        );

        // If health factor is below threshold, unwind
        if (healthFactor < UNWIND_THRESHOLD_HF) {
            _unwindPosition();
        }
    }

    /// @notice Manually close position from frontend
    /// @dev Safe unwind regardless of health factor
    function closePosition() external {
        require(isActive, "position not open");
        _unwindPosition();
    }

    /// @notice Internal function to unwind the position
    function _unwindPosition() internal {
        uint256 debt = autoLooper.getVariableDebt(USDC);

        if (debt == 0) {
            IPool.ReserveData memory reserve = aavePool.getReserveData(WETH);
            address aTokenAddress = reserve.aTokenAddress;
            uint256 aTokenBal = IERC20(aTokenAddress).balanceOf(
                address(autoLooper)
            );

            if (aTokenBal == 0) {
                // No collateral either, position is already closed
                isActive = false;
                emit PositionClosed(msg.sender, 0, 0);
                return;
            }

            isActive = false;
            emit PositionClosed(msg.sender, 0, 0);
            return;
        }

        // Add a small buffer (1%) to account for interest accrual
        uint256 usdcNeeded = debt + (debt / 100);
        uint256 ownerBalance = IERC20(USDC).balanceOf(owner);

        if (ownerBalance < debt) {
            emit UnwindFailed("insufficient USDC balance");

            return;
        }

        uint256 amountToTransfer = debt;
        if (ownerBalance >= usdcNeeded) {
            amountToTransfer = usdcNeeded;
        }

        IERC20(USDC).transferFrom(owner, address(this), amountToTransfer);

        IERC20(USDC).approve(address(autoLooper), amountToTransfer);

        try autoLooper.unwindWithUserUSDC(recipient) {
            isActive = false;

            uint256 actualDebt = autoLooper.getVariableDebt(USDC);
            uint256 repaid = debt - actualDebt; // This is approximate

            emit PositionClosed(msg.sender, repaid, 0); // wethReturned is sent to recipient
        } catch Error(string memory reason) {
            emit UnwindFailed(reason);

            uint256 leftover = IERC20(USDC).balanceOf(address(this));
            if (leftover > 0) {
                IERC20(USDC).transfer(owner, leftover);
            }
            // Keep isActive = true so we can retry
        } catch {
            emit UnwindFailed("unknown error during unwind");

            uint256 leftover = IERC20(USDC).balanceOf(address(this));
            if (leftover > 0) {
                IERC20(USDC).transfer(owner, leftover);
            }
        }
    }

    /// @notice Get current health factor of the position
    function getHealthFactor() external view returns (uint256) {
        (, , , , , uint256 healthFactor) = aavePool.getUserAccountData(
            address(autoLooper)
        );
        return healthFactor;
    }

    /// @notice Get position data
    function getPositionData()
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 healthFactor,
            bool active
        )
    {
        (totalCollateralBase, totalDebtBase, , , , healthFactor) = aavePool
            .getUserAccountData(address(autoLooper));
        active = isActive;
    }
}
