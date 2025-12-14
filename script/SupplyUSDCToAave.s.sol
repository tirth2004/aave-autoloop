// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";

import {USDC, POOL} from "../src/Constants.sol";

contract SupplyUSDCToAave is Script {
    IERC20 private constant usdc = IERC20(USDC);
    IPool private constant pool = IPool(POOL);

    function run() external {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);

        console.log("Supplying USDC to Aave Pool");
        console.log("User address:", user);

        uint256 usdcBalance = usdc.balanceOf(user);
        console.log("Your USDC balance:", usdcBalance);

        if (usdcBalance == 0) {
            console.log("ERROR: No USDC to supply!");
            return;
        }

        // Check USDC reserve configuration
        IPool.ReserveData memory usdcReserve = pool.getReserveData(USDC);
        console.log("USDC aToken address:", usdcReserve.aTokenAddress);

        if (usdcReserve.aTokenAddress == address(0)) {
            console.log("ERROR: USDC is not configured in Aave Pool!");
            return;
        }

        // Try supplying in smaller chunks to avoid error 51
        // Start with 10 USDC, then 50, then rest
        vm.startBroadcast(userPrivateKey);

        uint256 remaining = usdcBalance;
        uint256 chunk1 = 10e6; // 10 USDC
        uint256 chunk2 = 50e6; // 50 USDC

        // Try first chunk (10 USDC)
        if (remaining >= chunk1) {
            console.log("Trying to supply", chunk1, "USDC (first chunk)...");
            usdc.approve(address(pool), chunk1);
            try pool.supply(USDC, chunk1, user, 0) {
                console.log("Successfully supplied", chunk1, "USDC");
                remaining -= chunk1;
            } catch {
                console.log("Failed with 10 USDC, trying 1 USDC...");
                // Try even smaller - 1 USDC
                uint256 tinyChunk = 1e6;
                if (remaining >= tinyChunk) {
                    usdc.approve(address(pool), tinyChunk);
                    try pool.supply(USDC, tinyChunk, user, 0) {
                        console.log("Successfully supplied", tinyChunk, "USDC");
                        remaining -= tinyChunk;
                    } catch {
                        console.log(
                            "ERROR: Even 1 USDC failed. Reserve might be paused or misconfigured."
                        );
                        vm.stopBroadcast();
                        return;
                    }
                }
            }
        }

        // Try second chunk (50 USDC)
        if (remaining >= chunk2) {
            console.log("Trying to supply", chunk2, "USDC (second chunk)...");
            usdc.approve(address(pool), chunk2);
            try pool.supply(USDC, chunk2, user, 0) {
                console.log("Successfully supplied", chunk2, "USDC");
                remaining -= chunk2;
            } catch {
                console.log(
                    "Failed with 50 USDC, continuing with remaining..."
                );
            }
        }

        // Supply the rest in 100 USDC chunks
        uint256 chunkSize = 100e6; // 100 USDC chunks
        while (remaining > 0) {
            uint256 toSupply = remaining > chunkSize ? chunkSize : remaining;
            console.log("Supplying", toSupply, "USDC...");
            usdc.approve(address(pool), toSupply);
            try pool.supply(USDC, toSupply, user, 0) {
                console.log("Successfully supplied", toSupply, "USDC");
                remaining -= toSupply;
            } catch {
                console.log("Failed to supply", toSupply, "USDC, stopping");
                break;
            }
        }

        vm.stopBroadcast();

        console.log("Supply attempt complete!");

        // Check balances after
        uint256 aTokenBalance = IERC20(usdcReserve.aTokenAddress).balanceOf(
            user
        );
        console.log("Your aUSDC balance (supplied to Aave):", aTokenBalance);

        // Check pool liquidity
        uint256 poolBalance = usdc.balanceOf(usdcReserve.aTokenAddress);
        console.log("USDC pool total liquidity:", poolBalance);
        console.log("Pool should now have enough liquidity for borrowing!");
    }
}
