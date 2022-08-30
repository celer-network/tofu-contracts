import { DeployFunction, DeployResult } from 'hardhat-deploy/types';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { config } from './config';

const deployCrossChainEndpoint: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = parseInt(await hre.getChainId(), 10);

  console.log('deploying CrossChainEndpoint on chain', chainId);

  const conf = config[chainId];
  const args = [conf.MessageBus, conf.MarketNG];
  const deployResult = await deploy('CrossChainEndpoint', {
    from: deployer,
    args: args
  });

  // await verify(hre, deployResult, args);
};

export const verify = async (hre: HardhatRuntimeEnvironment, deployResult: DeployResult, args?: any) => {
  return hre.run('verify:verify', {
    address: deployResult.address,
    constructorArguments: args
  });
};

deployCrossChainEndpoint.tags = ['CrossChainEndpoint'];
deployCrossChainEndpoint.dependencies = [];
export default deployCrossChainEndpoint;
