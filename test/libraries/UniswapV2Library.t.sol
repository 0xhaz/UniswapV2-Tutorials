// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {UniswapV2Library} from "../../src/libraries/UniswapV2Library.sol";
import {UniswapV2Factory} from "../../src/core/UniswapV2Factory.sol";
import {IUniswapV2Pair} from "../../src/interfaces/IUniswapV2Pair.sol";
import {ERC20} from "../../src/test/ERC20.sol";

contract UniswapV2LibraryTest is Test {
    ERC20 tokenA;
    ERC20 tokenB;
    UniswapV2Factory factory;

    function setUp() public {
        tokenA = new ERC20(100_000e18);
        tokenB = new ERC20(100_000e18);
        factory = new UniswapV2Factory(address(this));

        (address token0, address token1) = UniswapV2Library.sortTokens(address(tokenA), address(tokenB));
        address pairAddr = factory.createPair(token0, token1);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);

        tokenA.transfer(address(pair), 5000 ether);
        tokenB.transfer(address(pair), 10000 ether);
        pair.mint(address(this));
    }

    function testQuote() public {
        uint256 amountA = 1000;
        uint256 reserveA = 5000;
        uint256 reserveB = 10000;

        uint256 amountB = UniswapV2Library.quote(amountA, reserveA, reserveB);
        assertEq(amountB, 2000);
    }

    function testQuoteRevertInsufficientAmount() public {
        uint256 amountA = 0;
        uint256 reserveA = 5000;
        uint256 reserveB = 10000;

        vm.expectRevert();
        UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function testQuoteRevertInsufficientLiquidity() public {
        uint256 amountA = 1000;
        uint256 reserveA = 0;
        uint256 reserveB = 10000;

        vm.expectRevert();
        UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function testSortTokens() public {
        address tokenA = address(0xB);
        address tokenB = address(0xA);

        (address token0, address token1) = UniswapV2Library.sortTokens(tokenA, tokenB);
        assertEq(token0, tokenB);
        assertEq(token1, tokenA);
    }

    function testSortTokensRevertIdenticalAddresses() public {
        address tokenA = address(0xA);
        address tokenB = address(0xA);

        vm.expectRevert();
        UniswapV2Library.sortTokens(tokenA, tokenB);
    }

    function testSortTokensRevertZeroAddress() public {
        address tokenA = address(0x0);
        address tokenB = address(0xA);

        vm.expectRevert();
        UniswapV2Library.sortTokens(tokenA, tokenB);
    }

    function testPairFor() public {
        address factory = address(0xF);
        address tokenA = address(0xA);
        address tokenB = address(0xB);

        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        assertEq(pair, address(0x3659dF6Fe5ADd9bA95F987d902426Fa85F80D3C5));
    }

    function testGetAmountOut() public {
        uint256 amountIn = 1000;
        uint256 reserveIn = 5000;
        uint256 reserveOut = 10000;

        // NOTE: amountInWithFee = amountIn * 997
        // amountInWithFee = 1000 * 997 = 997_000
        // NOTE: numerator = amountInWithFee * reserveOut
        // numerator = 997_000 * 10000 = 9_970_000_000
        // NOTE: denominator = reserveIn * 1000 + amountInWithFee
        // denominator = 5000 * 1000 + 997_000 = 5_997_000
        // NOTE: amountOut = numerator / denominator
        // amountOut = 9_970_000_000 / 5_997_000 = 1662

        uint256 amountOut = UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
        assertEq(amountOut, 1662);
    }

    function testGetAmountOutRevertInsufficientInputAmount() public {
        uint256 amountIn = 0;
        uint256 reserveIn = 5000;
        uint256 reserveOut = 10000;

        vm.expectRevert();
        UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function testGetAmountOutRevertInsufficientLiquidity() public {
        uint256 amountIn = 1000;
        uint256 reserveIn = 0;
        uint256 reserveOut = 10000;

        vm.expectRevert();
        UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function testGetAmountIn() public {
        uint256 amountOut = 1000;
        uint256 reserveIn = 5000;
        uint256 reserveOut = 10000;

        // NOTE: numerator = reserveIn * amountOut * 1000
        // numerator = 5000 * 1000 * 1000 = 5_000_000_000
        // NOTE: denominator = (reserveOut - amountOut) * 997
        // denominator = (10000 - 1000) * 997 = 8_973_000
        // NOTE: amountIn = numerator / denominator + 1
        // amountIn = 5_000_000_000 / 8_973_000 + 1 = 557 + 1 (rounding up) = 558

        uint256 amountIn = UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
        assertEq(amountIn, 558);
    }

    function testGetAmountInRevertInsufficientOutputAmount() public {
        uint256 amountOut = 0;
        uint256 reserveIn = 5000;
        uint256 reserveOut = 10000;

        vm.expectRevert();
        UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function testGetAmountInRevertInsufficientLiquidity() public {
        uint256 amountOut = 1000;
        uint256 reserveIn = 5000;
        uint256 reserveOut = 0;

        vm.expectRevert();
        UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function testGetAmountsOut() public {
        uint256 amountIn = 1000 ether;

        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);

        (uint256 reserve0, uint256 reserve1,) =
            IUniswapV2Pair(factory.getPair(address(tokenA), address(tokenB))).getReserves();

        uint256 amountOut = UniswapV2Library.getAmountOut(amountIn, reserve0, reserve1);

        // NOTE: amountInWithFee = amountIn * 997
        // amountInWithFee = 1000 * 997 = 997000
        // NOTE: numerator = amountInWithFee * reserveOut
        // numerator = 997000 * 5000 = 4985000000
        // NOTE: denominator = reserveIn * 1000 + amountInWithFee
        // denominator = 10000 * 1000 + 997000 = 10997000
        // NOTE: amountOut = numerator / denominator
        // amountOut = 4985000000 / 10997000 ≈ ~453.305

        assertEq(amountOut, 453305446940074565790); // ~453.305 ether
        assertEq(reserve0, 10000 ether); // tokenB reserve
        assertEq(reserve1, 5000 ether); // tokenA reserve
    }

    function testGetAmountsOutRevertPathLength() public {
        uint256 amountIn = 1000 ether;

        address[] memory path = new address[](1);
        path[0] = address(tokenB);

        vm.expectRevert();
        UniswapV2Library.getAmountOut(amountIn, 0, 0);
    }

    function testGetsAmountIn() public {
        uint256 amountOut = 1000 ether;

        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);

        (uint256 reserve0, uint256 reserve1,) =
            IUniswapV2Pair(factory.getPair(address(tokenA), address(tokenB))).getReserves();

        uint256 amountIn = UniswapV2Library.getAmountIn(amountOut, reserve0, reserve1);

        // NOTE: numerator = reserveIn * amountOut * 1000
        // numerator = 10000 * 1000 * 1000 = 10_000_000_000_000
        // NOTE: denominator = (reserveOut - amountOut) * 997
        // denominator = (5000 - 1000) * 997 = 3_988_000
        // NOTE: amountIn = numerator / denominator + 1
        // amountIn = 10_000_000_000_000 / 3_988_000 + 1 ≈ ~2509.045 + 1 (rounding up) = 2510.045

        assertEq(amountIn, 2507522567703109327984); //  ~2509.045 ether
        assertEq(reserve0, 10000 ether); // tokenB reserve
        assertEq(reserve1, 5000 ether); // tokenA reserve
    }

    function testGetsAmountInRevertPathLength() public {
        uint256 amountOut = 1000 ether;

        address[] memory path = new address[](1);
        path[0] = address(tokenB);

        vm.expectRevert();
        UniswapV2Library.getAmountIn(amountOut, 0, 0);
    }

    function testGetReserves() public {
        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);

        (uint256 reserve0, uint256 reserve1,) =
            IUniswapV2Pair(factory.getPair(address(tokenA), address(tokenB))).getReserves();

        assertEq(reserve0, 10000 ether); // tokenB reserve
        assertEq(reserve1, 5000 ether); // tokenA reserve
    }
}
