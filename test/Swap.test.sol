// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {WETH, USDC, UNISWAP_V3_POOL_FEE_WETH_USDC} from "../src/Constants.sol";

import {Swap} from "../src/aave/Swap.sol";

contract SwapTest is Test {
    IERC20 private constant weth = IERC20(WETH);
    IERC20 private constant usdc = IERC20(USDC);

    Swap private target;

    function setUp() public {
        target = new Swap();

        // fund the test address with WETH on the fork
        deal(WETH, address(this), 1 ether);
        console.log("Tester WETH before transfer:", weth.balanceOf(address(this)));

        // send WETH to the Swap contract (it is the actual swapper)
        weth.transfer(address(target), 0.1 ether);

        console.log("Tester WETH after transfer:", weth.balanceOf(address(this)));
        console.log("Swap contract WETH after funding:", weth.balanceOf(address(target)));
    }

    function test_swap_weth_to_usdc() public {
        uint256 amountIn = 0.01 ether;

        console.log("=== Pre-swap state ===");
        console.log("Swap WETH balance:", weth.balanceOf(address(target)));
        console.log("Swap USDC balance:", usdc.balanceOf(address(target)));
        console.log("Tester USDC balance:", usdc.balanceOf(address(this)));
        console.log("Amount in (WETH):", amountIn);
        console.log("Fee tier:", UNISWAP_V3_POOL_FEE_WETH_USDC);

        // sanity: make sure the Swap contract actually has enough WETH
        require(weth.balanceOf(address(target)) >= amountIn, "Swap contract has insufficient WETH");

        console.log("Calling swapExactInputSingle...");

        uint256 amountOut = target.swapExactInputSingle(
            WETH,
            USDC,
            UNISWAP_V3_POOL_FEE_WETH_USDC,
            amountIn,
            0, // set to 0 to eliminate slippage as a revert reason for now
            address(this)
        );

        console.log("=== Post-swap state ===");
        console.log("Amount out (USDC):", amountOut);
        console.log("Tester USDC balance after:", usdc.balanceOf(address(this)));
        console.log("Swap USDC balance after:", usdc.balanceOf(address(target)));
        console.log("Swap WETH balance after:", weth.balanceOf(address(target)));

        assertGt(usdc.balanceOf(address(this)), 0, "No USDC received");
    }
}
