// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Progression} from "../../../utils/Progression.sol";

struct LevelReward {
    address contractAddress;
    uint256 typeId;
    uint256 amount;
}

interface IEmLevel {

    event ProgressionParamsSet(uint256 base, uint8 geometric, uint256 step);
    event LevelRewardAdded(uint256 level, address contractAddress, uint256 typeId, uint256 amount);
    event LevelRewardRemoved(uint256 level, uint256 index);
    event LevelRewardClaimed(address indexed user, uint256 level, uint256 index);
    event LevelPromoted(address indexed user, uint256 levels, uint256 currentLevel);
    event ExperienceRaised(address indexed user, uint256 amount, uint256 currentExperience);

    function getNextLevelExpRequirement(address user) external view returns (uint256);
    function experienceOf(address user) external view returns (uint256);
    function levelOf(address user) external view returns (uint256);
    function getLevelRewards(uint256 level) external view returns (LevelReward[] memory);
    function getUserLevelRewards(address user, uint256 level) external view returns (LevelReward[] memory);
    function getProgression() external view returns (Progression.ProgressionParams memory);
    function claimReward(uint256 level, uint256 index) external;
    function claimLevelRewards(uint256 level) external;
    function raiseExp(address user, uint256 amount) external;
    function promoteUserLevel(address user) external;
    function setProgressionParams(uint256 base, uint8 geometric, uint256 step) external;
    function addLevelReward(uint256 level, address contractAddress, uint256 typeId, uint256 amount) external;
    function removeLevelReward(uint256 level, uint256 index) external;

}