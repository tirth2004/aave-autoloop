// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";
import {ISwapRouter} from "../src/interfaces/uniswap-v3/ISwapRouter.sol";

import {USDT, USDC, POOL, UNISWAP_V3_SWAP_ROUTER_02, UNISWAP_V3_POOL_FEE_USDT_USDC} from "../src/Constants.sol";

contract SwapUSDTToUSDCAndSupply is Script {
    IERC20 private constant usdt = IERC20(USDT);
    IERC20 private constant usdc = IERC20(USDC);
    IPool private constant pool = IPool(POOL);
    ISwapRouter private constant router =
        ISwapRouter(UNISWAP_V3_SWAP_ROUTER_02);

    function run() external {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);

        console.log("Swapping USDT to USDC and supplying to Aave");
        console.log("User address:", user);

        // Check USDT balance
        uint256 usdtBalance = usdt.balanceOf(user);
        console.log("User USDT balance:", usdtBalance);

        if (usdtBalance == 0) {
            console.log("ERROR: No USDT balance!");
            return;
        }

        // Swap ~200 USDC worth of USDT (USDT has 6 decimals, so 200e6)
        uint256 amountToSwap = 200e6; // 200 USDT
        if (usdtBalance < amountToSwap) {
            amountToSwap = usdtBalance; // Use all if less than 200
        }

        console.log("Swapping", amountToSwap, "USDT to USDC...");

        vm.startBroadcast(userPrivateKey);

        // Approve router to spend USDT
        usdt.approve(address(router), amountToSwap);

        // Swap USDT -> USDC
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: USDT,
                tokenOut: USDC,
                fee: UNISWAP_V3_POOL_FEE_USDT_USDC,
                recipient: user,
                amountIn: amountToSwap,
                amountOutMinimum: 0, // Accept any amount (testnet)
                sqrtPriceLimitX96: 0
            });

        uint256 usdcReceived = router.exactInputSingle(swapParams);
        console.log("Received", usdcReceived, "USDC from swap");

        // Check USDC reserve configuration
        IPool.ReserveData memory usdcReserve = pool.getReserveData(USDC);
        console.log("USDC aToken:", usdcReserve.aTokenAddress);

        if (usdcReserve.aTokenAddress == address(0)) {
            console.log("ERROR: USDC is not configured in Aave Pool!");
            vm.stopBroadcast();
            return;
        }

        // Supply USDC to Aave - try 100 USDC first to test
        uint256 amountToSupply = 100e6; // 100 USDC (smaller test amount)
        if (usdcReceived < amountToSupply) {
            amountToSupply = usdcReceived; // Use all if less than 100
        }

        console.log("Supplying", amountToSupply, "USDC to Aave Pool...");
        usdc.approve(address(pool), amountToSupply);
        pool.supply(USDC, amountToSupply, user, 0);
        console.log("Successfully supplied", amountToSupply, "USDC");

        // If we have more, supply the rest
        if (usdcReceived > amountToSupply) {
            uint256 remaining = usdcReceived - amountToSupply;
            console.log("Supplying remaining", remaining, "USDC...");
            usdc.approve(address(pool), remaining);
            pool.supply(USDC, remaining, user, 0);
            console.log("Successfully supplied all USDC");
        }

        vm.stopBroadcast();

        // Check pool liquidity after
        address usdcAToken = pool.getReserveData(USDC).aTokenAddress;
        uint256 poolBalance = usdc.balanceOf(usdcAToken);
        console.log("USDC pool balance after supply:", poolBalance);
        console.log("Done! Pool should now have enough liquidity");
    }
}
