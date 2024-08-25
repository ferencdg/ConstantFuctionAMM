import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("GeometricMeanAMM", (m) => {
  const assetA = m.getParameter("assetA");
  const assetB = m.getParameter("assetB");
  const assetC = m.getParameter("assetC");
  const lpTokenName = m.getParameter("lpTokenName");
  const lpTokenSymbol = m.getParameter("lpTokenSymbol");
  const evalTradeFuncMaxTolerance = m.getParameter("evalTradeFuncMaxTolerance");
  const evalTradeFuncGradientMaxTolerance = m.getParameter("evalTradeFuncGradientMaxTolerance");

  const geometricMeanAMM = m.contract("GeometricMeanAMM", [
    [assetA, assetB, assetC],
    lpTokenName,
    lpTokenSymbol,
    evalTradeFuncMaxTolerance,
    evalTradeFuncGradientMaxTolerance,
  ]);

  return { geometricMeanAMM };
});
