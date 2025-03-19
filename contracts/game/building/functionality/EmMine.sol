// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ResourceProgression} from "../../lib/structs.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmMine} from "../interfaces/IEmMine.sol";
import {IEmResource} from "../../../token/EmResource/interfaces/IEmResource.sol";
import {EmPipe, Building} from "../context/EmPipe.sol";
import {PERCENT_PRECISION} from "../../../core/const.sol";

contract EmMine is EmPipe, IEmMine {

    using Progression for Progression.Params;

    mapping (uint256 typeId => address resource) internal _resource;
    mapping (uint256 typeId => ResourceProgression amountPerSecond) internal _output;
    mapping (uint256 typeId => ResourceProgression volume) internal _volume;
    mapping (address user => mapping(uint256 buildingIndex => uint256 timestamp)) internal _claimedAt;

    constructor(address resFactoryAddress, address buildingIndex) EmPipe(buildingIndex) {

    }

    function setTypeParams(uint256 typeId, address resourceAddress, ResourceProgression memory output, ResourceProgression memory volume) public onlyRole(EDITOR_ROLE) {
        _resource[typeId] = resourceAddress;
        _output[typeId] = output;
        _volume[typeId] = volume;
        emit TypeParamsSet(typeId, resourceAddress, output, volume);
    }

    function _getClaimedAt(address user, Building memory building) internal view returns (uint256) {
        uint256 claimedAt = _claimedAt[user][building.index];
        return claimedAt > building.constructedAt
            ? claimedAt
            : building.constructedAt;
    }

    function _getOutput(address user, Building memory building) internal view returns (uint256) {
        uint256 mod = _building.getSpeedMod(user, building.index, _output[building.typeId].resource);
        return _output[building.typeId].amount.get(building.level) * mod / PERCENT_PRECISION;
    }

    function _getVolume(address user, Building memory building) internal view returns (uint256) {
        uint256 mod = _building.getVolumeMod(user, building.index, _output[building.typeId].resource);
        return _volume[building.typeId].amount.get(building.level) * mod / PERCENT_PRECISION;
    }

    function _getMined(address user, Building memory building) internal view returns (uint256) {
        uint256 time = block.timestamp - _getClaimedAt(user, building);
        uint256 mined = _getOutput(user, building) * time;
        uint256 volume = _getVolume(user, building);
        return mined < volume
            ? mined
            : volume;
    }

    function getPipeOutput(address user, uint256 buildingIndex, uint8 pipeIndex) external view returns (address consumer, address resource, uint256 amountPerSecond) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        _requireConstructed(building);
        _requirePipeExists(building, pipeIndex);
        return (_consumers[user][buildingIndex][pipeIndex], _resource[building.typeId], _getOutput(user, building));
    }

    function _claim(address user, Building memory building) internal {
        _requireNoConsumers(user, building);
        uint256 mined = _getMined(user, building);
        IEmResource(_resource[building.typeId]).mint(user, mined);
        _claimedAt[user][building.index] = block.timestamp;
        emit Claimed(user, building.index, _resource[building.typeId], mined);
    }

    function claim(uint256 buildingIndex) public {
        address user = _msgSender();
        Building memory building = _building.getBuilding(user, buildingIndex);
        _claim(user, building);
    }

    function lockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) public override onlyRole(CONSUMER_ROLE) {
        _claim(user, _building.getBuilding(user, buildingIndex));
        super.lockPipe(user, buildingIndex, pipeIndex);
    }

    function unlockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) public override onlyRole(CONSUMER_ROLE) {
        super.unlockPipe(user, buildingIndex, pipeIndex);
        _claimedAt[user][buildingIndex] = block.timestamp;
    }

}