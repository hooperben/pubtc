import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";

import "dotenv/config";

const config: HardhatUserConfig = {
  networks: {
    citreaDevnet: {
      url: "https://rpc.testnet.citrea.xyz",
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000,
      },
      // viaIR: true,
    },
  },
};

export default config;
