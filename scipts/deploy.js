// scripts/deploy.js

const hre = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  // 1. Deploy DeferredYieldFutures
  const DeferredYieldFutures = await hre.ethers.getContractFactory("DeferredYieldFutures");
  const dyf = await DeferredYieldFutures.deploy();
  await dyf.deployed();
  console.log("DeferredYieldFutures deployed to:", dyf.address);

  // 2. Define Chainlink Price Feed Address (e.g., AVAX/USD on Fuji)
  const priceFeedAddress = process.env.AVAX_USD_FEED;
  if (!priceFeedAddress || priceFeedAddress === "0x0000000000000000000000000000000000000000") {
    throw new Error("Please set AVAX_USD_FEED in .env");
  }

  // 3. Deploy CollateralManager
  const CollateralManager = await hre.ethers.getContractFactory("CollateralManager");
  const manager = await CollateralManager.deploy(dyf.address, priceFeedAddress);
  await manager.deployed();
  console.log("CollateralManager deployed to:", manager.address);

  // 4. Assign ORACLE_ROLE to deployer by default
  const ORACLE_ROLE = await manager.ORACLE_ROLE();
  const tx = await manager.grantRole(ORACLE_ROLE, deployer.address);
  await tx.wait();
  console.log("ORACLE_ROLE granted to:", deployer.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
