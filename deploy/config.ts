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
    MarketNG: '0x0b61C9AD8a968a14F273F68bbc393516983Df785'
  },
  // Arbitrum Goerli
  421613: {
    MessageBus: '0x7d43AABC515C356145049227CeE54B608342c0ad',
    MarketNG: '0x88532a901475b3ddf370386ae22c2067846f7d7a'
  }
};
