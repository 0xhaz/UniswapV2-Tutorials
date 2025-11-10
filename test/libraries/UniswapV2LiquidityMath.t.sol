// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Factory} from "../../src/core/UniswapV2Factory.sol";
import {UniswapV2LiquidityMathLibrary} from "../../src/libraries/UniswapV2LiquidityMathLibrary.sol";
import {ERC20} from "../../src/test/ERC20.sol";
import {IUniswapV2Pair} from "../../src/interfaces/IUniswapV2Pair.sol";
import {UniswapV2Library} from "../../src/libraries/UniswapV2Library.sol";
import {TestUniswapV2Library} from "../helpers/TestUniswapV2Library.sol";

contract UniswapV2LiquidityMathTest is Test {
    ERC20 tokenA;
    ERC20 tokenB;
    UniswapV2Factory factory;
    IUniswapV2Pair pair;

    function setUp() public {
        tokenA = new ERC20(100_000e18);
        tokenB = new ERC20(100_000e18);
        factory = new UniswapV2Factory(address(this));

        (address token0, address token1) = TestUniswapV2Library.sortTokens(address(tokenA), address(tokenB));
        address pairAddr = factory.createPair(token0, token1);
        pair = IUniswapV2Pair(pairAddr);

        // Add initial liquidity
        tokenA.transfer(address(pair), 5000 ether);
        tokenB.transfer(address(pair), 10000 ether);

        // Mint liquidity tokens to this contract
        pair.mint(address(this));
    }

    // function testGetReservesAfterArbitrage() public {
    //     // Simulated true prices: tokenA is worth 2 tokenB (i.e., priceA = 2, priceB = 1)
    //     uint256 truePriceTokenA = 2 ether;
    //     uint256 truePriceTokenB = 1 ether;

    //     (uint256 reserve0, uint256 reserve1,) =
    //         IUniswapV2Pair(factory.getPair(address(tokenA), address(tokenB))).getReserves();

    //     (uint256 adjustedReserveA, uint256 adjustedReserveB) = UniswapV2LiquidityMathLibrary.getReservesAfterArbitrage(
    //         address(factory), address(tokenA), address(tokenB), truePriceTokenA, truePriceTokenB
    //     );

    //     console.log("New reserves after arbitrage:");
    //     console.log("Reserve A:", adjustedReserveA / 1e18);
    //     console.log("Reserve B:", adjustedReserveB / 1e18);

    //     assertGt(adjustedReserveA, reserve0);
    //     assertLt(adjustedReserveB, reserve1);
    // }
}
