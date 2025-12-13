// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";

import {WETH, USDC, POOL} from "../src/Constants.sol";
import {AutoLooper} from "../src/aave/AutoLooper.sol";

contract TestDeployedAutoLooperReal is Script {
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant usdc = IERC20(USDC);
    IPool private constant pool = IPool(POOL);

    // Deployed AutoLooper address on Sepolia
    address private constant DEPLOYED_LOOPER =
        0x02E2ab3f8Bb53A8bdEd79b7f12448baa31be2c11;

    function run() external {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);
        AutoLooper looper = AutoLooper(DEPLOYED_LOOPER);

        console.log("Testing deployed AutoLooper at:", DEPLOYED_LOOPER);
        console.log("User address:", user);

        // Check current balances (must have real tokens on Sepolia)
        uint256 wethBalance = weth.balanceOf(user);
        uint256 usdcBalance = usdc.balanceOf(user);
        console.log("User WETH balance:", wethBalance);
        console.log("User USDC balance:", usdcBalance);

        require(wethBalance >= 0.01 ether, "Need at least 0.01 WETH");
        console.log("WETH balance sufficient");

        // Check position before
        (
            uint256 collateralBefore,
            uint256 debtBefore,
            ,
            ,
            ,
            uint256 hfBefore
        ) = pool.getUserAccountData(DEPLOYED_LOOPER);
        console.log("Before - collateral:", collateralBefore);
        console.log("Before - debt:", debtBefore);
        console.log("Before - HF:", hfBefore);

        // Approve and open position
        vm.startBroadcast(userPrivateKey);
        weth.approve(DEPLOYED_LOOPER, type(uint256).max);

        AutoLooper.OpenParams memory params = AutoLooper.OpenParams({
            initialCollateralWeth: 0.01 ether,
            loops: 1,
            borrowBps: 5000,
            minHealthFactor: 1.3e18,
            minSwapOut: 0
        });

        looper.openPosition(params);
        vm.stopBroadcast();
        console.log("Position opened");

        // Check position after open
        (
            uint256 collateralAfter,
            uint256 debtAfter,
            ,
            ,
            ,
            uint256 hfAfter
        ) = pool.getUserAccountData(DEPLOYED_LOOPER);
        console.log("After open - collateral:", collateralAfter);
        console.log("After open - debt:", debtAfter);
        console.log("After open - HF:", hfAfter);

        // Get debt and check if user has enough USDC
        uint256 usdcDebt = looper.getVariableDebt(USDC);
        console.log("USDC debt:", usdcDebt);
        console.log("User USDC balance:", usdcBalance);

        if (usdcBalance < usdcDebt) {
            console.log("WARNING: Not enough USDC to unwind!");
            console.log("Need:", usdcDebt);
            console.log("Have:", usdcBalance);
            console.log("You can:");
            console.log("  1. Get more USDC from Aave faucet");
            console.log("  2. Swap WETH for USDC on Uniswap");
            console.log("  3. Just check the position without unwinding");
            return;
        }
        console.log("USDC balance sufficient for unwind");

        // Unwind
        vm.startBroadcast(userPrivateKey);
        usdc.approve(DEPLOYED_LOOPER, type(uint256).max);
        looper.unwindWithUserUSDC(user);
        vm.stopBroadcast();
        console.log("Position unwound");

        // Final balances
        console.log("User WETH after:", weth.balanceOf(user));
        console.log("User USDC after:", usdc.balanceOf(user));
    }
}
