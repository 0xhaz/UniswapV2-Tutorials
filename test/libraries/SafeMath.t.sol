// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SafeMath} from "../../src/libraries/SafeMath.sol";

contract SafeMathTest is Test {
    function testAdd() public {
        assertEq(SafeMath.add(1, 2), 3);
        assertEq(SafeMath.add(0, 0), 0);
        assertEq(SafeMath.add(type(uint256).max - 1, 1), type(uint256).max);
    }

    function testAddOverflow() public {
        vm.expectRevert();
        SafeMath.add(type(uint256).max, 1);
    }

    function testSub() public {
        assertEq(SafeMath.sub(2, 1), 1);
        assertEq(SafeMath.sub(0, 0), 0);
        assertEq(SafeMath.sub(type(uint256).max, type(uint256).max - 1), 1);
    }

    function testSubUnderflow() public {
        vm.expectRevert();
        SafeMath.sub(0, 1);
    }

    function testMul() public {
        assertEq(SafeMath.mul(2, 3), 6);
        assertEq(SafeMath.mul(0, 100), 0);
        assertEq(SafeMath.mul(type(uint256).max / 2, 2), type(uint256).max - 1);
    }

    function testMulOverflow() public {
        vm.expectRevert();
        SafeMath.mul(type(uint256).max, 2);
    }
}
