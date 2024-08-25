import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { loadFixture, time } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

import { ERC20, GeometricMeanAMM, MockERC20 } from "../typechain-types";

const TOKENS_TO_MINT = BigInt(1e20);

// There tests are only used for manual testing, they are not proper unittests.
describe("GeometricMeanAMM", function () {
  async function createERC20(tokenName: string, tokenSymbol: string, accToFund: string): Promise<MockERC20> {
    const tokenContract = await hre.ethers.getContractFactory("MockERC20");
    const token = await tokenContract.deploy(tokenName, tokenSymbol);
    token.mint(accToFund, TOKENS_TO_MINT);
    return token;
  }

  async function testFixture(): Promise<GeometricMeanAMM> {
    const [owner] = await hre.ethers.getSigners();
    const tokenA = await createERC20("assetA", "A1", owner.address);
    const tokenB = await createERC20("assetB", "B1", owner.address);
    const tokenC = await createERC20("assetC", "C1", owner.address);
    const geometricMeanAMMContract = await hre.ethers.getContractFactory("GeometricMeanAMM");
    const geometricMeanAMM = await geometricMeanAMMContract.deploy(
      [tokenA, tokenB, tokenC],
      "LPToken",
      "LP1",
      BigInt(1e19),
      BigInt(1e18),
    );
    await tokenA.approve(geometricMeanAMM.getAddress(), TOKENS_TO_MINT);
    await tokenB.approve(geometricMeanAMM.getAddress(), TOKENS_TO_MINT);
    await tokenC.approve(geometricMeanAMM.getAddress(), TOKENS_TO_MINT);
    return geometricMeanAMM;
  }

  describe("Manual testing using console.log", function () {
    it("Adding liquidity and swapping", async function () {
      const [testUser] = await hre.ethers.getSigners();
      const testUserAddr = testUser.address;
      const geometricMeanAMM = await loadFixture(testFixture);
      await geometricMeanAMM.addLiquidity([100_000, 100_000, 100_000], testUserAddr);

      // taking assetA and assetB and supplying assetC
      await geometricMeanAMM.swap([-50_000, -25_000, 966_666], testUserAddr);

      // taking assetA and assetB and supplying assetC in the wrong ratio
      await expect(geometricMeanAMM.swap([-50_000, -25_000, 1], testUserAddr)).to.be.revertedWithCustomError(
        geometricMeanAMM,
        "TradingFuncEvalNotEqualError",
      );
    });

    it("Removing liquidity", async function () {
      const [testUser] = await hre.ethers.getSigners();
      const testUserAddr = testUser.address;
      const geometricMeanAMM = await loadFixture(testFixture);
      await geometricMeanAMM.addLiquidity([100_000, 100_000, 100_000], testUserAddr);

      // removing liquidity
      await geometricMeanAMM.removeLiquidity((await geometricMeanAMM.balanceOf(testUser)) / 3n, testUserAddr);
    });

    it("Adding liquidity multiple times", async function () {
      const [testUser] = await hre.ethers.getSigners();
      const testUserAddr = testUser.address;
      const geometricMeanAMM = await loadFixture(testFixture);
      await geometricMeanAMM.addLiquidity([100_000, 100_000, 100_000], testUserAddr);

      // adding symmetric liquidity, lp should be tripled
      await geometricMeanAMM.addLiquidity([200_000, 200_000, 200_000], testUserAddr);

      // adding liquidity in the wrong ratio
      await expect(geometricMeanAMM.addLiquidity([200_000, 0, 0], testUserAddr)).to.be.revertedWithCustomError(
        geometricMeanAMM,
        "TradingFuncGradientEvalNotEqualError",
      );
    });
  });
});
