// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { CFMM } from "./CFMM.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title Geometric Mean AMM with 3 assets implementing the x^3 * y * z = C trading function.
 * @notice Based on https://www-leland.stanford.edu/~boyd/papers/pdf/cfmm.pdf
 */
contract GeometricMeanAMM is CFMM {
    using Math for uint256;
    using SafeCast for int256;

    uint256 immutable EVAL_TRADE_FUNC_MAX_TOLERANCE;
    uint256 immutable EVAL_TRADE_FUNC_GRADIENT_MAX_TOLERANCE;

    constructor(
        IERC20[] memory assetTokens,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 evalTradeFuncMaxTolerance,
        uint256 evalTradeFuncGradientMaxTolerance
    ) CFMM(assetTokens, lpTokenName, lpTokenSymbol) {
        require(assetTokens.length == 3, SuppliedAssetLengthNotEqualError());
        EVAL_TRADE_FUNC_MAX_TOLERANCE = evalTradeFuncMaxTolerance;
        EVAL_TRADE_FUNC_GRADIENT_MAX_TOLERANCE = evalTradeFuncGradientMaxTolerance;
    }

    /**
     *  @notice Returns the value of the trading function at a speficic point.
     *  @param assets The point at which the trading function should be evaluated.
     *  @return tradeFuncEvalRes The value of the trading function at a speficic point.
     */
    function evalTradeFunc(uint256[] memory assets) internal virtual override returns (uint256 tradeFuncEvalRes) {
        tradeFuncEvalRes = assets[0] * assets[0] * assets[0] * assets[1] * assets[2];
    }

    /**
     *  @notice Returns the gradient vector (partial derivatives) of the trading function at a specific point.
     *  @param assets The point at which the gradient vector of the trading function should be evaluated.
     *  @return tradeFuncGradEvalRes The value of the gradient vector of the trading function at a speficic point.
     */
    function evalTradeFuncGradient(
        uint256[] memory assets
    ) internal virtual override returns (uint256[] memory tradeFuncGradEvalRes) {
        tradeFuncGradEvalRes = new uint256[](3);

        tradeFuncGradEvalRes[0] = 3 * assets[0] * assets[0] * assets[1] * assets[2];
        tradeFuncGradEvalRes[1] = assets[0] * assets[0] * assets[0] * assets[2];
        tradeFuncGradEvalRes[2] = assets[0] * assets[0] * assets[0] * assets[1];
    }

    /**
     *  @notice Calculates the amount of LP tokens that will be minted during the first call to addLiquidity method.
     *  @param assets The assets that were sent with the first call to addLiquidity method
     *  @return initialLpTokenSupply The amount of LP tokens that will be minted during the
     *          first call to addLiquidity method.
     */
    function calculateInitialLPTokenSupply(
        uint256[] calldata assets
    ) internal virtual override returns (uint256 initialLpTokenSupply) {
        // It would be even better to use cubic root here, but there is no direct solidity support to calculate it.
        initialLpTokenSupply = (assets[0] * assets[1] * assets[2]).sqrt();
    }

    function getEvalTradeFuncMaxTolerance()
        internal
        view
        virtual
        override
        returns (uint256 evaleTradeFuncMaxTolerance)
    {
        return EVAL_TRADE_FUNC_MAX_TOLERANCE;
    }

    function getEvalTradeFuncGradientMaxTolerance()
        internal
        view
        virtual
        override
        returns (uint256 evaleTradeFuncMaxTolerance)
    {
        return EVAL_TRADE_FUNC_GRADIENT_MAX_TOLERANCE;
    }
}
