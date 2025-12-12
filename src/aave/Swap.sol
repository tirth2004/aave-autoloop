// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "cyfrin-aave/interfaces/IERC20.sol";
import {ISwapRouter} from "../interfaces/uniswap-v3/ISwapRouter.sol";
import {UNISWAP_V3_SWAP_ROUTER_02} from "../Constants.sol";

contract Swap {
    ISwapRouter public constant router = ISwapRouter(UNISWAP_V3_SWAP_ROUTER_02);

    /// @notice Swap exact `amountIn` of tokenIn -> tokenOut via Uniswap V3
    /// @param tokenIn input token
    /// @param tokenOut output token
    /// @param fee pool fee tier (500, 3000, 10000)
    /// @param amountIn exact input amount
    /// @param amountOutMin min output amount (slippage protection)
    /// @param recipient who receives tokenOut
    function swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) public returns (uint256 amountOut) {
        // pull tokenIn from caller (your looper will call this internally, so caller will be your contract)
        IERC20(tokenIn).approve(address(router), 0);
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: recipient,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
    }
}
