// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Math} from "../../src/libraries/Math.sol";

contract MathTest is Test {
    function testMin() public {
        assertEq(Math.min(1, 2), 1);
        assertEq(Math.min(2, 1), 1);
        assertEq(Math.min(0, 0), 0);
        assertEq(Math.min(type(uint256).max, type(uint256).max - 1), type(uint256).max - 1);
    }

    function testSqrt() public {
        assertEq(Math.sqrt(0), 0);
        assertEq(Math.sqrt(1), 1);
        assertEq(Math.sqrt(4), 2);
        assertEq(Math.sqrt(9), 3);
        assertEq(Math.sqrt(16), 4);
        assertEq(Math.sqrt(25), 5);
        assertEq(Math.sqrt(26), 5); // test non-perfect square
        assertEq(Math.sqrt(1000000), 1000);
        assertEq(Math.sqrt(type(uint256).max), 340282366920938463463374607431768211455); // sqrt of max uint256
    }
}
