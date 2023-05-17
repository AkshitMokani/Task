// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Escrow {
    enum EscrowStatus { AWAITING_PAYMENT, FUNDS_DEPOSITED, FUNDS_RELEASED, DISPUTE_RESOLVED }

    struct Transaction {
        address buyer;
        address seller;
        uint256 amount;
        EscrowStatus status;
        bool buyerApproved;
        bool sellerApproved;
    }

    mapping(address => Transaction) public transactions;

    event FundsDeposited(address buyer, address seller, uint256 amount);
    event FundsReleased(address buyer, address seller, uint256 amount);
    event DisputeResolved(address buyer, address seller, uint256 amount);

    function depositFunds(address _seller) public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        require(transactions[msg.sender].status == EscrowStatus.AWAITING_PAYMENT, "No pending transaction found");

        Transaction storage transaction = transactions[msg.sender];
        transaction.buyer = msg.sender;
        transaction.seller = _seller;
        transaction.amount = msg.value;
        transaction.status = EscrowStatus.FUNDS_DEPOSITED;

        emit FundsDeposited(msg.sender, _seller, msg.value);
    }

    function releaseFunds(address _buyer) public {
        Transaction storage transaction = transactions[_buyer];
        require(transaction.status == EscrowStatus.FUNDS_DEPOSITED, "Funds not deposited");
        require(msg.sender == transaction.seller, "Only the seller can release the funds");

        transaction.sellerApproved = true;
        if (transaction.buyerApproved) {
            transaction.status = EscrowStatus.FUNDS_RELEASED;
            payable(transaction.seller).transfer(transaction.amount);
            emit FundsReleased(_buyer, transaction.seller, transaction.amount);
        }
    }

    function disputeTransaction(address _buyer) public {
        Transaction storage transaction = transactions[_buyer];
        require(transaction.status == EscrowStatus.FUNDS_DEPOSITED, "Funds not deposited");
        require(msg.sender == transaction.buyer, "Only the buyer can initiate a dispute");

        transaction.status = EscrowStatus.DISPUTE_RESOLVED;
        emit DisputeResolved(_buyer, transaction.seller, transaction.amount);
    }

    function approveTransaction() public {
        Transaction storage transaction = transactions[msg.sender];
        require(transaction.status == EscrowStatus.FUNDS_DEPOSITED, "Funds not deposited");

        if (msg.sender == transaction.buyer) {
            require(!transaction.buyerApproved, "Buyer has already approved the transaction");
            transaction.buyerApproved = true;
        } else if (msg.sender == transaction.seller) {
            require(!transaction.sellerApproved, "Seller has already approved the transaction");
            transaction.sellerApproved = true;
        }

        if (transaction.buyerApproved && transaction.sellerApproved) {
            transaction.status = EscrowStatus.FUNDS_RELEASED;
            payable(transaction.seller).transfer(transaction.amount);
            emit FundsReleased(transaction.buyer, transaction.seller, transaction.amount);
        }
    }

    function getTransactionStatus(address _user) public view returns (EscrowStatus) {
        return transactions[_user].status;
    }
}
