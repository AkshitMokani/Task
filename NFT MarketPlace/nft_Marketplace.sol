/*
Build a NFT Marketplace where users can come to the platform and create NFTs. 
While creating the NFT, they need to pay 0.0001 ether. 
After creating the NFT, user can sell them either by direct sale or by auction. 

In direct sale –
    user can put the NFT price of their choice and list the NFT for sale. 
    The other users can come to the platform and see the listed NFT. 
    The users can purchase them by putting the selling price. 
    The amount will be stored in the contract later transferred to the seller when transferring the NFT to the buyer.
In auction – 
    users can create an auction to sell the NFTs. 
    In order to do that, they need to set the start time, end time of the auction and the starting price for the NFT.
    The buyers can bid until the auction gets ended.
    The bidding amount will be stored in the contract.
    When the auction gets ended, The highest bidder will be finalized and the NFT will be transferred to them.
    The amount will be transferred to the seller and the other bidders can withdraw their amount.
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract nft_Marketplace is ERC721
{
    uint public minPrice = 0.0001 ether;
    uint tokenId = 1;
    
    mapping(address => mapping(uint => uint)) SellList;
    mapping(uint => uint) public ListedNFT;
    mapping(address => uint) public totalBalance;
    mapping(uint => bool) isOnSale;

    uint public endAuctionTime;
    uint public startingBid;
    uint public highestbid;
    address public highestBidder;

    // bool auctionStarted;

    mapping(address => mapping(uint => uint)) AuctionList;
    mapping(address => uint) public totalBid;
    mapping(uint => bool) isOnAuction;
    mapping(uint => uint) public auctionListed;

    constructor() ERC721("Glacier","GNFT")
    {

    }

    function MintNFT() public payable 
    {
        require(msg.value == minPrice,"minimum price for mint NFT is 0.0001 ether");
        _safeMint(msg.sender, tokenId);
        tokenId++;
    }

    function ListNFT(uint _nftId,uint _nftPrice) public
    {
        require(msg.sender == ownerOf(_nftId),"Sorry you are not the NFT owner");
        require(_nftPrice > minPrice,"You can't list for below mint price");
        require(isOnSale[_nftId] != true,"it's already on sale");
        require(isOnAuction[_nftId] != true,"it's already on Auction");
        SellList[msg.sender][_nftId] = _nftPrice;
        ListedNFT[_nftId] = _nftPrice;
        isOnSale[_nftId] = true;
    }

    function buyNFT(uint _nftId,uint _nftPrice) payable public
    {
        require(isOnSale[_nftId] == true,"check again!!! it's not on sell");
        require(_nftPrice != 0,"Please check again");
        require(_nftPrice == ListedNFT[_nftId],"please check your buy price");
        require(msg.value == _nftPrice,"Please check amount");
        require(isOnSale[_nftId] == true,"check again!!! it's not on sell");
        ListedNFT[_nftId] = 0;
        totalBalance[ownerOf(_nftId)] += _nftPrice;
        isOnSale[_nftId] = false;
        _transfer(ownerOf(_nftId),msg.sender, _nftId);
    }

    function withdrawBalance() payable  public 
    {
        require(totalBalance[msg.sender] > 0,"you haven't any balance for withdraw");
        uint balance = totalBalance[msg.sender];
        totalBalance[msg.sender] = 0;
        payable (msg.sender).transfer(balance);
    }

    function startAuction(uint _nftId, uint _nftPrice, uint _DurationSecond) public
    {
        require(msg.sender == ownerOf(_nftId),"Sorry you are not the NFT owner");
        require(_nftPrice > minPrice,"You can't list on Auction below mint price");
        require(isOnSale[_nftId] != true,"it's already on sale");
        require(isOnAuction[_nftId] != true,"it's already on Auction");

        endAuctionTime = block.timestamp + _DurationSecond;
        AuctionList[msg.sender][_nftPrice] = endAuctionTime;
        isOnAuction[_nftId] = true;
        auctionListed[_nftId] = _nftPrice;

        startingBid = _nftPrice;
    }

    function bidOnNFT(uint _nftId,uint _bidAmount) payable public 
    {
        require(isOnAuction[_nftId] == true,"NFT not in Auction");
        require(_bidAmount > startingBid && _bidAmount > highestbid,"your bid must be higher ");
        require(msg.value ==_bidAmount,"Please check amount");
        require(block.timestamp < endAuctionTime,"auction is over");

        highestbid = _bidAmount;
        highestBidder = msg.sender;
        auctionListed[_nftId] = _bidAmount;

        totalBid[highestBidder] += highestbid;
    }

    function endAuction(uint _nftId) payable public 
    {
        require(isOnAuction[_nftId] == true,"NFT not in Auction");
        require(block.timestamp >= endAuctionTime,"Auction is still ongoing. wait till time over");


        if(highestBidder != address(0))
        {
            totalBid[highestBidder] -= highestbid;
            _transfer( ownerOf(_nftId), highestBidder , _nftId);
            payable (ownerOf(_nftId)).transfer(highestbid);
            auctionListed[_nftId] = 0;
            highestbid = 0;
            highestBidder = address(0);
        }

        auctionListed[_nftId] = 0;
        isOnAuction[_nftId] = false;
        highestbid = 0;
        highestBidder = address(0);
    }

    function withdrawBids() public 
    {
        uint balance = totalBid[msg.sender];
        payable (msg.sender).transfer(balance);
        totalBid[msg.sender] = 0;
    }
}