// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVesting {
    mapping(address => uint256) public vestedTokens;
    address public tokenAddress;

    event TokensReleased(address beneficiary, uint256 amount);

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Invalid token address");
        tokenAddress = _tokenAddress;
    }

    function createVestingSchedule(address _beneficiary, uint256 _totalTokens) public {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(vestedTokens[_beneficiary] == 0, "Vesting schedule already exists");

        vestedTokens[_beneficiary] = _totalTokens;
    }

    function releaseTokens(address _beneficiary) public {
        uint256 vestedAmount = vestedTokens[_beneficiary];
        require(vestedAmount > 0, "No tokens available for release");

        vestedTokens[_beneficiary] = 0;
        IToken(tokenAddress).transfer(_beneficiary, vestedAmount);

        emit TokensReleased(_beneficiary, vestedAmount);
    }
}

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
}
