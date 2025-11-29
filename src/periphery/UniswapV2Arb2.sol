// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IUniswapV2Pair} from "src/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

contract UniswapV2Arb2 {
    struct FlashSwapData {
        // Caller of flashSwap (msg.sender inside flashSwap)
        address caller;
        // Pair to flash swap from
        address pair0;
        // Pair to swap from
        address pair1;
        // True if flash swap is token0 in and token1 out
        bool isZeroForOne;
        // Amount in to repay flash swap
        uint256 amountIn;
        // Amount to borrow from flash swap
        uint256 amountOut;
        // Revert if profit is less than this minimum
        uint256 minProfit;
    }

    // Exercise 1
    // - Flash swap to borrow tokenOut
    /**
     * @param pair0 Pair contract to flash swap from
     * @param pair1 Pair contract to swap to
     * @param isZeroForOne True if flash swap is token0 in and token1 out
     * @param amountIn Amount in to repay flash swap
     * @param minProfit Minimum profit to make from arbitrage
     *
     */
    function flashSwap(address pair0, address pair1, bool isZeroForOne, uint256 amountIn, uint256 minProfit) external {
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair0).getReserves();
        uint256 amountOut =
            getAmountOut(amountIn, isZeroForOne ? reserve1 : reserve0, isZeroForOne ? reserve0 : reserve1);

        bytes memory data = abi.encode(
            FlashSwapData({
                caller: msg.sender,
                pair0: pair0,
                pair1: pair1,
                isZeroForOne: isZeroForOne,
                amountIn: amountIn,
                amountOut: amountOut,
                minProfit: minProfit
            })
        );

        IUniswapV2Pair(pair0).swap({
            amount0Out: isZeroForOne ? 0 : amountOut,
            amount1Out: isZeroForOne ? amountOut : 0,
            to: address(this),
            data: data
        });
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        FlashSwapData memory params = abi.decode(data, (FlashSwapData));

        address token0 = IUniswapV2Pair(params.pair0).token0();
        address token1 = IUniswapV2Pair(params.pair0).token1();
        (address tokenIn, address tokenOut) = params.isZeroForOne ? (token1, token0) : (token0, token1);

        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(params.pair1).getReserves();
        uint256 amountOut = params.isZeroForOne
            ? getAmountOut(params.amountOut, reserve1, reserve0)
            : getAmountOut(params.amountOut, reserve0, reserve1);

        IERC20(tokenOut).transfer(params.pair1, params.amountOut);
        IUniswapV2Pair(params.pair1).swap({
            amount0Out: params.isZeroForOne ? amountOut : 0,
            amount1Out: params.isZeroForOne ? 0 : amountOut,
            to: address(this),
            data: ""
        });

        IERC20(tokenIn).transfer(params.pair0, params.amountIn);

        uint256 profit = amountOut - params.amountIn;
        require(profit >= params.minProfit, "UniswapV2Arb2: insufficient profit");
        IERC20(tokenIn).transfer(params.caller, profit);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
