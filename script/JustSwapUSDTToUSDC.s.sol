// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {ISwapRouter} from "../src/interfaces/uniswap-v3/ISwapRouter.sol";

import {USDT, USDC, UNISWAP_V3_SWAP_ROUTER_02, UNISWAP_V3_POOL_FEE_USDT_USDC} from "../src/Constants.sol";

contract JustSwapUSDTToUSDC is Script {
    IERC20 private constant usdt = IERC20(USDT);
    IERC20 private constant usdc = IERC20(USDC);
    ISwapRouter private constant router =
        ISwapRouter(UNISWAP_V3_SWAP_ROUTER_02);

    function run() external {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);

        console.log("Swapping USDT to USDC");
        console.log("User address:", user);

        uint256 usdtBalance = usdt.balanceOf(user);
        console.log("USDT balance:", usdtBalance);

        if (usdtBalance == 0) {
            console.log("ERROR: No USDT!");
            return;
        }

        // Swap 200 USDT to USDC
        uint256 amountToSwap = 200e6; // 200 USDT
        if (usdtBalance < amountToSwap) {
            amountToSwap = usdtBalance;
        }

        console.log("Swapping", amountToSwap, "USDT to USDC...");

        vm.startBroadcast(userPrivateKey);
        usdt.approve(address(router), amountToSwap);

        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: USDT,
                tokenOut: USDC,
                fee: UNISWAP_V3_POOL_FEE_USDT_USDC,
                recipient: user,
                amountIn: amountToSwap,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 usdcReceived = router.exactInputSingle(swapParams);
        vm.stopBroadcast();

        console.log("Swap complete!");
        console.log("Received", usdcReceived, "USDC");
        console.log("Your USDC balance now:", usdc.balanceOf(user));
    }
}
