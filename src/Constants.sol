// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// Sepolia Testnet Addresses (TEMPORARY)
address constant WETH = 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;
address constant DAI = 0x3E622317F8f93Ef2Ee0f06753c5BC5b7172E41ad;

// Aave V3 Sepolia
address constant POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
address constant ORACLE = 0x2da88497588bf89281816106C7259e31AF45a663;

// Uniswap V3 Sepolia
address constant UNISWAP_V3_SWAP_ROUTER_02 = 0x3bFA4769FB09eefC5a80d6E87c3B9C650f7Ae48E;
uint24 constant UNISWAP_V3_POOL_FEE_DAI_WETH = 3000;

address constant USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
address constant USDT = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;
uint24 constant UNISWAP_V3_POOL_FEE_WETH_USDC = 3000;
uint24 constant UNISWAP_V3_POOL_FEE_USDT_USDC = 500; // Common fee tier for stablecoin pairs
