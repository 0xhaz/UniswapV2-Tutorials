// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "src/interfaces/IERC20.sol";
import {IWETH} from "src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "src/interfaces/IUniswapV2Router02.sol";
import {
    DAI,
    WETH,
    UNISWAP_V2_PAIR_DAI_WETH,
    UNISWAP_V2_ROUTER_02,
    SUSHISWAP_V2_ROUTER_02,
    UNISWAP_V2_PAIR_DAI_WETH,
    SUSHISWAP_V2_PAIR_DAI_WETH
} from "src/Constants.sol";
import {UniswapV2Arb2} from "src/periphery/UniswapV2Arb2.sol";

// Test arbitrage between Uniswap and Sushiswap
// Buy WETH on Uniswap, sell WETH on Sushiswap
// For flashSwap, borrow DAI from DAI/MKR pair
contract UniswapV2Arb2Test is Test {
    IUniswapV2Router02 private constant uni_router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Router02 private constant sushi_router = IUniswapV2Router02(SUSHISWAP_V2_ROUTER_02);
    IERC20 private constant dai = IERC20(DAI);
    IWETH private constant weth = IWETH(WETH);

    address constant user = address(1);

    UniswapV2Arb2 private arb;

    function setUp() public {
        arb = new UniswapV2Arb2();

        deal(address(this), 100e18);

        weth.deposit{value: 100e18}();
        weth.approve(address(uni_router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        uni_router.swapExactTokensForTokens({
            amountIn: 100e18,
            amountOutMin: 1,
            path: path,
            to: user,
            deadline: block.timestamp
        });
    }

    function test_flashSwap() public {
        uint256 bal0 = dai.balanceOf(user);
        vm.prank(user);
        arb.flashSwap(UNISWAP_V2_PAIR_DAI_WETH, SUSHISWAP_V2_PAIR_DAI_WETH, true, 1e18, 1);
        uint256 bal1 = dai.balanceOf(user);

        assertGe(bal1, bal0);
        assertEq(dai.balanceOf(address(arb)), 0);
        console2.log("Profit:", bal1 - bal0);
    }
}
