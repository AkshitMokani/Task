// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


contract MultiSignature_Wallet
{
    
    uint public requiredSignatures = 3;
    address[] public signer;

    struct Transaction
    {
        address to;
        bool executed;
        mapping(address => bool) signatures;
    }

    Transaction[] private _transactions;

    event TransactionCreated(uint transactionId, address to);
    event TransactionSigned(uint transactionId, address signer);
    event TransactionExecuted(uint transactionId, address executer);

    function initialize(address[] memory _signer) public 
    {
        requiredSignatures = 3;
        require(_signer.length > 2,"At least 3 signer required");
        signer = _signer;
    }

    function submitTransaction(address to) public
    {
        require(checkOwner(msg.sender), "Not an owner!");
        require(to != address(0),"Invalid Destination Address");
        
        uint transactionId = _transactions.length;
        _transactions.push();
        Transaction storage transaction = _transactions[transactionId];
        transaction.to = to;
        transaction.executed = false;

        emit TransactionCreated(transactionId, to);
    }

    function signTransactrion(uint transactionId) public 
    {
        require(transactionId < _transactions.length, "Invalid Transaction ID");
        
        Transaction storage transaction = _transactions[transactionId];

        require(!transaction.executed, "Transaction Already Executed");
        require(checkOwner(msg.sender), "Only owner can sign the transaction");
        require(!transaction.signatures[msg.sender],"Transaction already signed by this owner");

        transaction.signatures[msg.sender] = true;

        emit TransactionSigned(transactionId, msg.sender);

        if(countSignatures(transaction) == requiredSignatures)
        {
            executeTransaction(transactionId);
        }
    }

    function executeTransaction(uint transactionId) private
    {
        require(transactionId < _transactions.length, "Invalid Transaction Id");

        Transaction storage transaction = _transactions[transactionId];

        require(!transaction.executed, " Transaction already executed");        
        require(countSignatures(transaction) >= requiredSignatures, " insufficient valid signatures");

        transaction.executed = true;

        // require(success, "Transaction execution failed");
        emit TransactionExecuted(transactionId, msg.sender);
    }

    function checkOwner(address account) public view returns(bool)
    {
        for(uint i = 0; i < signer.length; i++)
        {
            if(signer[i] == account)
            {
                return true;
            }
        }
        return false;
    }

    function countSignatures(Transaction storage transaction) private view returns(uint)
    {
        uint count = 0;
        for(uint i = 0; i < signer.length; i++)
        {
            if(transaction.signatures[signer[i]])
            {
                count++;
            }
        }
        return count;
    }

    function getTransaction(uint transactionId) public view returns(address, bool, uint)
    {
        require(transactionId < _transactions.length, "Invalid Transaction ID");

        Transaction storage transaction = _transactions[transactionId];
        return (transaction.to, transaction.executed, countSignatures(transaction));
    }

    function getOwners() public view returns(address[] memory,uint totalOwner)
    {
        return (signer,signer.length);
    }

    receive() external payable{}
}



//["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"]




