// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IEmAuth} from "../../core/auth/interfaces/IEmAuth.sol";
import {IEmLevel, LevelReward} from "./interfaces/IEmLevel.sol";
import {Progression} from "../../utils/Progression.sol";
import {MemoryQueue} from "../../utils/sequence/MemoryQueue.sol";

contract EmLevel is AccessControl, IEmLevel {

    using Progression for Progression.ProgressionParams;
    using MemoryQueue for MemoryQueue.Queue;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant RAISER_ROLE = keccak256("RAISER_ROLE");

    IEmAuth private _auth;

    mapping (address user => uint256 experience) private _userExperience;
    mapping (address user => uint256 level) private _userLevel;
    mapping (address user => 
        mapping (uint256 level => 
            mapping (uint256 rewardIndex => bool isClaimed)
        )
    ) private _userRewardClaimed;
    
    Progression.ProgressionParams private _progress;
    mapping (uint256 level => LevelReward[] rewards) private _levelRewards;

    constructor(address authAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        _grantRole(RAISER_ROLE, _msgSender());

        _auth = IEmAuth(authAddress);
        /// TODO: Add start progression params
    }


    /// Read methods

    function getNextLevelExpRequirement(address user) public view returns (uint256) {
        return _getNextUserLevelExpRequirement(user);
    }

    function experienceOf(address user) public view returns (uint256) {
        return _userExperience[user];
    }

    function levelOf(address user) public view returns (uint256) {
        return _userLevel[user];
    }

    function getLevelRewards(uint256 level) public view returns (LevelReward[] memory) {
        MemoryQueue.Queue memory indexes;
        for (uint256 i; i < _levelRewards[level].length; i++) {
            if (_levelRewards[level][i].contractAddress != address(0)) {
                indexes.push(i);
            }
        }
        return _getLevelRewardsByIndexes(level, indexes.values());
    }

    function getUserLevelRewards(address user, uint256 level) public view returns (LevelReward[] memory) {
        return _getLevelRewardsByIndexes(level, _getUnclaimedLevelRewardsIndexes(user, level));
    }

    function getProgression() public view returns (Progression.ProgressionParams memory) {
        return _progress;
    }


    /// Write methods

    function claimReward(uint256 level, uint256 index) public {
        address user = _msgSender();
        _auth.banCheck(user);
        require(_userLevel[user] >= level, "User level is not reached");
        _claimReward(user, level, index);
    }

    function claimLevelRewards(uint256 level) public {
        address user = _msgSender();
        _auth.banCheck(user);
        require(_userLevel[user] >= level, "User level is not reached");
        uint256[] memory indexes = _getUnclaimedLevelRewardsIndexes(user, level);
        for (uint256 i; i < indexes.length; i++) {
            _claimReward(user, level, indexes[i]);
        }
    }


    /// Raiser methods

    function raiseExp(address user, uint256 amount) public onlyRole(RAISER_ROLE) {
        /// TODO: add multipliers implementation
        _raiseExp(user, amount);
    }

    function promoteUserLevel(address user) public onlyRole(RAISER_ROLE) {
        _raiseExp(user, _getNextUserLevelExpRequirement(user) - _userExperience[user]);
    }


    /// Admin methods

    function setProgressionParams(uint256 base, uint8 geometric, uint256 step) public onlyRole(EDITOR_ROLE) {
        _progress.base = base;
        _progress.geometric = geometric;
        _progress.step = step;
        emit ProgressionParamsSet(base, geometric, step);
    }

    function addLevelReward(uint256 level, address contractAddress, uint256 typeId, uint256 amount) public onlyRole(EDITOR_ROLE) {
        _levelRewards[level].push(LevelReward(
            contractAddress,
            typeId,
            amount
        ));
        emit LevelRewardAdded(level, contractAddress, typeId, amount);
    }

    function removeLevelReward(uint256 level, uint256 index) public onlyRole(EDITOR_ROLE) {
        _levelRewards[level][index].contractAddress = address(0);
        emit LevelRewardRemoved(level, index);
    }


    /// Internal methods
    
    function _getLevelRewardsByIndexes(uint256 level, uint256[] memory indexes) internal view returns (LevelReward[] memory) {
        LevelReward[] memory rewards = new LevelReward[](indexes.length);
        for (uint256 i; i < indexes.length; i++) {
            rewards[i] = _levelRewards[level][indexes[i]];
        }
        return rewards;
    }

    function _getUnclaimedLevelRewardsIndexes(address user, uint256 level) internal view returns (uint256[] memory) {
        MemoryQueue.Queue memory indexes;
        for (uint256 i; i < _levelRewards[level].length; i++) {
            if (
                _userRewardClaimed[user][level][i]
                && _levelRewards[level][i].contractAddress != address(0)
            ) {
                indexes.push(i);
            }
        }
        return indexes.values();
    }

    function _claimReward(address user, uint256 level, uint256 index) internal {
        require(index < _levelRewards[level].length, "Reward unreachable");
        require(!_userRewardClaimed[user][level][index], "Reward already claimed");

        LevelReward storage reward = _levelRewards[level][index];
        if (reward.typeId > 0) {
            /// TODO: Add NFT reward claim implementation
        } else {
            /// TODO: Add token reward claim implementation
        }

        _userRewardClaimed[user][level][index] = true;
        emit LevelRewardClaimed(user, level, index);
    }

    function _raiseExp(address user, uint256 amount) internal {
        _auth.banCheck(user);
        _userExperience[user] += amount;
        uint256 promotedLevels;
        while (_userExperience[user] + promotedLevels >= _progress.get(_userLevel[user] + 1)) {
            promotedLevels++;
        }
        if (promotedLevels > 0) {
            _userExperience[user] += promotedLevels;
            emit LevelPromoted(user, promotedLevels, _userExperience[user]);
        }
        emit ExperienceRaised(user, amount, _userExperience[user]);
    }

    function _getNextUserLevelExpRequirement(address user) internal view returns (uint256) {
        return _progress.get(_userLevel[user] + 1);
    }

}