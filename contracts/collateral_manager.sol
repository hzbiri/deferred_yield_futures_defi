// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IToken {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

contract CollateralManager is Ownable, AccessControl, ReentrancyGuard {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    AggregatorV3Interface public priceFeed;
    IToken public sClaimToken;

    mapping(address => uint256) public collateral;
    mapping(address => uint256) public debt;
    mapping(address => uint256) public riskScore;

    event CollateralDeposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event RiskScoreUpdated(address indexed user, uint256 score);
    event Liquidated(address indexed user, uint256 seizedCollateral);

    constructor(address token, address feed) {
        require(token != address(0) && feed != address(0), "Invalid address");
        sClaimToken = IToken(token);
        priceFeed = AggregatorV3Interface(feed);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORACLE_ROLE, msg.sender); // Default deployer is oracle
    }

    modifier onlyOracle() {
        require(hasRole(ORACLE_ROLE, msg.sender), "Not authorized oracle");
        _;
    }

    function depositCollateral(uint256 amount) external nonReentrant {
        require(sClaimToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        collateral[msg.sender] += amount;
        emit CollateralDeposited(msg.sender, amount);
    }

    function borrow(uint256 amount) external nonReentrant {
        require(address(this).balance >= amount, "Insufficient AVAX liquidity");
        uint256 price = getPrice();
        uint256 maxLTV = 100 - riskScore[msg.sender];
        uint256 collateralValue = (collateral[msg.sender] * price) / 1e8;
        uint256 maxBorrow = (collateralValue * maxLTV) / 100;

        require(amount + debt[msg.sender] <= maxBorrow, "Exceeds max borrow limit");
        debt[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
        emit Borrowed(msg.sender, amount);
    }

    function repay() external payable nonReentrant {
        require(msg.value <= debt[msg.sender], "Overpaying debt");
        debt[msg.sender] -= msg.value;
        emit Repaid(msg.sender, msg.value);
    }

    function updateRiskScore(address user, uint256 newScore) external onlyOracle {
        require(newScore <= 100, "Invalid score");
        riskScore[user] = newScore;
        emit RiskScoreUpdated(user, newScore);
    }

    function getPrice() public view returns (uint256) {
        (, int price, , ,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        return uint256(price);
    }

    function getLTV(address user) public view returns (uint256) {
        uint256 price = getPrice();
        uint256 collateralValue = (collateral[user] * price) / 1e8;
        if (collateralValue == 0) return 0;
        return (debt[user] * 100) / collateralValue;
    }

    function liquidate(address user) external onlyOracle nonReentrant {
        uint256 ltv = getLTV(user);
        require(ltv > 90, "LTV not high enough to liquidate");

        uint256 seizedCollateral = collateral[user];
        collateral[user] = 0;
        debt[user] = 0;

        require(sClaimToken.transfer(msg.sender, seizedCollateral), "Collateral transfer failed");
        emit Liquidated(user, seizedCollateral);
    }

    function withdrawExcessCollateral(uint256 amount) external nonReentrant {
        address user = msg.sender;
        require(collateral[user] >= amount, "Not enough collateral");

        uint256 price = getPrice();
        uint256 newCollateral = collateral[user] - amount;
        uint256 newCollateralValue = (newCollateral * price) / 1e8;
        uint256 safeMaxBorrow = (newCollateralValue * (100 - riskScore[user])) / 100;

        require(debt[user] <= safeMaxBorrow, "Unsafe withdrawal");

        collateral[user] = newCollateral;
        require(sClaimToken.transfer(user, amount), "Withdraw failed");
    }

    receive() external payable {}

    function getAccountSummary(address user) external view returns (
        uint256 userCollateral,
        uint256 userDebt,
        uint256 userRisk,
        uint256 userLTV
    ) {
        userCollateral = collateral[user];
        userDebt = debt[user];
        userRisk = riskScore[user];
        userLTV = getLTV(user);
    }
}
