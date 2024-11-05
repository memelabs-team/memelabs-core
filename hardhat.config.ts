import { HardhatUserConfig,vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";


const PRIVATE_KEY = vars.get("PRIVATE_KEY");
const API_KEY = vars.get("API_KEY");
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true
    }
  },
  networks: {
    bsc_testnet: {
      url: `https://bsc-testnet-rpc.publicnode.com`,
      accounts: [PRIVATE_KEY],
    },
    bsc: {
      url: `https://bsc-dataseed4.ninicoin.io`,
      accounts: [PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: API_KEY
  },
  sourcify: {
    enabled: true
  }
};

export default config;
