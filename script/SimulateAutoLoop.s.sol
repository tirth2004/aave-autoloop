// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "forge-std/StdCheats.sol";

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";

import {WETH, USDC, POOL} from "../src/Constants.sol";
import {AutoLooper} from "../src/aave/AutoLooper.sol";

contract SimulateAutoLoop is Script, StdCheats {
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant usdc = IERC20(USDC);
    IPool private constant pool = IPool(POOL);

    function run() external {
        address user = address(0xBEEF);

        console.log("User address:", user);

        AutoLooper looper = new AutoLooper();
        console.log("AutoLooper deployed at:", address(looper));

        deal(WETH, user, 5 ether);
        console.log("User WETH balance before:", weth.balanceOf(user));

        vm.startPrank(user);
        weth.approve(address(looper), type(uint256).max);
        vm.stopPrank();

        AutoLooper.OpenParams memory params = AutoLooper.OpenParams({
            initialCollateralWeth: 1 ether,
            loops: 2,
            borrowBps: 7000, // 70% of max borrow each loop
            minHealthFactor: 1.3e18,
            minSwapOut: 0
        });

        vm.startPrank(user);
        looper.openPosition(params);
        vm.stopPrank();

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

        uint256 usdcDebt = looper.getVariableDebt(USDC);
        console.log("USDC debt (looper):", usdcDebt);

        deal(USDC, user, usdcDebt + 1_000e6);
        console.log("User USDC before unwind:", usdc.balanceOf(user));

        vm.startPrank(user);
        usdc.approve(address(looper), type(uint256).max);
        looper.unwindWithUserUSDC(user);
        vm.stopPrank();

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
