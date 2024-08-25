// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { VectorLib } from "./libs/VectorLib.sol";
import { UtilsLib } from "./libs/UtilsLib.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "hardhat/console.sol";

/**
 * @title The base contract from which a particular CFMM should inherit from.
 * @notice Based on https://www-leland.stanford.edu/~boyd/papers/pdf/cfmm.pdf
 */
abstract contract CFMM is Context, ERC20 {
    using VectorLib for int256[];
    using VectorLib for uint256[];
    using UtilsLib for int256[];
    using UtilsLib for int256;
    using UtilsLib for uint256[];
    using UtilsLib for uint256;
    using SafeERC20 for IERC20;
    using SafeCast for int256;
    using SafeCast for uint256;

    IERC20[] _assetTokens;

    uint256 constant MINIMUM_LIQUIDITY = 1e3;

    event SwapEvent(address indexed initiator, address indexed recipient, int256[] assetDeltas);
    event LiquidityAddEvent(address indexed initiator, address indexed recipient, uint256[] assetDeltas);
    event LiquidityRemoveEvent(address indexed initiator, address indexed recipient, uint256 lpTokenAmount);

    error TradingFuncEvalNotEqualError();
    error TradingFuncGradientEvalNotEqualError();
    error SuppliedAssetLengthNotEqualError();

    constructor(
        IERC20[] memory assetTokens,
        string memory lpTokenName,
        string memory lpTokenSymbol
    ) ERC20(lpTokenName, lpTokenSymbol) {
        _assetTokens = assetTokens;
    }

    /**
     *  @notice Low level swap function that is intended to be used from a higher level router contract.
     *  @param assetDeltas Asset deltas which are describing the swap. The array can contain both positive and
     *  negative deltas at the same time. Positive delta means the message sender
     *  intends to deposit that particular ERC20 token to the pool, while negative deltas means the
     *  message sender intends to receive that particular ERC20 token. The message sender can also
     *  designate a `recipient` for the ERC20 tokens with negative delta.
     *  @param recipient The recipient of tokens corresponding to negative deltas.
     */
    function swap(int256[] memory assetDeltas, address recipient) external {
        require(assetDeltas.length == _assetTokens.length, SuppliedAssetLengthNotEqualError());
        uint256[] memory reserves = getReserves();
        uint256[] memory newReserves = reserves.applyDelta(assetDeltas);

        // Checking whether the trading function evaluates to approximately the same value before and after the swap.
        require(
            evalTradeFunc(reserves).approxEqual(evalTradeFunc(newReserves), getEvalTradeFuncMaxTolerance()),
            TradingFuncEvalNotEqualError()
        );

        // Transfer some tokens from the message sender and send some tokens to the recipient.
        uint256 assetTokensLength = _assetTokens.length;
        for (uint256 i; i < assetTokensLength; ++i) {
            if (assetDeltas[i] > 0) {
                _assetTokens[i].safeTransferFrom(_msgSender(), address(this), assetDeltas[i].toUint256());
            } else if (assetDeltas[i] < 0) {
                _assetTokens[i].safeTransfer(recipient, (assetDeltas[i] * -1).toUint256());
            }
        }
        emit SwapEvent(_msgSender(), recipient, assetDeltas);
    }

    /**
     *  @notice Low level add liquidity function that is intended to be used from a higher level router contract.
     *  @param assetDeltas Asset deltas should all be positive and they describe the amount of ERC20 tokens
     *                     that are going to be deposited to the pool.
     *  @param recipient The recipient of LP tokens.
     */
    function addLiquidity(uint256[] calldata assetDeltas, address recipient) external {
        require(assetDeltas.length == _assetTokens.length, SuppliedAssetLengthNotEqualError());
        if (totalSupply() == 0) {
            // locking minimal liquidity to avoid share inflation attacks:
            // https://docs.openzeppelin.com/contracts/4.x/erc4626#inflation-attack
            uint256 lpTokensToMintToUser = calculateInitialLPTokenSupply(assetDeltas) - MINIMUM_LIQUIDITY;
            _mint(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), MINIMUM_LIQUIDITY);
            _mint(_msgSender(), lpTokensToMintToUser);
        } else {
            uint256[] memory reserves = getReserves();
            uint256[] memory newReserves = reserves.add(assetDeltas);

            // Eq 12 in the linked paper: https://www-leland.stanford.edu/~boyd/papers/pdf/cfmm.pdf
            // Instead of trying to find alpha, the gradient vectors are normalized and compared.
            uint256[] memory reserveTradeFuncGradient = evalTradeFuncGradient(reserves).normalize();
            uint256[] memory newReserveTradeFuncGradient = evalTradeFuncGradient(newReserves).normalize();
            require(
                reserveTradeFuncGradient.approxEqual(
                    newReserveTradeFuncGradient,
                    getEvalTradeFuncGradientMaxTolerance()
                ),
                TradingFuncGradientEvalNotEqualError()
            );

            // Eq 13 in the linked paper: https://www-leland.stanford.edu/~boyd/papers/pdf/cfmm.pdf
            // A small deviation from the a paper is that, here we don't aim to normalize all the shares
            // to add up to 1, as that would require iterating through all the users who hold LP tokens.
            uint256 reserveValue = reserves.dotProduct(reserveTradeFuncGradient).removeFixedDecimalFactor();
            uint256 reserveValueIncrease = newReserves
                .dotProduct(newReserveTradeFuncGradient)
                .removeFixedDecimalFactor() - reserveValue;
            _mint(recipient, (totalSupply() * reserveValueIncrease) / reserveValue);
        }

        uint256 assetTokensLength = _assetTokens.length;
        for (uint256 i; i < assetTokensLength; ++i) {
            _assetTokens[i].safeTransferFrom(_msgSender(), address(this), assetDeltas[i]);
        }
        emit LiquidityAddEvent(_msgSender(), recipient, assetDeltas);
    }

    /**
     *  @notice Low level remove liquidity function that is intended to be used from a higher level router contract.
     *  @param lpTokenAmount The amount of LP tokens the message sender would like to burn.
     *  @param recipient The recipient of assets that results from burning the LP tokens.
     */
    function removeLiquidity(uint256 lpTokenAmount, address recipient) external {
        uint256[] memory reservesToSend = getReserves().mulScalar(lpTokenAmount).divScalar(totalSupply());

        uint256 assetTokensLength = _assetTokens.length;
        for (uint256 i; i < assetTokensLength; ++i) {
            _assetTokens[i].safeTransfer(recipient, reservesToSend[i]);
        }
        _burn(_msgSender(), lpTokenAmount);
        emit LiquidityRemoveEvent(_msgSender(), recipient, lpTokenAmount);
    }

    function getReserves() public view returns (uint256[] memory reserves) {
        uint256 assetTokensLength = _assetTokens.length;
        reserves = new uint256[](assetTokensLength);
        for (uint256 i; i < assetTokensLength; ++i) {
            // There is no need to store the token balances inside the CFMM smart contract, and
            // not storing it in CFMM saves a considerable amount of gas.
            // If someone sends tokens directly to the CFMM contract (without calling the swap function)
            // it will change the evaluation value of the trading function of the CFMM, but this
            // shound't cause any issue.
            reserves[i] = _assetTokens[i].balanceOf(address(this));
        }
    }

    function evalTradeFunc(uint256[] memory assets) internal virtual returns (uint256 tradeFuncEvalRes);

    function evalTradeFuncGradient(
        uint256[] memory assets
    ) internal virtual returns (uint256[] memory tradeFuncGradEvalRes);

    function calculateInitialLPTokenSupply(
        uint256[] calldata assets
    ) internal virtual returns (uint256 initialLpTokenSupply);

    function getEvalTradeFuncMaxTolerance() internal view virtual returns (uint256 evaleTradeFuncMaxTolerance);

    function getEvalTradeFuncGradientMaxTolerance() internal view virtual returns (uint256 evaleTradeFuncMaxTolerance);
}
