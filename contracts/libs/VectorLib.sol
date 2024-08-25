// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { UtilsLib } from "./UtilsLib.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

library VectorLib {
    using SafeCast for uint256;
    using SafeCast for int256;

    function add(int256[] memory a, int256[] memory b) internal pure returns (int256[] memory res) {
        uint256 aLength = a.length;
        res = new int256[](aLength);
        for (uint256 i; i < aLength; ++i) {
            res[i] = a[i] + b[i];
        }
    }

    function add(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory res) {
        uint256 aLength = a.length;
        res = new uint256[](aLength);
        for (uint256 i; i < aLength; ++i) {
            res[i] = a[i] + b[i];
        }
    }

    function applyDelta(uint256[] memory a, int256[] memory b) internal pure returns (uint256[] memory res) {
        uint256 aLength = a.length;
        res = new uint256[](aLength);
        for (uint256 i; i < aLength; ++i) {
            res[i] = (a[i].toInt256() + b[i]).toUint256();
        }
    }

    function mulScalar(int256[] memory a, int256 c) internal pure returns (int256[] memory res) {
        uint256 aLength = a.length;
        res = new int256[](aLength);
        for (uint256 i; i < aLength; ++i) {
            res[i] = a[i] * c;
        }
    }

    function mulScalar(uint256[] memory a, uint256 c) internal pure returns (uint256[] memory res) {
        uint256 aLength = a.length;
        res = new uint256[](aLength);
        for (uint256 i; i < aLength; ++i) {
            res[i] = a[i] * c;
        }
    }

    function divScalar(int256[] memory a, int256 c) internal pure returns (int256[] memory res) {
        uint256 aLength = a.length;
        res = new int256[](aLength);
        for (uint256 i; i < aLength; ++i) {
            res[i] = a[i] / c;
        }
    }

    function divScalar(uint256[] memory a, uint256 c) internal pure returns (uint256[] memory res) {
        uint256 aLength = a.length;
        res = new uint256[](aLength);
        for (uint256 i; i < aLength; ++i) {
            res[i] = a[i] / c;
        }
    }

    function dotProduct(int256[] memory a, int256[] memory b) internal pure returns (int256 res) {
        uint256 aLength = a.length;
        for (uint256 i; i < aLength; ++i) {
            res += a[i] * b[i];
        }
    }

    function dotProduct(uint256[] memory a, uint256[] memory b) internal pure returns (uint256 res) {
        uint256 aLength = a.length;
        for (uint256 i; i < aLength; ++i) {
            res += a[i] * b[i];
        }
    }

    function normalize(int256[] memory a) internal pure returns (int256[] memory res) {
        uint256 aLength = a.length;
        res = new int256[](aLength);
        for (uint256 i; i < aLength - 1; ++i) {
            res[i] = (a[i] * UtilsLib.FIXED_DECIMAL_FACTOR.toInt256()) / a[aLength - 1];
        }
        res[aLength - 1] = UtilsLib.FIXED_DECIMAL_FACTOR.toInt256();
    }

    function normalize(uint256[] memory a) internal pure returns (uint256[] memory res) {
        uint256 aLength = a.length;
        res = new uint256[](aLength);
        for (uint256 i; i < aLength - 1; ++i) {
            res[i] = (a[i] * UtilsLib.FIXED_DECIMAL_FACTOR) / a[aLength - 1];
        }
        res[aLength - 1] = UtilsLib.FIXED_DECIMAL_FACTOR;
    }

    function approxEqual(int256[] memory a, int256[] memory b, int256 tolerance) internal pure returns (bool) {
        uint256 aLength = a.length;
        for (uint256 i; i < aLength; ++i) {
            if (!UtilsLib.approxEqual(a[i], b[i], tolerance)) {
                return false;
            }
        }
        return true;
    }

    function approxEqual(uint256[] memory a, uint256[] memory b, uint256 tolerance) internal pure returns (bool) {
        uint256 aLength = a.length;
        for (uint256 i; i < aLength; ++i) {
            if (!UtilsLib.approxEqual(a[i], b[i], tolerance)) {
                return false;
            }
        }
        return true;
    }

    function toInt256Vec(uint256[] memory a) internal pure returns (int256[] memory res) {
        uint256 aLength = a.length;
        res = new int256[](aLength);
        for (uint256 i; i < aLength; ++i) {
            res[i] = a[i].toInt256();
        }
    }

    function toUint256Vec(int256[] memory a) internal pure returns (uint256[] memory res) {
        uint256 aLength = a.length;
        res = new uint256[](aLength);
        for (uint256 i; i < aLength; ++i) {
            res[i] = a[i].toUint256();
        }
    }
}
