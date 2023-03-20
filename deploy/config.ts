interface IDeployConfig {
  [chainId: number]: IChainConfig;
}

interface IChainConfig {
  MessageBus: string;
  MarketNG: string;
}

export const config: IDeployConfig = {
  // Ethereum
  1: {
    MessageBus: '0x4066d196a423b2b3b8b054f4f40efb47a74e200c',
    MarketNG: '0x7bc8b1B5AbA4dF3Be9f9A32daE501214dC0E4f3f'
  },
  // Arbitrum Nova
  42170: {
    MessageBus: '0xf5c6825015280cdfd0b56903f9f8b5a2233476f5',
    MarketNG: '0x7bc8b1B5AbA4dF3Be9f9A32daE501214dC0E4f3f'
  },
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
