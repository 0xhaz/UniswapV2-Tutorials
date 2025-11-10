// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {FullMath} from "src/libraries/FullMath.sol";

contract FullMathTest is Test {
    function testFullMul() public {
        uint256 a = type(uint256).max;
        uint256 b = type(uint256).max;

        (uint256 lo, uint256 hi) = FullMath.fullMul(a, b);

        console.log("lo:", lo);
        console.log("hi:", hi);

        assertEq(hi, type(uint256).max - 1);
        assertEq(lo, 1);
    }

    function testFullLt() public {
        uint256 a = type(uint256).max;
        uint256 b = type(uint256).max - 1;

        (uint256 al, uint256 ah) = FullMath.fullMul(a, b);
        (uint256 bl, uint256 bh) = FullMath.fullMul(b, a);

        assertFalse(FullMath.fullLt(al, ah, bl, bh));

        b = type(uint256).max;
        (bl, bh) = FullMath.fullMul(b, a);

        assertTrue(FullMath.fullLt(al, ah, bl, bh));
    }

    function testMulDiv() public {
        uint256 a = 2 ** 128;
        uint256 b = 2 ** 128;
        uint256 denominator = 2 ** 128;

        uint256 result = FullMath.mulDiv(a, b, denominator);

        console.log("result:", result);

        assertEq(result, 2 ** 128);
    }

    function testMulDivRevertOverflow() public {
        uint256 a = type(uint256).max;
        uint256 b = type(uint256).max;
        uint256 denominator = 1;

        vm.expectRevert();
        FullMath.mulDiv(a, b, denominator);
    }

    function testMulDivUp() public {
        uint256 a = 7;
        uint256 b = 3;
        uint256 denominator = 2;

        uint256 result = FullMath.mulDivUp(a, b, denominator);

        console.log("result:", result);

        assertEq(result, 11); // 7 * 3 / 2 = 10.5 -> rounded up to 11
    }

    function testMulDivUpRevertOverflow() public {
        uint256 a = type(uint256).max;
        uint256 b = type(uint256).max;
        uint256 denominator = 1;

        vm.expectRevert();
        FullMath.mulDivUp(a, b, denominator);
    }

    function testSaturatingMulDivUp() public {
        uint256 a = type(uint256).max;
        uint256 b = type(uint256).max;
        uint256 denominator = 1;

        uint256 result = FullMath.saturatingMulDivUp(a, b, denominator);

        console.log("result:", result);

        assertEq(result, type(uint256).max); // should saturate to max uint256
    }

    function testUnsafeMulDiv() public {
        uint256 a = 2 ** 128;
        uint256 b = 2 ** 128;
        uint256 denominator = 2 ** 128;

        uint256 result = FullMath.unsafeMulDiv(a, b, denominator);

        console.log("result:", result);

        assertEq(result, 2 ** 128); // (2**128 * 2**128) / 2**128 = 2**128
    }

    function testUnsafeMulDivAlt() public {
        uint256 a = 2 ** 128;
        uint256 b = 2 ** 128;
        uint256 denominator = 2 ** 128;

        uint256 result = FullMath.unsafeMulDivAlt(a, b, denominator);

        console.log("result:", result);

        assertEq(result, 2 ** 128); // (2**128 * 2**128) / 2**128 = 2**128
    }

    function testUnsafeMulDivUp() public {
        uint256 a = 7;
        uint256 b = 3;
        uint256 denominator = 2;

        uint256 result = FullMath.unsafeMulDivUp(a, b, denominator);

        console.log("result:", result);

        assertEq(result, 11); // 7 * 3 / 2 = 10.5 -> rounded up to 11
    }

    function testUnsafeMulShift() public {
        uint256 a = 2 ** 130;
        uint256 b = 2 ** 130;
        uint256 s = 128;

        uint256 result = FullMath.unsafeMulShift(a, b, s);

        console.log("result:", result);

        assertEq(result, 2 ** 132); // (2**130 * 2**130) >> 128 = 2**132
    }

    function testUnsafeMulShiftDown() public {
        uint a = 7;
        uint b = 3;
        uint s = 2;

        uint256 result = FullMath.unsafeMulShift(a, b, s);

        console.log("result:", result);

        assertEq(result, 5); // (7 * 3) >> 2 = 5.25 -> rounded down to 5
    }

    function testUnsafeMulShiftUp() public {
        uint256 a = 7;
        uint256 b = 3;
        uint256 s = 2;

        uint256 result = FullMath.unsafeMulShiftUp(a, b, s);

        console.log("result:", result);

        assertEq(result, 6); // (7 * 3) >> 2 = 5.25 -> rounded up to 6
    }
}
