// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "hardhat/console.sol";

library UtilsLib {
    using Strings for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 constant FIXED_DECIMAL_FACTOR = 1e18;

    function removeFixedDecimalFactor(int256 a) internal pure returns (int256 res) {
        res = a / FIXED_DECIMAL_FACTOR.toInt256();
    }

    function removeFixedDecimalFactor(uint256 a) internal pure returns (uint256 res) {
        res = a / FIXED_DECIMAL_FACTOR;
    }

    function approxEqual(int256 a, int256 b, int256 tolerance) internal pure returns (bool res) {
        res = absDiff(a, b) <= tolerance;
    }

    function approxEqual(uint256 a, uint256 b, uint256 tolerance) internal pure returns (bool res) {
        res = absDiff(a, b) <= tolerance;
    }

    function absDiff(int256 a, int256 b) internal pure returns (int256 res) {
        res = (a > b ? a - b : b - a);
    }

    function absDiff(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a > b ? a - b : b - a);
    }

    function printArr(int256[] memory arr) internal pure {
        uint256 aLength = arr.length;

        for (uint256 i; i < aLength; ++i) {
            console.log(i.toString(), ": ", arr[i].toUint256());
        }
    }

    function printArr(uint256[] memory arr) internal pure {
        uint256 aLength = arr.length;

        for (uint256 i; i < aLength; ++i) {
            console.log(i.toString(), ": ", arr[i]);
        }
    }
}
