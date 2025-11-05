// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112
// It's used to represent fractional numbers with high precision using only integers, which avoids
// the need for floating-point arithmetic and its associated issues in Solidity.

/// Format Overview
/// The Q format represents numbers using fixed-point binary
/// 112 bits for the integer part and 112 bits for the fractional part.
/// The entire number is stored in uint224 (112 + 112 = 224 bits).

library UQ112x112 {
    // scaling factor
    uint224 constant Q112 = 2 ** 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        // x = reserve1 * Q112 / reserve0
        z = x / uint224(y);
    }
}
