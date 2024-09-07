// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//
//send eth directly
// lite version
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
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



    constructor(uint256 _lockPeriodDays, uint256 _withdrawETHWeiAmount, uint256 _withdrawTokenAmount) {
        owner = msg.sender;
        lastWithdrawDate = block.timestamp;
        //LOCK_PERIOD = _lockPeriodDays * 1 minutes; // minutes for test
        LOCK_PERIOD = _lockPeriodDays * 1 days; // Convert days to seconds
        WITHDRAWETH_WEI_AMOUNT = _withdrawETHWeiAmount;
        WITHDRAWTOKEN_AMOUNT = _withdrawTokenAmount;
    }

    receive() external payable {

    }

    function depositToken(address token, uint256 amount) external {
    	//increase allowance amount of token on current contract before deposit token.
        IERC20 tokenContract = IERC20(token);        
        require(tokenContract.transferFrom(msg.sender, address(this), amount), "Token transfer failed");        
    
    }


    function withdrawETH() external onlyOwner canWithdraw {
        require(address(this).balance >= WITHDRAWETH_WEI_AMOUNT, "Insufficient ETH balance");
        payable(owner).transfer(WITHDRAWETH_WEI_AMOUNT);
        lastWithdrawDate = block.timestamp;

    }

    function withdrawToken(address token) external onlyOwner canWithdraw {
        IERC20 tokenContract = IERC20(token);
        uint8 tokenDecimals = tokenContract.decimals();
        uint256 withdrawAmountAdjusted = WITHDRAWTOKEN_AMOUNT * (10 ** tokenDecimals);
        
        require(tokenContract.balanceOf(address(this)) >= withdrawAmountAdjusted, "Insufficient token balance");
        require(tokenContract.transfer(owner, withdrawAmountAdjusted), "Token transfer failed");
        lastWithdrawDate = block.timestamp;
    
    }


}


