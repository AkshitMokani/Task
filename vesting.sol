// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TokenVesting 
{
    struct VestingSchedule 
    {
        uint256 totalTokens;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 releasedTokens;
        bool isActive;
    }

    mapping(address => VestingSchedule) public vestingSchedules;
    mapping(address => uint256) public vestedTokens;

    address public tokenAddress;

    event TokensReleased(address beneficiary, uint256 amount);

    constructor(address _tokenAddress)
    {
        require(_tokenAddress != address(0), "Invalid token address");
        tokenAddress = _tokenAddress;
    }

    function createVestingSchedule(address _beneficiary,uint256 _totalTokens,uint256 _startTime,uint256 _cliffDuration,uint256 _vestingDuration) public 
    {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(vestingSchedules[_beneficiary].startTime == 0, "Vesting schedule already exists");

        VestingSchedule storage vestingSchedule = vestingSchedules[_beneficiary];
        vestingSchedule.totalTokens = _totalTokens;
        vestingSchedule.startTime = _startTime;
        vestingSchedule.cliffDuration = _cliffDuration;
        vestingSchedule.vestingDuration = _vestingDuration;
        vestingSchedule.releasedTokens = 0;
        vestingSchedule.isActive = true;
    }

    function releaseTokens(address _beneficiary) public {
        VestingSchedule storage vestingSchedule = vestingSchedules[_beneficiary];
        require(vestingSchedule.isActive, "Vesting schedule not found");
        require(vestedTokens[_beneficiary] == 0, "Tokens already released");

        uint256 vestedAmount = calculateVestedAmount(_beneficiary);
        require(vestedAmount > 0, "No tokens available for release");

        vestedTokens[_beneficiary] = vestedAmount;
        IToken(tokenAddress).transfer(_beneficiary, vestedAmount);
        vestingSchedule.releasedTokens = vestedAmount;

        emit TokensReleased(_beneficiary, vestedAmount);
    }

    function calculateVestedAmount(address _beneficiary) public view returns (uint256) {
        VestingSchedule storage vestingSchedule = vestingSchedules[_beneficiary];
        require(vestingSchedule.isActive, "Vesting schedule not found");

        if (block.timestamp < vestingSchedule.startTime + vestingSchedule.cliffDuration) {
            // Before cliff duration, no tokens are vested
            return 0;
        } else if (block.timestamp >= vestingSchedule.startTime + vestingSchedule.vestingDuration) {
            // After vesting duration, all tokens are vested
            return vestingSchedule.totalTokens;
        } else {
            // During the vesting period, calculate the vested amount proportionally
            uint256 elapsedTime = block.timestamp - vestingSchedule.startTime;
            uint256 vestingPeriod = vestingSchedule.vestingDuration - vestingSchedule.cliffDuration;
            uint256 vestedAmount = (vestingSchedule.totalTokens * elapsedTime) / vestingPeriod;
            return vestedAmount;
        }
    }
}

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
}
