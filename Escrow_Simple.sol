// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Escrow
{
    address payable public buyer;
    address payable public seller;
    address payable public escrow;

    enum State{await_payment, await_delivery, complete}

    State public state;

    constructor(address payable _buyer, address payable _seller)
    {
        escrow = payable(msg.sender);
        require(escrow != _buyer,"escrow can't be buyer");
        require(escrow != _seller,"escrow can't be seller");
        buyer = _buyer;
        seller =_seller;

        state = State.await_payment;
    }

    function payment() payable public 
    {
        require(msg.sender == buyer,"Only buyer can do payment");
        require(state == State.await_payment,"must be in await payment state");
        state = State.await_delivery;
    }

    function confirmPayment() public
    {
        require(msg.sender == seller,"Only seller can confirm payment");
        require(state == State.await_delivery,"must be in await payment state");
        seller.transfer(address(this).balance);
        state = State.complete;
    }

    function failed() public payable 
    {
        require(msg.sender == seller,"Only seller can do this!!!");
        require(state == State.await_delivery,"must be in await payment state");
        buyer.transfer(address(this).balance);
        state = State.await_payment;
    }




}