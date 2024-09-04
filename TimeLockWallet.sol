// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//send token to checksum contract address directly
//send eth directly

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract TimeLockedWallet {
    address public owner;
    uint256 public lastWithdrawDate;
    uint256 public LOCK_PERIOD; // Period in seconds
    uint256 public immutable WITHDRAWETH_WEI_AMOUNT;
    uint256 public immutable WITHDRAWTOKEN_AMOUNT;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier canWithdraw() {
        require(block.timestamp >= lastWithdrawDate + LOCK_PERIOD, "Withdrawals locked");
        _;
    }

    event DepositedETH(address indexed sender, uint256 amount);
    event WithdrawnETH(address indexed owner, uint256 amount);
    event DepositedToken(address indexed token, address indexed sender, uint256 amount);
    event WithdrawnToken(address indexed token, address indexed owner, uint256 amount);

    constructor(uint256 _lockPeriodDays, uint256 _withdrawETHWeiAmount, uint256 _withdrawTokenAmount) {
        owner = msg.sender;
        lastWithdrawDate = block.timestamp;
        //LOCK_PERIOD = _lockPeriodDays * 1 minutes; // minutes for test
        LOCK_PERIOD = _lockPeriodDays * 1 days; // Convert days to seconds
        WITHDRAWETH_WEI_AMOUNT = _withdrawETHWeiAmount;
        WITHDRAWTOKEN_AMOUNT = _withdrawTokenAmount;
    }

    receive() external payable {
        emit DepositedETH(msg.sender, msg.value);
    }

    function depositToken(address token, uint256 amount) external {
        IERC20 tokenContract = IERC20(token);
        uint8 tokenDecimals = tokenContract.decimals();
        uint256 amountAdjusted = amount * (10 ** tokenDecimals);
        
        uint256 allowance = tokenContract.allowance(msg.sender, address(this));
        require(allowance >= amountAdjusted, "Check the token allowance");
        
        require(tokenContract.transferFrom(msg.sender, address(this), amountAdjusted), "Token transfer failed");
        
        emit DepositedToken(token, msg.sender, amountAdjusted);
    }


    function withdrawETH() external onlyOwner canWithdraw {
        require(address(this).balance >= WITHDRAWETH_WEI_AMOUNT, "Insufficient ETH balance");
        payable(owner).transfer(WITHDRAWETH_WEI_AMOUNT);
        lastWithdrawDate = block.timestamp;
        emit WithdrawnETH(owner, WITHDRAWETH_WEI_AMOUNT);
    }

    function withdrawToken(address token) external onlyOwner canWithdraw {
        IERC20 tokenContract = IERC20(token);
        uint8 tokenDecimals = tokenContract.decimals();
        uint256 withdrawAmountAdjusted = WITHDRAWTOKEN_AMOUNT * (10 ** tokenDecimals);
        
        require(tokenContract.balanceOf(address(this)) >= withdrawAmountAdjusted, "Insufficient token balance");
        require(tokenContract.transfer(owner, withdrawAmountAdjusted), "Token transfer failed");
        lastWithdrawDate = block.timestamp;
        emit WithdrawnToken(token, owner, withdrawAmountAdjusted);
    }


}


