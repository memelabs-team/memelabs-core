// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CommunityTreasuryModule = buildModule("CommunityTreasuryModule", (m) => {

  const CommunityTreasury = m.contract("CommunityTreasury");

  return { CommunityTreasury };
});

export default CommunityTreasuryModule;
