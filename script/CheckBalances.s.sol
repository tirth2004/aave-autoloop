// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {IPool} from "cyfrin-aave/interfaces/aave-v3/IPool.sol";

import {USDT, USDC, POOL} from "../src/Constants.sol";

contract CheckBalances is Script {
    IERC20 private constant usdt = IERC20(USDT);
    IERC20 private constant usdc = IERC20(USDC);
    IPool private constant pool = IPool(POOL);

    function run() external {
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(userPrivateKey);

        console.log("Checking balances for:", user);
        console.log("USDT balance:", usdt.balanceOf(user));
        console.log("USDC balance:", usdc.balanceOf(user));

        // Check USDC pool liquidity
        address usdcAToken = pool.getReserveData(USDC).aTokenAddress;
        uint256 poolBalance = usdc.balanceOf(usdcAToken);
        console.log("USDC pool balance:", poolBalance);

        // Check if user has supplied USDC to Aave
        if (usdcAToken != address(0)) {
            uint256 aTokenBalance = IERC20(usdcAToken).balanceOf(user);
            console.log(
                "Your aUSDC balance (supplied to Aave):",
                aTokenBalance
            );
        }
    }
}
