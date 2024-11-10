// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TestLPModule = buildModule("TestLPModule", (m) => {

  const TestLP = m.contract("TestLP");

  return { TestLP };
});

export default TestLPModule;
