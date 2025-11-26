// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IUniswapV2Pair} from "src/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "src/interfaces/IERC20.sol";

error InvalidToken();

contract UniswapV2FlashSwap {
    IUniswapV2Pair private immutable pair;
    address private immutable token0;
    address private immutable token1;

    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function flashSwap(address token, uint256 amount) external {
        if (token != token0 && token != token1) {
            revert InvalidToken();
        }

        uint256 amountToken0Out = token == token0 ? amount : 0;
        uint256 amountToken1Out = token == token1 ? amount : 0;

        // 1. Determine amount0Out and amount1Out
        (uint256 amount0Out, uint256 amount1Out) = (amountToken0Out, amountToken1Out);

        // 2. Encode token and msg.sender as bytes
        bytes memory data = abi.encode(token, msg.sender);

        // 3. Call swap on the pair contract
        pair.swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        // 1. Require msg.sender is pair contract
        if (msg.sender != address(pair)) {
            revert InvalidToken();
        }
        // 2. Require sender is this contract
        if (sender != address(this)) {
            revert InvalidToken();
        }

        // Alice -> FlashSwap --- to = FlashSwap ----> UniswapV2Pair
        //.                   <-- sender = FlashSwap ---
        // Eve ---------------- to = FlashSwap ----> UniswapV2Pair
        //.              FlashSwap <-- sender = Eve -------

        // 3. Decode token and caller from data
        (address token, address caller) = abi.decode(data, (address, address));
        // 4. Determine amount borrowed (only one of them is > 0)
        uint256 amount = amount0 > 0 ? amount0 : amount1;

        // 5. Calculate flash swap fee and amount to repay
        // fee = borrowed amount * 3 / 997 + 1 to round up
        uint256 fee = (amount * 3) / 997 + 1;
        uint256 amountToRepay = amount + fee;

        // 6. Get flash swap fee from caller
        IERC20(token).transferFrom(caller, address(this), amountToRepay);
        // 7. Repay the pair contract
        IERC20(token).transfer(address(pair), amountToRepay);
    }
}
