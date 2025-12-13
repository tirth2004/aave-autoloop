// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdCheats.sol";

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";

// Note: This script works with Sepolia FORK (not direct deployment)
// The contracts use mainnet addresses, so we fork Sepolia to test
import {WETH, USDC, POOL} from "../src/Constants.sol";
import {AutoLooper} from "../src/aave/AutoLooper.sol";

contract TestAutoLooperSepolia is Script, StdCheats {
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant usdc = IERC20(USDC);
    IPool private constant pool = IPool(POOL);

    function run() external {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);

        // Get deployed AutoLooper address from environment or deploy new one
        address looperAddress = vm.envOr("AUTOLOOPER_ADDRESS", address(0));
        AutoLooper looper;

        if (looperAddress == address(0)) {
            console.log("Deploying new AutoLooper...");
            vm.startBroadcast(userPrivateKey);
            looper = new AutoLooper();
            vm.stopBroadcast();
            console.log("AutoLooper deployed at:", address(looper));
        } else {
            console.log("Using existing AutoLooper at:", looperAddress);
            looper = AutoLooper(looperAddress);
        }

        console.log("User address:", user);
        console.log("User WETH balance before funding:", weth.balanceOf(user));
        console.log("User USDC balance before funding:", usdc.balanceOf(user));

        // Fund user with WETH on the fork (deal works on forks)
        deal(WETH, user, 5 ether);
        console.log("User WETH balance after funding:", weth.balanceOf(user));

        // Verify Aave Pool has WETH configured
        address wethAToken = pool.getReserveData(WETH).aTokenAddress;
        console.log("WETH aToken address:", wethAToken);
        if (wethAToken == address(0)) {
            console.log(
                "ERROR: WETH is not configured in Aave Pool on Sepolia!"
            );
            console.log("Pool address:", address(pool));
            console.log("WETH address:", WETH);
            return;
        }
        console.log("WETH reserve configured correctly");

        // Check USDC reserve and fund if needed (to avoid arithmetic errors)
        address usdcAToken = pool.getReserveData(USDC).aTokenAddress;
        console.log("USDC aToken address:", usdcAToken);
        uint256 usdcPoolBalance = usdc.balanceOf(usdcAToken);
        console.log("USDC pool balance:", usdcPoolBalance);

        // If pool has less than 1000 USDC, fund it to avoid arithmetic errors
        if (usdcPoolBalance < 1000e6) {
            console.log(
                "USDC pool has low liquidity, funding with 10,000 USDC..."
            );
            deal(USDC, usdcAToken, 10_000e6);
            console.log(
                "USDC pool balance after funding:",
                usdc.balanceOf(usdcAToken)
            );
        }

        // 1) Approve looper to pull WETH from user
        vm.startBroadcast(userPrivateKey);
        weth.approve(address(looper), type(uint256).max);
        vm.stopBroadcast();
        console.log("Approved WETH");

        // 2) Open position
        // Note: Using 1 loop instead of 2 because Sepolia has low liquidity
        // which causes arithmetic errors in interest rate calculations
        AutoLooper.OpenParams memory params = AutoLooper.OpenParams({
            initialCollateralWeth: 0.01 ether, // Start small on testnet
            loops: 1, // Reduced to 1 loop due to Sepolia liquidity issues
            borrowBps: 5000, // Reduced to 50% to be safer on testnet
            minHealthFactor: 1.3e18,
            minSwapOut: 0
        });

        vm.startBroadcast(userPrivateKey);
        looper.openPosition(params);
        vm.stopBroadcast();
        console.log("Position opened");

        // 3) Inspect position on Aave
        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            ,
            ,
            uint256 hf
        ) = pool.getUserAccountData(address(looper));
        console.log("AFTER OPEN");
        console.log("  collateral (base):", totalCollateralBase);
        console.log("  debt (base):      ", totalDebtBase);
        console.log("  HF:               ", hf);

        // 4) Get USDC debt and fund user
        uint256 usdcDebt = looper.getVariableDebt(USDC);
        console.log("USDC debt (looper):", usdcDebt);
        deal(USDC, user, usdcDebt + 1_000e6);
        console.log("User USDC balance after funding:", usdc.balanceOf(user));

        // 5) Approve and unwind
        vm.startBroadcast(userPrivateKey);
        usdc.approve(address(looper), type(uint256).max);
        looper.unwindWithUserUSDC(user);
        vm.stopBroadcast();
        console.log("Position unwound");

        // 6) Check Aave position after unwind
        (
            uint256 collateralAfter,
            uint256 debtAfter,
            ,
            ,
            ,
            uint256 hfAfter
        ) = pool.getUserAccountData(address(looper));
        console.log("AFTER UNWIND");
        console.log("  collateral (base):", collateralAfter);
        console.log("  debt (base):      ", debtAfter);
        console.log("  HF:               ", hfAfter);
        console.log("User WETH after unwind:", weth.balanceOf(user));
        console.log("User USDC after unwind:", usdc.balanceOf(user));
    }
}
