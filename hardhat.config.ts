import '@nomicfoundation/hardhat-toolbox';
import * as dotenv from 'dotenv';
import 'hardhat-deploy';
import { HardhatUserConfig } from 'hardhat/config';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.16',
    settings: {
      optimizer: {
        enabled: true,
        runs: 800
      }
    }
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5'
  },
  namedAccounts: {
    deployer: {
      default: 0
    }
  },
  defaultNetwork: 'hardhat',
  networks: {
    goerli: {
      url: process.env.GOERLI_ENDPOINT,
      accounts: [`0x${process.env.DEFAULT_PRIVATE_KEY}`]
    },
    arbGoerli: {
      url: process.env.ARB_GOERLI_ENDPOINT,
      accounts: [`0x${process.env.DEFAULT_PRIVATE_KEY}`]
    }
  }
};

export default config;
