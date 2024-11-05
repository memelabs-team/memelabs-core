// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MemeUSDTModule = buildModule("MemeUSDTModule", (m) => {

  const MemeUSDT = m.contract("MemeUSDT");

  return { MemeUSDT };
});

export default MemeUSDTModule;
