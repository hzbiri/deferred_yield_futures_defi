// test/CollateralManager.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CollateralManager", function () {
  let dyf, cm, owner, user;
  const mockPrice = 1_000_000_00; // 100 USD with 8 decimals

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();

    const MockPriceFeed = await ethers.getContractFactory("MockPriceFeed");
    const priceFeed = await MockPriceFeed.deploy(mockPrice);
    await priceFeed.deployed();

    const DeferredYieldFutures = await ethers.getContractFactory("DeferredYieldFutures");
    dyf = await DeferredYieldFutures.deploy();
    await dyf.deployed();

    const CollateralManager = await ethers.getContractFactory("CollateralManager");
    cm = await CollateralManager.deploy(dyf.address, priceFeed.address);
    await cm.deployed();

    await dyf.connect(owner).mint(user.address, 1000, 0);
    await dyf.connect(user).approve(cm.address, 1000);
  });

  it("should allow collateral deposit", async () => {
    await cm.connect(user).depositCollateral(1000);
    const deposited = await cm.collateral(user.address);
    expect(deposited).to.equal(1000);
  });

  it("should update and use risk score for borrowing", async () => {
    await cm.connect(user).depositCollateral(1000);
    await cm.connect(owner).updateRiskScore(user.address, 30); // 70% LTV
    await cm.connect(user).borrow(700);
    const debt = await cm.debt(user.address);
    expect(debt).to.equal(700);
  });

  it("should reject borrow over max LTV", async () => {
    await cm.connect(user).depositCollateral(1000);
    await cm.connect(owner).updateRiskScore(user.address, 40); // 60% LTV
    await expect(cm.connect(user).borrow(700)).to.be.revertedWith("Exceeds LTV limit");
  });
});
