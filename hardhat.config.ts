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
    ethMainnet: {
      url: process.env.ETHEREUM_ENDPOINT,
      accounts: [`0x${process.env.DEFAULT_PRIVATE_KEY}`]
    },
    arbNova: {
      url: process.env.ARBITRUM_NOVA_ENDPOINT,
      accounts: [`0x${process.env.DEFAULT_PRIVATE_KEY}`]
    },
    arbitrum: {
      url: process.env.ARBITRUM_ENDPOINT,
      accounts: [`0x${process.env.DEFAULT_PRIVATE_KEY}`]
    },
    goerli: {
      url: process.env.GOERLI_ENDPOINT,
      accounts: [`0x${process.env.DEFAULT_PRIVATE_KEY}`]
    },
    arbGoerli: {
      url: process.env.ARB_GOERLI_ENDPOINT,
      accounts: [`0x${process.env.DEFAULT_PRIVATE_KEY}`]
    }
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || '',
      arbNova: process.env.ARBISCAN_API_KEY || '',
      arbitrumOne: process.env.ARBISCAN_API_KEY || '',
      goerli: process.env.ETHERSCAN_API_KEY || ''
    },
    customChains: [
      {
        network: 'arbNova',
        chainId: 42170,
        urls: {
          apiURL: 'https://nova.arbitrum.io/rpc',
          browserURL: 'https://nova.arbiscan.io'
        }
      },
      {
        network: 'arbGoerli',
        chainId: 421613,
        urls: {
          apiURL: 'https://goerli-rollup.arbitrum.io/rpc',
          browserURL: 'https://goerli.arbiscan.io'
        }
      }
    ]
  }
};

export default config;
