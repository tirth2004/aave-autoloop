// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";

import {WETH, USDC, POOL} from "../src/Constants.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";
import {AutoLooper} from "../src/aave/AutoLooper.sol";

contract AutoLooperTest is Test {
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant usdc = IERC20(USDC);
    IPool private constant pool = IPool(POOL);

    AutoLooper private looper;

    function setUp() public {
        looper = new AutoLooper();

        // give test user 5 WETH on the fork and approve looper
        deal(WETH, address(this), 5 ether);
        weth.approve(address(looper), type(uint256).max);
    }

    function test_openPosition_basic() public {
        AutoLooper.OpenParams memory params = AutoLooper.OpenParams({
            initialCollateralWeth: 1 ether,
            loops: 2,
            borrowBps: 7000, // 70% of max each loop
            minHealthFactor: 1.3e18,
            minSwapOut: 0 // no slippage check yet
        });

        looper.openPosition(params);

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            ,
            ,
            ,
            uint256 hf
        ) = pool.getUserAccountData(address(looper));

        console.log("collateral:", totalCollateralBase);
        console.log("debt:", totalDebtBase);
        console.log("HF:", hf);

        assertGt(totalCollateralBase, 0, "no collateral");
        assertGt(totalDebtBase, 0, "no debt");
        assertGt(hf, params.minHealthFactor, "hf too low");
    }

    function test_unwindWithUserUSDC() public {
        // 1) Open a leveraged position first
        AutoLooper.OpenParams memory params = AutoLooper.OpenParams({
            initialCollateralWeth: 1 ether,
            loops: 2,
            borrowBps: 7000, // 70% of max each loop
            minHealthFactor: 1.3e18,
            minSwapOut: 0
        });

        looper.openPosition(params);

        (
            uint256 collateralBefore,
            uint256 debtBefore,
            ,
            ,
            ,
            uint256 hfBefore
        ) = pool.getUserAccountData(address(looper));

        console.log("Before unwind - collateral:", collateralBefore);
        console.log("Before unwind - debt:", debtBefore);
        console.log("Before unwind - HF:", hfBefore);

        assertGt(collateralBefore, 0, "no collateral before unwind");
        assertGt(debtBefore, 0, "no debt before unwind");

        // 2) Figure out how much USDC the looper owes
        uint256 usdcDebt = looper.getVariableDebt(USDC);
        console.log("USDC debt:", usdcDebt);
        assertGt(usdcDebt, 0, "expected some USDC debt");

        // 3) Give this test address enough USDC to repay
        //    (a bit extra margin just in case, but repay() uses exact debt)
        deal(USDC, address(this), usdcDebt + 1_000e6);
        console.log(
            "Tester USDC balance before unwind:",
            usdc.balanceOf(address(this))
        );

        // 4) Approve the looper to pull USDC and unwind
        usdc.approve(address(looper), type(uint256).max);
        looper.unwindWithUserUSDC(address(this));

        // 5) Check post-unwind state on Aave for the looper
        (
            uint256 collateralAfter,
            uint256 debtAfter,
            ,
            ,
            ,
            uint256 hfAfter
        ) = pool.getUserAccountData(address(looper));

        console.log("After unwind - collateral:", collateralAfter);
        console.log("After unwind - debt:", debtAfter);
        console.log("After unwind - HF:", hfAfter);

        // The position should be fully closed on Aave
        assertEq(debtAfter, 0, "looper still has debt after unwind");
        assertEq(
            collateralAfter,
            0,
            "looper still has collateral after unwind"
        );
        assertEq(looper.getVariableDebt(USDC), 0, "variable debt not cleared");

        // And the recipient (this test) should now hold WETH (the unwound collateral)
        uint256 wethAfter = weth.balanceOf(address(this));
        console.log("Tester WETH balance after unwind:", wethAfter);
        assertGt(wethAfter, 0, "no WETH returned to user after unwind");
    }
}
