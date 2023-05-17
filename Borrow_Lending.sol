
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC20
{
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract Borrow_Lending
{
    uint damount;
    uint totalPool = 0;
    uint public updatedPool = 0;
    uint withIntAmount = 0;
    uint withPendingInt = 0;

    mapping (address => uint) public DepositAmount;
    mapping (address => uint) public BorrowAmount;
    mapping (address => uint) withInterest;


    function depositFund(uint _damount) payable public //Lending
    {
        require(_damount > 0,"amount mus be greater than 0");
        damount = _damount;
        totalPool += damount;
        updatedPool = totalPool;
        DepositAmount[msg.sender] += _damount;
        
    }

    function borrowFund(uint bamount) payable public 
    {
        require(bamount <= damount, "you can't borrow more than deposited");
        require(updatedPool > 0,"sorry there is no fund for borrow");
        BorrowAmount[msg.sender] += bamount;
        payable(msg.sender).transfer(bamount);

        updatedPool -= bamount;

        uint interestAmount = ( BorrowAmount[msg.sender] * 10 ) / 100;
        withIntAmount = BorrowAmount[msg.sender] + interestAmount;
        withInterest[msg.sender] += withIntAmount;
        withPendingInt = withInterest[msg.sender];
    }

    function returnFund(uint amount) payable public
    {
        require(withInterest[msg.sender] > 0, "You didn't borrow any fund");
        require(amount <= withInterest[msg.sender],"you can't refund more amount");
        
        //withPendingInt = withInterest[msg.sender] - amount;
        withInterest[msg.sender] -= amount; 
        updatedPool = updatedPool + amount;
    }

    function removeLiquidity() payable public  
    {
        require(DepositAmount[msg.sender] > 0,"You didn't deposit any fund");
        require(address(this).balance >= DepositAmount[msg.sender],"there is not enough fund");
        uint IntLiquidity = ( DepositAmount[msg.sender] * 8 ) / 100;
        uint withIntLiquidity = IntLiquidity + DepositAmount[msg.sender];
        payable(msg.sender).transfer(withIntLiquidity);
        updatedPool -= DepositAmount[msg.sender];
        totalPool -= DepositAmount[msg.sender];
    }

    

    function TotalRefund() public view returns(uint PendingRefund)
    {
        return (withInterest[msg.sender]);
    }

    function checkBorrow() public view returns(bool)
    {
        if(withInterest[msg.sender] > 0)
        {
            return true;
        }
        else 
        {
            return false;
        }
    }
}
