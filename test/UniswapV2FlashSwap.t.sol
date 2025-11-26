// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "src/interfaces/IUniswapV2Router02.sol";
import {DAI, UNISWAP_V2_ROUTER_02, UNISWAP_V2_PAIR_DAI_WETH} from "src/Constants.sol";
import {UniswapV2FlashSwap} from "src/periphery/UniswapV2FlashSwap.sol";

contract UniswapV2FlashSwapTest is Test {
    IERC20 private constant dai = IERC20(DAI);

    IUniswapV2Router02 private constant uniswapV2Router02 = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    UniswapV2FlashSwap private flashSwap;

    address private constant user = address(1);

    function setUp() public {
        flashSwap = new UniswapV2FlashSwap(UNISWAP_V2_PAIR_DAI_WETH);

        deal(DAI, user, 10_031e18);
        vm.prank(user);
        dai.approve(address(flashSwap), type(uint256).max);
        // user -> flashSwap.UniswapV2FlashSwap
        //        -> pair.swap
        //          -> flashSwap.uniswapV2Call
        //           -> token.transferFrom(user, flashSwap, fee)
    }

    function test_flashSwap() public {
        uint256 dai0 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);
        vm.prank(user);

        // Add liquidity first to ensure there are enough funds in the pair

        flashSwap.flashSwap(DAI, 10_000e18); // 10,000 DAI
        uint256 dai1 = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);

        console.log("DAI fee", dai1 - dai0);
        assertGe(dai1, dai0);
    }
}
