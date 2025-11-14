// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {IUniswapV2Factory} from "src/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "src/interfaces/IUniswapV2Pair.sol";
import {IWETH} from "src/interfaces/IWETH.sol";
import {WETH, UNISWAP_V2_FACTORY} from "src/Constants.sol";
import {ERC20} from "src/ERC20.sol";

contract UniswapV2FactoryTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    function test_createPair() public {
        ERC20 token = new ERC20("Test Token", "TTK", 18);

        address pair;
        
        pair = factory.createPair(address(token), WETH);

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();


        if (address(token) < WETH) {
            assertEq(token0, address(token));
            assertEq(token1, WETH);
        } else {
            assertEq(token0, WETH);
            assertEq(token1, address(token));
        }
    }
}
