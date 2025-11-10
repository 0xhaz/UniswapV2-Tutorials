// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {UnsafeMath} from "../../src/utils/UnsafeMath.sol";

contract UnsafeMathTest is Test {
    using UnsafeMath for uint256;
    using UnsafeMath for int256;

    function testUnsafeIncUint256() public {
        uint256 x = 5;
        uint256 result = x.unsafeInc();
        assertEq(result, 6); // Incrementing 5 gives 6
    }

    function testUnsafeIncInt256() public {
        int256 x = 5;
        int256 result = x.unsafeInc();
        assertEq(result, 6);
    }

    function testUnsafeDecUint256() public {
        uint256 x = 5;
        uint256 result = x.unsafeDec();
        assertEq(result, 4); // Decrementing 5 gives 4
    }

    function testUnsafeNegInt256() public {
        int256 x = -5;
        int256 result = x.unsafeNeg();
        assertEq(result, 5); // Negation of -5 is 5
    }

    function testUnsafeAbsInt256() public {
        int256 x = -10;
        uint256 result = x.unsafeAbs();
        assertEq(result, 10); // Absolute value of -10 is 10
    }

    function testUnsafeDivUint256() public {
        uint256 numerator = 10;
        uint256 denominator = 2;
        uint256 result = numerator.unsafeDiv(denominator);
        assertEq(result, 5); // 10 / 2 = 5
    }

    function testUnsafeDivInt256() public {
        int256 numerator = 10;
        int256 denominator = 2;
        int256 result = numerator.unsafeDiv(denominator);
        assertEq(result, 5); // 10 / 2 = 5
    }

    function testUnsafeModUint256() public {
        uint256 x = 10;
        uint256 y = 3;
        uint256 result = x.unsafeMod(y);
        assertEq(result, 1); // 10 % 3 = 1
    }

    function testUnsafeMulModUint256() public {
        uint256 x = 4;
        uint256 y = 3;
        uint256 modulus = 5;
        uint256 result = x.unsafeMulMod(y, modulus);
        assertEq(result, 2); // (4 * 3) % 5 = 12 % 5 = 2
    }

    function testUnsafeAddModUint256() public {
        uint256 x = 4;
        uint256 y = 3;
        uint256 modulus = 5;
        uint256 result = x.unsafeAddMod(y, modulus);
        assertEq(result, 2); // (4 + 3) % 5 = 7 % 5 = 2
    }

    function testUnsafeDivUpUint256() public {
        uint256 n = 10;
        uint256 d = 3;
        uint256 result = n.unsafeDivUp(d);
        assertEq(result, 4); // 10 / 3 = 3.33... rounded up to 4
    }

    function testUnsafeDivUpInt256() public {
        int256 n = 10;
        int256 d = 3;
        int256 result = n.unsafeDivUp(d);
        assertEq(result, 4); // 10 / 3 = 3.33... rounded up to 4
    }

    function testUnsafeAdd() public {
        uint256 a = 7;
        uint256 b = 5;
        uint256 result = a.unsafeAdd(b);
        assertEq(result, 12); // 7 + 5 = 12
    }
}
