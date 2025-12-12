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
}
