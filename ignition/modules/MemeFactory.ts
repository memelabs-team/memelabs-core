// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MemeFactoryModule = buildModule("MemeFactoryModule", (m) => {

  const MemeFactory = m.contract("MemeFactory");

  return { MemeFactory };
});

export default MemeFactoryModule;
