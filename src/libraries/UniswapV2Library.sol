// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {SafeMath} from "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    // Ensures tokens are consistently sorted before interacting with a pair
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // Calculates the CREATE2 address for a pair without making any external calls
    // Computes the deterministic address of a Uniswap V2 pair contract without calling the factory
    // Same address as would be returned by IUniswapV2Factory.getPair but cheaper
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            // NOTE: salt
                            keccak256(abi.encodePacked(token0, token1)),
                            // NOTE: keccak256(creation bytecode)
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair in a token-agnostic manner
    function getReserves(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        // NOTE: token 0 < token 1
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    // pure price quote without fee or slippage. Used in routing estimations or off-chain quoting
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        // NOTE:
        // dy = dx * y0 / x0
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset an pair reserves, returns the maxmimum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        // NOTE:
        // x = token in
        // y = token out
        //        dx * 0.997 * x0
        // dy = ---------------------
        //        x0 + dx * 0.997

        // NOTE:
        // dx * 997
        uint256 amountInWithFee = amountIn.mul(997);
        // dx * 997 * y0
        uint256 numerator = amountInWithFee.mul(reserveOut);
        // x0 * 1000 + dx * 997
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        //         dx * 997 * y0
        // dy = ---------------------
        //        x0 * 1000 + dx * 997
        //
        //         dx * 997 / 1000 * y0
        //    = -------------------------
        //         x0 + dx * 997 / 1000
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        // x0 * dy * 1000
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        // (y0 - dy) * 997
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        // NOTE:
        // (x0 + dx * (1 - f))(y0 - dy) = x0 * y0
        //      x0 * dy       1
        // dx = --------- * -----
        //     (y0 - dy)   (1 - f)
        //      x0 * dy * 1000
        // dx = ---------------------
        //      (y0 - dy) * 997
        // NOTE: round up
        amountIn = (numerator / denominator).add(1);
    }
    // performs chained getAmountOut calculations on any number of pairs
    // NOTE: amounts[0] = amountIn
    //       amounts[n - 1] = final amount out
    //       amounts[i] = intermediate amounts out

    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        //  WETH 1000000000000000000 (1 * 1e18)
        //  DAI 3399798446669274345484 (3399.7984... * 1e18)
        //  MKR 46082848056548101 (0.0460828... * 1e18)

        // NOTE: Example
        // --- Inputs ---
        // amountIn = 1e18
        // path = [WETH, DAI, MKR]
        // --- Outputs ---
        // WETH    1000000000000000000 (1 * 1e18)
        // DAI  2500339748620145970214 (2500.3397... * 1e18)
        // MKR     1242766501542703043 (1.2427... * 1e18)

        // --- Execution ---
        // amounts = [0, 0, 0]
        // amounts = [1000000000000000000, 0, 0]

        // For loop
        // i = 0
        // path[i] = WETH, path[i + 1] = DAI
        // amounts[i] = 1000000000000000000
        // amounts[i + 1] = 2500339748620145970214
        // amounts = [1000000000000000000, 2500339748620145970214, 0]

        // i = 1
        // path[i] = DAI, path[i + 1] = MKR
        // amounts[i] = 2500339748620145970214
        // amounts[i + 1] = 1242766501542703043
        // amounts = [1000000000000000000, 2500339748620145970214, 1242766501542703043]

        // NOTE:
        //   i | path[i]   | path[i + 1]
        //   0 | path[0]   | path[1]
        //   1 | path[1]   | path[2]
        //   2 | path[2]   | path[3]
        // n-2 | path[n-2] | path[n-1]
        for (uint256 i; i < path.length - 1; i++) {
            // NOTE: reserves = internal balance of tokens inside pair contract
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            // NOTE: use the previous output for input
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;

        // --- Inputs ---
        // amountOut = 1e18
        // path = [WETH, DAI, MKR]
        // --- Outputs ---
        // WETH     804555560756014274 (0.8045... * 1e18)
        // DAI  2011892163724115442026 (2011.892... * 1e18)
        // MKR     1000000000000000000 (1 * 1e18)

        // --- Execution ---
        // amounts = [0, 0, 0]
        // amounts = [0, 0, 1000000000000000000]

        // For loop
        // i = 2
        // path[i - 1] = DAI, path[i] = MKR
        // amounts[i] = 1000000000000000000
        // amounts[i - 1] = 2011892163724115442026
        // amounts = [0, 2011892163724115442026, 1000000000000000000]

        // i = 1
        // path[i - 1] = WETH, path[i] = DAI
        // amounts[i] = 2011892163724115442026
        // amounts[i - 1] = 804555560756014274
        // amounts = [804555560756014274, 2011892163724115442026, 1000000000000000000]

        // NOTE:
        // i     | output amount  | input amount
        // n - 1 | amounts[n - 1] | amounts[n - 2]
        // n - 2 | amounts[n - 2] | amounts[n - 3]
        // ...
        // 2     | amounts[2]     | amounts[1]
        // 1     | amounts[1]     | amounts[0]
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
