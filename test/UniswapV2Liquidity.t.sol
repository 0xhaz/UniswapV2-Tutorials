// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {DAI, WETH, UNISWAP_V2_ROUTER_02, UNISWAP_V2_PAIR_DAI_WETH} from "../src/Constants.sol";

contract UniswapV2LiquidityTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);

    IUniswapV2Router02 private constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Pair private constant pair = IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_WETH);

    address private constant user = address(100);

    function setUp() public {
        deal(user, 100 ether);
        vm.startPrank(user);
        weth.deposit{value: 100 ether}();
        weth.approve(address(router), type(uint256).max);
        vm.stopPrank();

        deal(DAI, user, 1e6 * 1e18); // 1,000,000 DAI
        vm.startPrank(user);
        dai.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    function test_addLiquidity() public {
        vm.prank(user);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity({
            tokenA: DAI, // tokenA
            tokenB: WETH, // tokenB
            amountADesired: 1e6 * 1e18, // 1,000,000 DAI
            amountBDesired: 100 ether, // 100 WETH
            amountAMin: 1, // amountAMin
            amountBMin: 1, // amountBMin
            to: user, // to
            deadline: block.timestamp + 15
        });

        console.log("DAI added:", amountA);
        console.log("WETH added:", amountB);
        console.log("LP tokens minted:", liquidity);

        assertGt(pair.balanceOf(user), 0);
    }

    function test_removeLiquidity() public {
        // First, add liquidity
        vm.prank(user);
        (,, uint256 liquidity) = router.addLiquidity({
            tokenA: DAI,
            tokenB: WETH,
            amountADesired: 1e6 * 1e18,
            amountBDesired: 100 ether,
            amountAMin: 1,
            amountBMin: 1,
            to: user,
            deadline: block.timestamp + 15
        });

        vm.prank(user);
        pair.approve(address(router), type(uint256).max);

        // Now, remove liquidity
        vm.prank(user);
        (uint256 amountA, uint256 amountB) = router.removeLiquidity({
            tokenA: DAI,
            tokenB: WETH,
            liquidity: liquidity,
            amountAMin: 1,
            amountBMin: 1,
            to: user,
            deadline: block.timestamp + 15
        });

        console.log("DAI removed:", amountA);
        console.log("WETH removed:", amountB);

        assertEq(pair.balanceOf(user), 0);
    }
}
