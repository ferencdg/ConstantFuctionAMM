# Constant Function Market Maker

## High level design

The code is based on the paper: https://www-leland.stanford.edu/~boyd/papers/pdf/cfmm.pdf and part of the source code will refer to equations from that paper.

The main design goal was to be able to create new CFMMs by simply inheriting from a base class and override 2 methods.

1. evalTradeFunc - returns the value of the trading function at a speficic point
2. evalTradeFuncGradient - returns the gradient vector (partial derivatives) of the trading function at a specific point

The code supports an unlimited number of assets, and also gives an example of a geometric mean AMM with 3 assets.

The code is more of a creative solution to the problem of CFMM rather than a practical one for the following reasons.

1. Gas efficiency: by knowing the actual trading function like x * y = C, there could be more gas optimization done
1. Security: the CFMMs base class has to rely on predefined tolerance values when checking the changes in the return value from the trading function or from the gradient vector.

## Testing

Currently there are no proper unit tests, only tests that were used for manual testing. Those tests can be run by

```pnpm test:mock```

## Deploy

Currently the deployment is done into an in-memory node, as the main branch for fhevm-hardhat-template frequently messes up the project after running pnpm fhevm:start.

```pnpm task:deployGeometricMeanAMM```

## Limitations/Missing features

1. Tests are largely missing.
1. Limited documentation.
1. All the convenience classes like Router contract or Factory contract are missing.
1. Only ERC20 tokens are supported, native ETH is not.
1. Fees on Transfer type of ERC20 contracts are not supported.
1. No multi hop swapping
1. No audit was done
