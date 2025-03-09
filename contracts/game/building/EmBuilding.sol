// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EmBuildingContext} from "./context/EmBuildingContext.sol";
import {IEmSlots} from "../slots/interfaces/IEmSlots.sol";
import {IEmResource} from "../../token/EmResource/interfaces/IEmResource.sol";
import "./interfaces/IEmBuilding.sol";

contract EmBuilding is EmBuildingContext, IEmBuilding {

    constructor(address slotsAddress) EmBuildingContext(slotsAddress) {
        
    }

    function _setType(
        uint256 typeId,
        string calldata title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel
    ) internal {
        _types[typeId].title = title;
        _types[typeId].functionality = functionalityAddress;
        _types[typeId].minLevel = minLevel;
        _types[typeId].maxLevel = maxLevel;

        emit BuildingTypeSet(typeId, functionalityAddress, title, minLevel, maxLevel);
    }

    function _requireTypeExists(uint256 typeId) internal view {
        require(typeId < _typesLength, "Building type is not exists");
    }

    function addType(
        string calldata title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel
    ) public onlyRole(EDITOR_ROLE) {
        uint256 typeId = _typesLength++;
        _types[typeId].typeId = typeId;
        _setType(typeId, title, functionalityAddress, minLevel, maxLevel);
    }

    function updateType(
        uint256 typeId,
        string calldata title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel
    ) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        _setType(typeId, title, functionalityAddress, minLevel, maxLevel);
    }

    function setTypeSlots(uint256 typeId, uint256[] calldata slots) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        _types[typeId].slots = slots;
        emit BuildingTypeSlotsSet(typeId, slots);
    }

    function setBuildingRequirements(uint256 typeId, BuildRequirements calldata requirements) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        _types[typeId].construction = requirements;
        emit BuildingRequirementsSet(typeId, requirements);
    }

    function disableType(uint256 typeId) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        _types[typeId].disabled = true;
        emit BuildingTypeDisabled(typeId);
    }

    function enableType(uint256 typeId) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        _types[typeId].disabled = false;
        emit BuildingTypeEnabled(typeId);
    }

}