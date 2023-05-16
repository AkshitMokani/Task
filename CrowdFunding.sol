// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdFunding {
    struct Campaign {
        string campaignName;
        uint targetAmount;
        uint timeDuration;
        uint raisedFund;
        uint pendingRaisedFund;
        bool funded;
    }

    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public campaignContributions;
    mapping(uint => address[]) public campaignContributors;

    uint public campaignIdCounter;
    uint public constant TOTAL_TOKEN_SUPPLY = 1_000_000_000;

    event CampaignCreated(uint campaignId, string campaignName, uint targetAmount, uint timeDuration);
    event ContributionMade(uint campaignId, address contributor, uint amount);
    event TokensIssued(address recipient, uint amount);
    event RefundIssued(uint campaignId, address contributor, uint amount);

    mapping(address => uint) public tokenBalances;

    constructor() {}

    function createCampaign(string memory _campaignName, uint _targetAmount, uint _timeDuration) public returns(uint) {
        require(_targetAmount > 0, "Target amount must be greater than zero");
        require(_timeDuration > block.timestamp, "Time duration must be in the future");

        uint campaignId = ++campaignIdCounter;

        Campaign storage campaign = campaigns[campaignId];
        campaign.campaignName = _campaignName;
        campaign.targetAmount = _targetAmount;
        campaign.timeDuration = _timeDuration;
        campaign.raisedFund = 0;
        campaign.pendingRaisedFund = _targetAmount;
        campaign.funded = false;

        emit CampaignCreated(campaignId, _campaignName, _targetAmount, _timeDuration);

        return campaignId;
    }

    function contributeToCampaign(uint _campaignId) payable public {
        require(campaigns[_campaignId].targetAmount > 0, "Campaign does not exist");
        require(!campaigns[_campaignId].funded, "Campaign has already reached its funding goal");
        require(msg.value > 0, "Contribution amount must be greater than zero");

        campaigns[_campaignId].raisedFund += msg.value;
        campaigns[_campaignId].pendingRaisedFund -= msg.value;
        campaignContributions[_campaignId][msg.sender] += msg.value;

        // Add the contributor if it's their first contribution to this campaign
        if (campaignContributions[_campaignId][msg.sender] == msg.value) {
            campaignContributors[_campaignId].push(msg.sender);
        }

        emit ContributionMade(_campaignId, msg.sender, msg.value);

        if (campaigns[_campaignId].raisedFund >= campaigns[_campaignId].targetAmount) {
            campaigns[_campaignId].funded = true;
            issueTokens(_campaignId);
        }
    }

    function issueTokens(uint _campaignId) internal {
        require(campaigns[_campaignId].raisedFund >= campaigns[_campaignId].targetAmount, "Funding goal not reached");

        uint totalContributions = campaigns[_campaignId].raisedFund;
        uint tokenSupply = (totalContributions * 10) / 100; // Calculate 10% of the total contributions as tokens

        // Distribute tokens to each contributor proportionally
        uint totalTokensIssued = 0;
        for (uint i = 0; i < campaignContributors[_campaignId].length; i++) {
            address contributor = campaignContributors[_campaignId][i];
            uint contribution = campaignContributions[_campaignId][contributor];
            uint tokensToIssue = (contribution * tokenSupply) / totalContributions;
            Token token = new Token(tokensToIssue);
            tokenBalances[contributor] += tokensToIssue;
            token.transfer(contributor, tokensToIssue);
        
            totalTokensIssued += tokensToIssue;
        
            emit TokensIssued(contributor, tokensToIssue);
        }

        // Issue any remaining tokens to the contract address
        uint remainingTokens = tokenSupply - totalTokensIssued;
        Token remainingToken = new Token(remainingTokens);
        tokenBalances[address(this)] += remainingTokens;
        remainingToken.transfer(address(this), remainingTokens);
    }

    function requestRefund(uint _campaignId) public 
    {
        require(campaigns[_campaignId].targetAmount > 0, "Campaign does not exist");
        require(campaigns[_campaignId].raisedFund < campaigns[_campaignId].targetAmount, "Campaign has reached its funding goal");
        require(campaignContributions[_campaignId][msg.sender] > 0, "No contribution found for the campaign");

        uint refundAmount = campaignContributions[_campaignId][msg.sender];
        campaignContributions[_campaignId][msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);
        emit RefundIssued(_campaignId, msg.sender, refundAmount);
    }

}

contract Token 
{
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(uint256 _totalSupply) 
    {
        name = "MyToken";
        symbol = "MTK";
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _amount) public returns (bool) 
    {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;

        return true;
    }   
}

