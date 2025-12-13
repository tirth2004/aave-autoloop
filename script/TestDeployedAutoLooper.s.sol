// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdCheats.sol";

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";

import {WETH, USDC, POOL} from "../src/Constants.sol";
import {AutoLooper} from "../src/aave/AutoLooper.sol";

contract TestDeployedAutoLooper is Script, StdCheats {
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

        // Check current balances
        console.log("User WETH balance:", weth.balanceOf(user));
        console.log("User USDC balance:", usdc.balanceOf(user));

        // Fund user with WETH if needed
        if (weth.balanceOf(user) < 0.1 ether) {
            console.log("Funding user with WETH...");
            deal(WETH, user, 1 ether);
            console.log(
                "User WETH balance after funding:",
                weth.balanceOf(user)
            );
        }

        // Check USDC pool liquidity and fund if needed
        address usdcAToken = pool.getReserveData(USDC).aTokenAddress;
        uint256 usdcPoolBalance = usdc.balanceOf(usdcAToken);
        console.log("USDC pool balance:", usdcPoolBalance);
        if (usdcPoolBalance < 1000e6) {
            console.log("Funding USDC pool with 10,000 USDC...");
            deal(USDC, usdcAToken, 10_000e6);
            console.log(
                "USDC pool balance after funding:",
                usdc.balanceOf(usdcAToken)
            );
        }

        // Approve looper
        vm.startBroadcast(userPrivateKey);
        weth.approve(DEPLOYED_LOOPER, type(uint256).max);
        vm.stopBroadcast();
        console.log("Approved WETH");

        // Open position
        AutoLooper.OpenParams memory params = AutoLooper.OpenParams({
            initialCollateralWeth: 0.01 ether,
            loops: 1,
            borrowBps: 5000,
            minHealthFactor: 1.3e18,
            minSwapOut: 0
        });

        vm.startBroadcast(userPrivateKey);
        looper.openPosition(params);
        vm.stopBroadcast();
        console.log("Position opened");

        // Check position
        (uint256 collateral, uint256 debt, , , , uint256 hf) = pool
            .getUserAccountData(DEPLOYED_LOOPER);
        console.log("Position - collateral:", collateral);
        console.log("Position - debt:", debt);
        console.log("Position - HF:", hf);

        // Get debt and fund user for unwind
        uint256 usdcDebt = looper.getVariableDebt(USDC);
        console.log("USDC debt:", usdcDebt);
        deal(USDC, user, usdcDebt + 1_000e6);

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
