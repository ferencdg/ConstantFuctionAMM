# Constant Function Market Maker

## High level design

The code is based on the paper: https://www-leland.stanford.edu/~boyd/papers/pdf/cfmm.pdf and part of the source code will refer to equations from that paper.

The main design goal was to be able to create new CFMMs by simply inheriting from a base class and override 2 methods.

1. evalTradeFunc - returns the value of the trading function at a speficic point
2. evalTradeFuncGradient - returns the gradient vector (partial derivatives) of the trading function at a specific point

The code supports an unlimited number of assets, and also gives an example of a geometric mean AMM with 3 assets.

The code is more of a creative solution to the problem of CFMM rather than a practical one for the following reasons.

1. Gas efficiency: by knowing the actual trading function like x * y = C, there could be more gas optimization done
1. Security: the CFMMs base class has to rely on predefined tolerance values when checking the changes in the return value from the trading function or from the gradient vector. More analysis needs to be done about the security implication of those tolerance levels.
1. Trading function evaluation: evaluating the trading function might exceed the maximum value of uin256, so it requires special care. Instead of evaluating the original trading function, the Nth root of the trading function could be considered.

## Testing

Currently there are no proper unit tests, only tests that were used for manual testing. Those tests can be run by

```pnpm test:mock```

Please note that that this project was created based on Zama template and will fail with:
Artifact for contract "fhevm/lib/ACL.sol:ACL" not found.

## Deploy

```pnpm task:deployGeometricMeanAMM```

Please note that that this project was created based on Zama template and will fail with:
Artifact for contract "fhevm/lib/ACL.sol:ACL" not found.

## Limitations/Missing features/Comments

1. Tests are largely missing.
1. Limited documentation.
1. All the convenience classes like Router contract or Factory contract are missing.
1. Only ERC20 tokens are supported, native ETH is not.
1. Fees on Transfer type of ERC20 contracts are not supported.
1. No multi hop swapping
1. No audit was done
1. The Code heavily relies on the overflow/underflow protection implmenented in the solidity compiler starting from version 0.8.
