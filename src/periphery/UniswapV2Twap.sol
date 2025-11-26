// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IUniswapV2Pair} from "src/interfaces/IUniswapV2Pair.sol";
import {FixedPoint} from "src/libraries/FixedPoint.sol";

// Modified from https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
// Do not use this contract in production
contract UniswapV2Twap {
    using FixedPoint for *;

    // Minimum wait time in seconds before the function update can be called again
    // TWAP of time > MIN_WAIT
    uint256 private constant MIN_WAIT = 300;

    IUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;

    // Cumulative prices are uq112x112 price * seconds
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    // Last timestamp the cumulative prices were updated
    uint32 public updatedAt;

    // TWAP of token0 and token1
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    // TWAP of token0 in terms of token1
    FixedPoint.uq112x112 public price0Avg;
    // TWAP of token1 in terms of token0
    FixedPoint.uq112x112 public price1Avg;

    constructor(address _pair) {
        // 1. Set pair contract from constructor input
        pair = IUniswapV2Pair(_pair);
        // 2. Set token0 and token1 from pair contract
        token0 = pair.token0();
        token1 = pair.token1();
        // 3. Store price0CumulativeLast and price1CumulativeLast from pair contract
        // 4. Call pair.getReserve to get last timestamp the reserves were updated
        // and store it in updatedAt
        price0CumulativeLast = pair.price0CumulativeLast();
        price1CumulativeLast = pair.price1CumulativeLast();
        (,, uint32 blockTimestampLast) = pair.getReserves();
        updatedAt = blockTimestampLast;
    }

    function _getCurrentCumulativePrices() internal view returns (uint256 price0Cumulative, uint256 price1Cumulative) {
        // 1. Get latest cumulative prices from pair contract
        price0Cumulative = pair.price0CumulativeLast();
        price1Cumulative = pair.price1CumulativeLast();

        // if current block timestamp > last timestamp reserves were updated
        // calculate cumulative prices until current time.
        // Otherwise, return latest cumulative prices retrieved from pair contract.
        
        // 2. Get reserves and last timestamp the reserves were updated from pair contract
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair.getReserves();
        
        // 3. Cast block.timestamp to uint32
        uint32 blockTimestamp = 0;
        if(blockTimestampLast != blockTimestamp) {
            // 4. Calculate elapsed time
            uint32 dt;

            // Addition overflow is desired
            uncheck {
                // 5. Add spot price * elapsed time to the cumulative prices
                // - Use FixedPoint.fraction to calculate spot price
                // - FixedPoint.fraction returns a UQ112x112, so cast it to uint256
                // - Multiply spot price by time elapsed
                dt = blockTimestamp - blockTimestampLast;
                price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * dt;
                price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * dt;
            }
        }
    }

    // update cumulative prices
    function update() external {
        // 1. Cast block.timestamp to uint32
        uint32 blockTimestamp = 0;
        // 2. Calculate elapsed time since last time cumulative prices were 
        // updated in this contract
        uint32 dt = 0;
        // 3. Require elapsed time > MIN_WAIT
        require(dt >= MIN_WAIT, "UniswapV2Twap: MIN_WAIT not elapsed");
        // 4. Call the internal function _getCurrentCumulativePrices to get latest
        // cumulative prices from pair contract
        (uint256 price0Cumulative, uint256 price1Cumulative) = _getCurrentCumulativePrices();
        
         // Overflow is desired, casting never truncates
        // https://docs.uniswap.org/contracts/v2/guides/smart-contract-integration/building-an-oracle
        // Subtracting between two cumulative price values will result in
        // a number that fits within the range of uint256 as long as the
        // observations are made for periods of max 2^32 seconds, or ~136 years
        unchecked {
            // 5. Calculate TWAP price0Avg and price1Avg
            //    - TWAP = (current cumulative price - last cumulative price) / dt
            //    - Cast TWAP into uint224 and then into FixedPoint.uq112x112
            price0Avg = FixedPoint.uq112x112(
                uint224((price0Cumulative - price0CumulativeLast) / dt)
            );
            price1Avg = FixedPoint.uq112x112(
                uint224((price1Cumulative - price1CumulativeLast) / dt)
            );
        }

        // 6. Update state variables price0CumulativeLast, price1CumulativeLast and updatedAt
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        updatedAt = blockTimestamp;
    }

    // Returns the amount out corresponding to the amount in a for a given token
    function consult(address tokenIn, uint amountIn) external view returns (uint amountOut) {
        // 1. Require tokenIn is either token0 or token1
        tokenIn == token0 ? token0 : token1;

        // 2. Calculate amountOut 
        // - amountOut = TWAP of tokenIn * amountIn
        // - Use FixedPoint.mul to multiply TWAP of tokenIn with amountIn
        // - FixedPoint.mul returns a UQ144x112, so decode it to uint144
        if (tokenIn == token0) {
            amountOut = price0Avg.mul(amountIn).decode144();
        } else {
            amountOut = price1Avg.mul(amountIn).decode144();    
        }
    }
}
