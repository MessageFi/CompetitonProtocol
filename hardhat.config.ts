import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';
import * as dotenv from 'dotenv';
import "hardhat-circom";

dotenv.config();
const PRIVATE_KEY: string | undefined = process.env.PRIVATE_KEY;
if (!PRIVATE_KEY) {
    throw new Error('Private key not found in environment variables');
}
const API_KEY: string | undefined = process.env.API_KEY;
if (!API_KEY) {
    throw new Error('Api key not found in environment variables');
}

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/${API_KEY}`,
      accounts: [PRIVATE_KEY]
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${API_KEY}`,
      accounts: [PRIVATE_KEY]
    },
    scroll_sepolia: {
      url: `https://sepolia-rpc.scroll.io`,
      accounts: [PRIVATE_KEY]
    }
  },
  circom: {
    inputBasePath: "./circuits",
    ptau: "https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_15.ptau",
    circuits: [
      {
        name: "quadratic",
      },
    ],
  },
};

export default config;
