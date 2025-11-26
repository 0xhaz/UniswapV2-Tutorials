// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {FixedPoint} from "src/libraries/FixedPoint.sol";
import {FullMath} from "src/libraries/FullMath.sol";

contract FixedPointTest is Test {
    using FixedPoint for *;

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function testFractionSmall() public {
        uint256 numerator = 5e18;
        uint256 denominator = 2e18;

        FixedPoint.uq112x112 memory result = FixedPoint.fraction(numerator, denominator);
        uint224 expected = uint224((numerator << RESOLUTION) / denominator);
        console.logUint(result._x);
        console.logUint(expected);

        assertEq(result._x, expected);
    }

    function testFractionLargeNumerator() public {
        uint256 numerator = 2 ** 144;
        uint256 denominator = 2e18;

        FixedPoint.uq112x112 memory result = FixedPoint.fraction(numerator, denominator);
        uint224 expected = uint224(FullMath.mulDiv(numerator, Q112, denominator));
        console.logUint(result._x);
        console.logUint(expected);

        assertEq(result._x, expected);
    }

    function testDecode() public {
        uint256 numerator = 9e18;
        uint256 denominator = 4e18;

        FixedPoint.uq112x112 memory result = FixedPoint.fraction(numerator, denominator);
        uint256 decoded = result._x >> RESOLUTION;

        console.logUint(result._x);
        console.logUint(decoded);

        assertEq(decoded, 2); // 9/4 = 2.25, truncated to 2
    }

    function testMul() public {
        uint256 numerator = 3e18;
        uint256 denominator = 2e18;
        uint256 multiplier = 4;

        FixedPoint.uq112x112 memory fp = FixedPoint.fraction(numerator, denominator);
        FixedPoint.uq144x112 memory result = fp.mul(multiplier);

        uint256 expected = ((numerator << RESOLUTION) / denominator) * multiplier;
        console.logUint(result._x);
        console.logUint(expected);

        assertEq(result._x, expected);
    }

    function testDecode144() public {
        uint256 value = 7.5e18;
        FixedPoint.uq112x112 memory fp = FixedPoint.fraction(uint256(value), 1e18);
        FixedPoint.uq144x112 memory multiplied = fp.mul(1);

        uint144 decoded = FixedPoint.decode144(multiplied);
        console.logUint(multiplied._x);
        console.logUint(decoded);

        assertEq(decoded, 7); // 7.5 truncated to 7
    }
}
