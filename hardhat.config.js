// hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    fuji: {
      url: process.env.FUJI_RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      avalancheFujiTestnet: process.env.ETHERSCAN_API_KEY
    }
  }
};

// package.json
{
  "name": "ai-deferred-yield-futures",
  "version": "1.0.0",
  "description": "AI-powered Deferred Yield Futures on Avalanche C-Chain",
  "scripts": {
    "compile": "npx hardhat compile",
    "test": "npx hardhat test",
    "deploy": "npx hardhat run scripts/deploy.js --network fuji",
    "verify": "npx hardhat verify --network fuji"
  },
  "devDependencies": {
    "@nomicfoundation/hardhat-toolbox": "^2.0.0",
    "@nomiclabs/hardhat-etherscan": "^3.1.0",
    "chai": "^4.3.7",
    "ethers": "^5.7.2",
    "hardhat": "^2.17.0"
  },
  "keywords": [
    "avalanche",
    "chainlink",
    "ai",
    "yield",
    "defi",
    "hardhat"
  ]
}