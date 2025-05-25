// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract TruYanICO is Ownable {
    IERC20 public busd; // BUSD token (BEP-20)
    IERC20 public mzlx; // MZLx token
    AggregatorV3Interface internal priceFeed; // Chainlink BNB/USD

    uint256 public startTime;
    uint256 public endTime;
    uint256 public basePrice = 0.001 * 1e18; // $0.001 in BUSD
    uint256 public dailyIncrement = ((0.1 * 1e18) - (0.001 * 1e18)) / 90;
    uint256 public companyFeePercent = 50; // 50% of Binance gas fee

    struct User {
        address upline;
        uint256 totalPurchased;
        uint256 referralRewards;
    }

    mapping(address => User) public users;

    event TokensBought(address indexed user, uint256 amount, uint256 fee);

    constructor(address _busd, address _mzlx, address _priceFeed) {
        busd = IERC20(_busd);
        mzlx = IERC20(_mzlx);
        priceFeed = AggregatorV3Interface(_priceFeed);
        startTime = block.timestamp;
        endTime = startTime + 90 days;
    }

    // Buy tokens with BUSD (includes fee)
    function buyTokens(uint256 _busdAmount, address _upline) external {
        require(block.timestamp <= endTime, "ICO ended");
        
        // Calculate fee: Binance gas equivalent + 50% markup
        (, int256 bnbPrice, , , ) = priceFeed.latestRoundData();
        uint256 bnbGasFee = (tx.gasprice * 1e18) / uint256(bnbPrice);
        uint256 companyFee = (bnbGasFee * companyFeePercent) / 100;
        uint256 totalFee = bnbGasFee + companyFee;

        // Deduct BUSD from user
        busd.transferFrom(msg.sender, address(this), _busdAmount);
        
        // Calculate tokens bought (after fee)
        uint256 currentPrice = basePrice + (dailyIncrement * ((block.timestamp - startTime) / 1 days));
        uint256 tokensBought = (_busdAmount - totalFee) * 1e18 / currentPrice;

        // Distribute MLM rewards (6 levels, 2.5% each)
        address upline = _upline;
        for (uint i = 0; i < 6; i++) {
            if (upline == address(0)) break;
            uint256 reward = (tokensBought * 25) / 1000; // 2.5%
            mzlx.transfer(upline, reward);
            users[upline].referralRewards += reward;
            upline = users[upline].upline;
        }

        mzlx.transfer(msg.sender, tokensBought);
        emit TokensBought(msg.sender, tokensBought, totalFee);
    }

    // Admin: Adjust fees
    function setCompanyFee(uint256 _feePercent) external onlyOwner {
        companyFeePercent = _feePercent;
    }

    // Withdraw BUSD fees
    function withdrawFees() external onlyOwner {
        busd.transfer(owner(), busd.balanceOf(address(this)));
    }
}
