// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeferredYieldFutures is ERC20, Ownable {
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
    }

    mapping(address => Lock[]) public userLocks;

    event Locked(address indexed user, uint256 amount, uint256 unlockTime);
    event Redeemed(address indexed user, uint256 amount);
    event Liquidated(address indexed user, uint256 amount);

    constructor() ERC20("Staked Claim Token", "sClaimToken") {}

    function mint(address to, uint256 amount, uint256 lockDuration) external onlyOwner {
        _mint(to, amount);
        uint256 unlockTime = block.timestamp + lockDuration;
        userLocks[to].push(Lock(amount, unlockTime));
        emit Locked(to, amount, unlockTime);
    }

    function redeem() external {
        Lock[] storage locks = userLocks[msg.sender];
        uint256 totalRedeemable = 0;
        uint256 i = 0;

        while (i < locks.length) {
            if (locks[i].unlockTime <= block.timestamp) {
                totalRedeemable += locks[i].amount;
                locks[i] = locks[locks.length - 1];
                locks.pop();
            } else {
                i++;
            }
        }

        require(totalRedeemable > 0, "Nothing to redeem");
        _burn(msg.sender, totalRedeemable);
        emit Redeemed(msg.sender, totalRedeemable);
    }

    function liquidate(address user) external onlyOwner {
        Lock[] storage locks = userLocks[user];
        uint256 totalLocked = 0;

        for (uint256 i = 0; i < locks.length; i++) {
            totalLocked += locks[i].amount;
        }

        delete userLocks[user];
        _burn(user, totalLocked);
        emit Liquidated(user, totalLocked);
    }

    function getUserLocks(address user) external view returns (Lock[] memory) {
        return userLocks[user];
    }
}