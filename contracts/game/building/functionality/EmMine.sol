// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmMine, MineType, Mine} from "../interfaces/IEmMine.sol";
import {IEmResource} from "../../../token/EmResource/interfaces/IEmResource.sol";
import {EmPipe, Building} from "./EmPipe.sol";
import {EmMineContext} from "../context/EmMineContext.sol";
import {PERCENT_PRECISION} from "../../../core/const.sol";
import {Consumer} from "../interfaces/structs.sol";

/// @dev Require EmResFactory MINTER_ROLE;
contract EmMine is EmPipe, EmMineContext, IEmMine {

    using EnumerableSet for EnumerableSet.UintSet;
    using Progression for Progression.Params;

    constructor(address buildingAddress, address techAddress) EmPipe(buildingAddress, techAddress) {
        _grantRole(CLAIMER_ROLE, _msgSender());
    }


    /// Read methods

    function getPipeOutput(address user, uint256 buildingIndex, uint8 pipeIndex) external view returns (Consumer memory consumer, address resource, uint256 amountPerSecond) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        _requireConstructed(building);
        _requirePipeExists(building, pipeIndex);
        return (_consumers[user][buildingIndex][pipeIndex], _resource[building.typeId], _getOutput(user, building));
    }

    function getTypes(uint256 offset, uint256 limit) public view returns (MineType[] memory, uint256 count) {
        count = _types.length();
        if (offset >= count || limit == 0) return (new MineType[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        MineType[] memory data = new MineType[](length);
        for (uint256 i; i < length; i++) {
            data[i] = getType(_types.at(i));
        }
        return (data, count);
    }

    function getType(uint256 typeId) public view returns (MineType memory data) {
        _requireTypeExists(typeId);
        data.typeId = typeId;
        data.resource = _resource[typeId];
        data.output = _output[typeId];
        data.volume = _volume[typeId];
        data.pipes = _pipes[typeId];
    }

    function getMine(address user, uint256 buildingIndex) public view returns (Mine memory mine) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        mine.index = buildingIndex;
        mine.typeId = building.typeId;
        mine.claimedAt = _getClaimedAt(user, building);
        mine.output = _getOutput(user, building);
        mine.volume = _getVolume(user, building);
        mine.consumers = _getConsumers(user, building);
    }

    function getMines(address user, uint256[] calldata buildingIndex) public view returns (Mine[] memory) {
        Mine[] memory mines = new Mine[](buildingIndex.length);
        for (uint256 i; i < buildingIndex.length; i++) {
            mines[i] = getMine(user, buildingIndex[i]);
        }
        return mines;
    }


    /// Write methods

    function claim(uint256 buildingIndex) public {
        address user = _msgSender();
        Building memory building = _building.getBuilding(user, buildingIndex);
        _claim(user, building);
    }


    /// Admin methods
    
    function setTypeParams(uint256 typeId, address resourceAddress, Progression.Params memory output, Progression.Params memory volume, Progression.Params memory pipes) public onlyRole(EDITOR_ROLE) {
        _types.add(typeId);
        _resource[typeId] = resourceAddress;
        _output[typeId] = output;
        _volume[typeId] = volume;
        _pipes[typeId] = pipes;
        emit TypeParamsSet(typeId, resourceAddress, output, volume, pipes);
    }

    function removeType(uint256 typeId) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        _types.remove(typeId);
        emit TypeRemoved(typeId);
    }


    /// External methods

    function claimFor(address user, uint256 buildingIndex) external onlyRole(CLAIMER_ROLE) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        _claim(user, building);
    }

    function lockPipe(address user, uint256 buildingIndex, uint8 pipeIndex, uint256 consumerIndex) public override onlyRole(CONSUMER_ROLE) {
        _claim(user, _building.getBuilding(user, buildingIndex));
        super.lockPipe(user, buildingIndex, pipeIndex, consumerIndex);
    }

    function unlockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) public override onlyRole(CONSUMER_ROLE) {
        super.unlockPipe(user, buildingIndex, pipeIndex);
        _claimedAt[user][buildingIndex] = block.timestamp;
    }


    /// Internal methods

    function _requireTypeExists(uint256 typeId) internal view {
        require(_types.contains(typeId), "Type is not exists");
    }

    function _getClaimedAt(address user, Building memory building) internal view returns (uint256) {
        uint256 claimedAt = _claimedAt[user][building.index];
        return claimedAt > building.constructedAt
            ? claimedAt
            : building.constructedAt;
    }

    function _getOutput(address user, Building memory building) internal view returns (uint256) {
        uint256 mod = _building.getSpeedMod(user, building.index, _resource[building.typeId]);
        return _output[building.typeId].get(building.level) * mod / PERCENT_PRECISION;
    }

    function _getVolume(address user, Building memory building) internal view returns (uint256) {
        uint256 mod = _building.getVolumeMod(user, building.index, _resource[building.typeId]);
        return _volume[building.typeId].get(building.level) * mod / PERCENT_PRECISION;
    }

    function _getMined(address user, Building memory building) internal view returns (uint256) {
        uint256 time = block.timestamp - _getClaimedAt(user, building);
        uint256 mined = _getOutput(user, building) * time;
        uint256 volume = _getVolume(user, building);
        return mined < volume
            ? mined
            : volume;
    }

    function _claim(address user, Building memory building) internal {
        _requireNoConsumers(user, building);
        uint256 mined = _getMined(user, building);
        IEmResource(_resource[building.typeId]).mint(user, mined);
        _claimedAt[user][building.index] = block.timestamp;
        emit Claimed(user, building.index, _resource[building.typeId], mined);
    }

}