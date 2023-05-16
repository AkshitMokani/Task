pragma solidity ^0.8.19;

contract CrowdfundingPlatform {

  
  // Structs
  struct Campaign {
    string name;
    string description;
    uint256 goal;
    uint256 fundingDeadline;
    uint256 totalContributions;
    bool funded;
  }

  // Mapping of campaign IDs to campaigns
  mapping(bytes32 => Campaign) public campaigns;

  // Function to create a new campaign
  function createCampaign(
    string name,
    string description,
    uint256 goal,
    uint256 fundingDeadline
  ) public returns (bytes32 campaignId) {
    // Check that the goal is positive
    require(goal > 0);

    // Check that the funding deadline is in the future
    require(now < fundingDeadline);

    // Create a new campaign
    bytes32 campaignId = sha3(abi.encodePacked(name, description, goal, fundingDeadline));
    campaigns[campaignId] = Campaign(name, description, goal, fundingDeadline, 0, false);

    // Emit a campaign created event
    emit CampaignCreated(campaignId, name, description, goal, fundingDeadline);

    return campaignId;
  }

  // Function to contribute to a campaign
  function contributeToCampaign(
    bytes32 campaignId,
    uint256 amount
  ) public returns (bool success) {
    // Check that the campaign exists
    require(campaigns[campaignId].name != "");

    // Check that the amount is positive
    require(amount > 0);

    // Check that the campaign is still open
    require(now < campaigns[campaignId].fundingDeadline);

    // Update the campaign's total contributions
    campaigns[campaignId].totalContributions += amount;

    // Emit a contribution made event
    emit ContributionMade(campaignId, amount, msg.sender);

    // If the campaign has reached its goal, mark it as funded
    if (campaigns[campaignId].totalContributions >= campaigns[campaignId].goal) {
      campaigns[campaignId].funded = true;
      emit CampaignFunded(campaignId, campaigns[campaignId].totalContributions);
    }

    return true;
  }

  // Function to refund contributions to a campaign that has not been funded
  function refundContributions(bytes32 campaignId) public returns (bool success) {
    // Check that the campaign exists
    require(campaigns[campaignId].name != "");

    // Check that the campaign has not been funded
    require(!campaigns[campaignId].funded);

    // Return all contributions to contributors
    for (uint256 i = 0; i < campaigns[campaignId].totalContributions; i++) {
      address contributorAddress = contributors[campaignId][i];
      uint256 amount = contributions[campaignId][i];
      contributorAddress.transfer(amount);
    }

    // Delete the campaign
    delete campaigns[campaignId];

    return true;
  }

}