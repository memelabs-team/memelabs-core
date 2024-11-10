// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const VestingModule = buildModule("VestingModule", (m) => {

  const Vesting = m.contract("TokenVesting");

  return { Vesting };
});

export default VestingModule;
