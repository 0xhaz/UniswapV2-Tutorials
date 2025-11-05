// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {UQ112x112} from "../../src/libraries/UQ112x112.sol";

contract UQ112x112Test is Test {
    using UQ112x112 for uint224;

    function testEncode() public {
        uint112 value = 5;
        uint224 encoded = UQ112x112.encode(value);
        assertEq(encoded, uint224(value) << 112); // 5 * 2**112
    }

    function testUqdiv() public {
        uint112 divisor = 5;
        uint224 encoded = UQ112x112.encode(20); // 20 in UQ112x112
        uint224 result = UQ112x112.uqdiv(encoded, divisor);
        assertEq(result, UQ112x112.encode(4)); // 20 / 5 = 4
    }
}
