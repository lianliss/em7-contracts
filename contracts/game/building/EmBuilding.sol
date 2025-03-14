// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EmBuildingContext} from "./context/EmBuildingContext.sol";
import {IEmSlots} from "../slots/interfaces/IEmSlots.sol";
import {IEmResource} from "../../token/EmResource/interfaces/IEmResource.sol";
import "./interfaces/IEmBuilding.sol";

contract EmBuilding is EmBuildingContext, IEmBuilding {

    using EnumerableSet for EnumerableSet.UintSet;
    using Progression for Progression.Params;

    constructor(
        address slotsAddress,
        address techAddress,
        address mapAddress
    ) EmBuildingContext(slotsAddress, techAddress, mapAddress) {}


    /// Read methods

    function getTypes(uint256 offset, uint256 limit) public view returns (BuildingType[] memory, uint256 count) {
        if (offset >= _typesLength || limit == 0) return (new BuildingType[](0), _typesLength);
        uint256 length = _typesLength - offset;
        if (limit < length) length = limit;
        BuildingType[] memory data = new BuildingType[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _types[offset + i];
        }
        return (data, _typesLength);
    }

    function getBuildings(address user, uint256 offset, uint256 limit) public view returns (Building[] memory, uint256 count) {
        count = _indexes[user].length();
        if (offset >= count || limit == 0) return (new Building[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Building[] memory data = new Building[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _building[user][_indexes[user].at(offset + i)];
        }
        return (data, count);
    }

    /// Write methods

    function build(uint256 typeId, uint256 x, uint256 y) public {
        _requireType(typeId);
        address user = _msgSender();
        _burnResources(user, typeId, 0);
        _build(user, typeId, x, y);
    }

    function upgrade(uint256 buildingIndex) public {
        address user = _msgSender();
        _requireBuildingExists(user, buildingIndex);
        Building storage building = _building[user][buildingIndex];
        _burnResources(user, building.typeId, building.level + 1);
        _upgrade(user, buildingIndex);
    }

    function remove(uint256 buildingIndex) public {
        _remove(_msgSender(), buildingIndex);
    }


    /// Editor methods

    function setReturnDevider(uint256 devider) public onlyRole(EDITOR_ROLE) {
        require(devider > 0, "Devider can't be zero");
        _returnDevider = devider;
        emit ReturnDeviderSet(devider);
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


    /// External methods

    function buildFor(bytes calldata input) external onlyRole(MOD_ROLE) {
        (address user, uint256 x, uint256 y, bytes memory extra) = abi.decode(input, (address, uint256, uint256, bytes));
        uint256 buildingIndex = _map.getTileBuilding(user, x, y);
        if (buildingIndex > 0 && _map.getBuildingObject(user, buildingIndex).size > 0) {
            /// Upgrade existing object
            _requireBuildingExists(user, buildingIndex);
            _upgrade(user, buildingIndex);
        } else {
            /// Build a new building
            (uint256 typeId) = abi.decode(extra, (uint256));
            _requireType(typeId);
            _build(user, typeId, x, y);
        }
    }


    /// Internal methods

    function _requireTypeExists(uint256 typeId) internal view {
        require(typeId < _typesLength, "Building type is not exists");
    }

    function _requireType(uint256 typeId) internal view {
        require(typeId < _typesLength && !_types[typeId].disabled, "Unknown building type");
    }

    function _requireBuildingExists(address user, uint256 buildingIndex) internal view {
        require(_indexes[user].contains(buildingIndex), "Building is not exists");
    }

    function _requireTech(address user, uint256 typeId, uint256 level) internal view {
        if (_types[typeId].construction.levelTech.length > level) {
            uint256 techIndex = _types[typeId].construction.levelTech[level];
            if (!_tech.haveTech(user, techIndex)) {
                revert TechNotResearched(techIndex);
            }
        }
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

    function _burnResources(address user, uint256 typeId, uint256 level) internal {
        ResourceProgression[] storage res = _types[typeId].construction.resources;
        for (uint256 r; r < res.length; r++) {
            IEmResource(res[r].resource).burn(user, res[r].amount.get(level));
        }
    }
    
    function _build(address user, uint256 typeId, uint256 x, uint256 y) internal {
        _requireType(typeId);
        _requireTech(user, typeId, 0);
        /// Check count limit
        uint256 countLimit = _types[typeId].countLimit;
        if (countLimit > 0 && _count[user][typeId] >= countLimit) {
            revert BuildingTypeCountLimit(countLimit);
        }
        _count[user][typeId]++;
        /// Add to the map
        uint256 index = ++_counter[user];
        _map.setObject(user, x, y, _types[typeId].size, index);
        /// Add record
        _indexes[user].add(index);
        _building[user][index] = Building(
            index,
            typeId,
            0,
            block.timestamp + _types[typeId].construction.time.get(0)
        );
        emit BuildingPlaced(user, _building[user][index]);
        /// TODO insert bordering mods
    }

    function _upgrade(address user, uint256 buildingIndex) internal {
        _requireBuildingExists(user, buildingIndex);
        Building storage building = _building[user][buildingIndex];
        BuildingType storage buildType = _types[building.typeId];
        require(building.level < buildType.maxLevel, "Maximum building level reached");
        _requireTech(user, building.typeId, building.level + 1);
        building.level++;
        building.constructedAt = block.timestamp + buildType.construction.time.get(building.level);
        emit BuildingUpgraded(user, building);
    }

    function _remove(address user, uint256 buildingIndex) internal {
        _requireBuildingExists(user, buildingIndex);
        Building storage building = _building[user][buildingIndex];
        BuildingType storage buildType = _types[building.typeId];
        /// Return resources
        ResourceProgression[] storage res = buildType.construction.resources;
        uint256[] memory toReturn = new uint256[](res.length);
        for (uint256 l; l <= building.level; l++) {
            for (uint256 r; r < res.length; r++) {
                toReturn[r] += res[r].amount.get(l);
            }
        }
        for (uint256 r; r < res.length; r++) {
            uint256 amount = toReturn[r] / _returnDevider;
            /// TODO add mod
            IEmResource(res[r].resource).mint(user, amount);
        }
        /// Remove from map
        _map.removeObject(user, buildingIndex);
        /// Remove record
        _indexes[user].remove(buildingIndex);
        delete _building[user][buildingIndex];
        emit BuildingRemoved(user, buildingIndex);
        /// TODO remove bordering mods
    }

}