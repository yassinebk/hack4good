import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "hardhat-abi-exporter";

import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import "hardhat-gas-reporter";
import "@nomicfoundation/hardhat-chai-matchers";
import "solidity-coverage";

dotenv.config();

const ALCHEMY_API_KEY = process.env.RINKEBY_ALCHEMY_API_KEY || "";
const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY || "";
console.log(
  ALCHEMY_API_KEY,
  `https://eth-rinkeby.alchemyapi.io/v2/${process.env.RINKEBY_ALCHEMY_API_KEY}`
);

const config: HardhatUserConfig = {
  abiExporter: [
    {
      path: "./front/Int3ract-front/src/ABI",
      runOnCompile: true,
      clear: true,
      flat: true,
      only: [":Int3r4ct$"],
      spacing: 2,
      format: "json",
    },
    {
      path: "./front/GreedyR0b0t-front/src/ABI",
      runOnCompile: true,
      clear: true,
      flat: true,
      only: [":GreedyRobot$"],
      spacing: 2,
      format: "json",
    },
  ],
  solidity: "0.8.13",
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY],
      chainId: 5,
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/6b3d1bbb24f84624a8e2aaae46c1ec95`,
      accounts: [GOERLI_PRIVATE_KEY],
      chainId: 4,
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
};

export default config;
