// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LPVaultModule = buildModule("LPVaultModule", (m) => {

  const LPVault = m.contract("LPVault");

  return { LPVault };
});

export default LPVaultModule;
