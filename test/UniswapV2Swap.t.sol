// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Router01} from "../src/interfaces/IUniswapV2Router01.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {DAI, WETH, MKR, UNISWAP_V2_ROUTER_02, UNISWAP_V2_PAIR_DAI_MKR} from "../src/Constants.sol";

contract UniswapV2SwapTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mkr = IERC20(MKR);

    IUniswapV2Router02 private constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Pair private constant pair = IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_MKR);

    address private constant user = address(100);

    function setUp() public {
        vm.deal(user, 100 ether);
        vm.startPrank(user);
        weth.deposit{value: 100 ether}();
        weth.approve(address(router), type(uint256).max);
        vm.stopPrank();

        // Add MKR liquidity to DAI/MKR pool
        deal(DAI, address(pair), 1e6 * 1e18); // 1,000,000 DAI
        deal(MKR, address(pair), 1e5 * 1e18); // 100,000 MKR
        pair.sync();
    }

    // Swap all input tokens for as many output tokens as possible
    function test_swapExactTokensForTokens() public {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = 1 ether;
        uint256 amountOutMin = 1;

        vm.startPrank(user);
        weth.approve(address(router), type(uint256).max);
        uint256[] memory amounts =
            router.swapExactTokensForTokens(amountIn, amountOutMin, path, user, block.timestamp + 15);

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);

        //   WETH 1000000000000000000 = 1 ether
        //   DAI 3494167359584893467255 = 3494.1673... * 1e18
        //   MKR 347159092875617522655 = 347.1590... * 1e18
        vm.stopPrank();

        assertGe(mkr.balanceOf(user), amountOutMin);
    }

    // Receive an exact amaount of output tokens for as new input tokens as possible
    function test_swapTokensForExactTokens() public {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountOut = 0.1 * 1e18; // 0.1 MKR
        uint256 amountInMax = 1 ether;

        vm.startPrank(user);
        weth.approve(address(router), type(uint256).max);
        uint256[] memory amounts =
            router.swapTokensForExactTokens(amountOut, amountInMax, path, user, block.timestamp + 15);

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);

        //   WETH 286903134152013 = 0.2869... ether
        //   DAI 1003010030091273823 = 1003.0100... * 1e18
        //   MKR 100000000000000000 = 0.1 * 1e18
        vm.stopPrank();

        assertEq(mkr.balanceOf(user), amountOut);
    }
}
