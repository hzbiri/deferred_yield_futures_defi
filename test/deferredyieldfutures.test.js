// test/DeferredYieldFutures.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DeferredYieldFutures", function () {
  let dyf, owner, user;

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();
    const DeferredYieldFutures = await ethers.getContractFactory("DeferredYieldFutures");
    dyf = await DeferredYieldFutures.deploy();
    await dyf.deployed();
  });

  it("should mint locked tokens", async () => {
    await dyf.connect(owner).mint(user.address, 1000, 60);
    const balance = await dyf.balanceOf(user.address);
    expect(balance).to.equal(1000);
  });

  it("should not redeem before unlock", async () => {
    await dyf.connect(owner).mint(user.address, 500, 60);
    await expect(dyf.connect(user).redeem(0)).to.be.revertedWith("Tokens are still locked");
  });

  it("should redeem after unlock", async () => {
    await dyf.connect(owner).mint(user.address, 1000, 1);
    await ethers.provider.send("evm_increaseTime", [2]);
    await ethers.provider.send("evm_mine");
    await dyf.connect(user).redeem(0);
    const balance = await dyf.balanceOf(user.address);
    expect(balance).to.equal(0);
  });
});