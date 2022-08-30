interface IDeployConfig {
  [chainId: number]: IChainConfig;
}

interface IChainConfig {
  MessageBus: string;
  MarketNG: string;
}

export const config: IDeployConfig = {
  // Goerli
  5: {
    MessageBus: '0xF25170F86E4291a99a9A560032Fe9948b8BcFBB2',
    MarketNG: '0x0000000000000000000000000000000000000000'
  },
  // Arbitrum Goerli
  421613: {
    MessageBus: '0x7d43AABC515C356145049227CeE54B608342c0ad',
    MarketNG: '0x0000000000000000000000000000000000000000'
  }
};
