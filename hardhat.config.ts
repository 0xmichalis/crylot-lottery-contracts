import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";
import "@nomicfoundation/hardhat-toolbox";

import dotenv from 'dotenv'
dotenv.config();

const {
  PRIVATE_KEY,
} = process.env;

const sharedNetworkConfig: NetworkUserConfig = {};

if (PRIVATE_KEY) {
  sharedNetworkConfig.accounts = [PRIVATE_KEY];
}

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    base: {
      ...sharedNetworkConfig,
      chainId: 8453,
      url: 'https://mainnet.base.org',
    },
    'base-sepolia': {
      ...sharedNetworkConfig,
      chainId: 84532,
      url: 'https://sepolia.base.org',
    },
  }
};

export default config;
