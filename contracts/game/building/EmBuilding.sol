// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EmBuildingContext, Modificator, Item} from "./context/EmBuildingContext.sol";
import {IEmSlots} from "../slots/interfaces/IEmSlots.sol";
import {IEmResource} from "../../token/EmResource/interfaces/IEmResource.sol";
import {IEmEquipment, ResourceMod} from "../../NFT/Equipment/interfaces/IEmEquipment.sol";
import {IEmClaimer} from "./interfaces/IEmClaimer.sol";
import {DEMOLISH_PARAM_ID} from "../const.sol";
import {PERCENT_PRECISION} from "../../core/const.sol";
import "./interfaces/IEmBuilding.sol";

/// @notice Upgradable building with a slots;
/// @dev Require EmMap BUILDER_ROLE;
/// @dev Require EmEquipment MOD_ROLE;
/// @dev Require EmResFactory MINTER_ROLE;
/// @dev Require EmResFactory BURNER_ROLE;
/// @dev Require each functionality CLAIMER_ROLE;
contract EmBuilding is EmBuildingContext, IEmBuilding {

    using Modificator for Modificator.Mod;
    using EnumerableSet for EnumerableSet.UintSet;
    using Progression for Progression.Params;

    constructor(
        address techAddress,
        address mapAddress,
        address slotsAddress
    ) EmBuildingContext(techAddress, mapAddress, slotsAddress) {}


    /// Read methods

    /// @notice Returns buildings types;
    /// @param offset Offset from the beginning;
    /// @param limit Return array length limit;
    /// @return Array of buildings types;
    /// @return count Total amount of buildings types;
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

    /// @notice Returns buildings types;
    /// @param user Account address;
    /// @param offset Offset from the beginning;
    /// @param limit Return array length limit;
    /// @return Array of user buildings;
    /// @return count Total amount of user buildings;
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

    /// @notice Returns user single building;
    /// @param user Account address;
    /// @param buildingIndex Building index;
    /// @return Building data;
    function getBuilding(address user, uint256 buildingIndex) public view returns (Building memory) {
        return _building[user][buildingIndex];
    }
    

    /// Write methods

    /// @notice Build a building in the coordinates;
    /// @param typeId Building type index;
    /// @param x Horizontal coordinate;
    /// @param y Vertical ccordinate;
    function build(uint256 typeId, uint256 x, uint256 y) public {
        _requireType(typeId);
        address user = _msgSender();
        _burnResources(user, typeId, 0);
        _build(user, typeId, x, y);
    }

    /// @notice Upgrades the building;
    /// @param buildingIndex Building index;
    function upgrade(uint256 buildingIndex) public {
        address user = _msgSender();
        _requireBuildingExists(user, buildingIndex);
        Building storage building = _building[user][buildingIndex];
        _burnResources(user, building.typeId, building.level + 1);
        _upgrade(user, buildingIndex);
    }

    /// @notice Removes the building;
    /// @param buildingIndex Building index;
    function remove(uint256 buildingIndex) public {
        _remove(_msgSender(), buildingIndex);
    }

    /// @notice Equipes an NFT to a building slot;
    /// @param tokenAddress NFT address;
    /// @param tokenId NFT identificator;
    /// @param buildingIndex Building index with available slot;
    /// @param slotId Slot index of the building;
    /// @dev It will try to claim resources before the equip;
    function equip(address tokenAddress, uint256 tokenId, uint256 buildingIndex, uint256 slotId) public {
        _equip(_msgSender(), tokenAddress, tokenId, buildingIndex, slotId);
    }

    /// @notice Unequips the NFT from the building slot;
    /// @param buildingIndex Building index;
    /// @param slotId Slot index of the building;
    /// @dev It will try to claim resources before the unequip;
    function unequip(uint256 buildingIndex, uint256 slotId) public {
        _unequip(_msgSender(), buildingIndex, slotId);
    }


    /// External methods

    /// @notice Build a building for user
    /// @param input Encoded data with user address, coordinates and building type index in bytes encoded extra data;
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

    /// @notice Finishes the construction in the building;
    /// @param input Encoded data with user address, coordinates;
    function finishConstructionFor(bytes calldata input) external onlyRole(MOD_ROLE) {
        (address user, uint256 x, uint256 y,) = abi.decode(input, (address, uint256, uint256, bytes));
        uint256 buildingIndex = _map.getTileBuilding(user, x, y);
        require(_building[user][buildingIndex].constructedAt < block.timestamp, "Building already constructed");
        _building[user][buildingIndex].constructedAt = 1;
    }

    /// @notice Returns mining speed modificator of the building;
    /// @param user Account address;
    /// @param buildingIndex Building index;
    /// @param resource Resource address;
    /// @return Resource mining speed modificator;
    function getSpeedMod(address user, uint256 buildingIndex, address resource) public view returns (uint256) {
        return _speedMod[user][buildingIndex][resource].get();
    }

    /// @notice Returns storage volume modificator of the building;
    /// @param user Account address;
    /// @param buildingIndex Building index;
    /// @param resource Resource address;
    /// @return Resource storage volume modificator;
    function getVolumeMod(address user, uint256 buildingIndex, address resource) public view returns (uint256) {
        return _volumeMod[user][buildingIndex][resource].get();
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
        _applyBuildingBorderingMods(user, index);
    }

    function _upgrade(address user, uint256 buildingIndex) internal {
        _requireBuildingExists(user, buildingIndex);
        Building storage building = _building[user][buildingIndex];
        BuildingType storage buildType = _types[building.typeId];
        require(building.level < buildType.maxLevel, "Maximum building level reached");
        _requireTech(user, building.typeId, building.level + 1);
        _claimBuilding(user, buildingIndex);
        building.level++;
        building.constructedAt = block.timestamp + buildType.construction.time.get(building.level);
        emit BuildingUpgraded(user, building);
    }

    function _remove(address user, uint256 buildingIndex) internal {
        _requireBuildingExists(user, buildingIndex);
        _requireSlotsReleased(user, buildingIndex);
        Building storage building = _building[user][buildingIndex];
        BuildingType storage buildType = _types[building.typeId];
        /// Claim
        _claimBuilding(user, buildingIndex);
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
            amount = amount * _slots.getMod(user, DEMOLISH_PARAM_ID) / PERCENT_PRECISION;
            IEmResource(res[r].resource).mint(user, amount);
        }
        /// Remove from map
        _map.removeObject(user, buildingIndex);
        /// Remove record
        _indexes[user].remove(buildingIndex);
        delete _building[user][buildingIndex];
        emit BuildingRemoved(user, buildingIndex);
    }

    function _getSourceId(address tokenAddress, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encode(tokenAddress, tokenId));
    }

    function _requireOwnership(address user, address tokenAddress, uint256 tokenId) internal view {
        IEmEquipment token = IEmEquipment(tokenAddress);
        require(token.ownerOf(tokenId) == user, "Wrong token owner");
    }

    function _requireSlotsReleased(address user, uint256 buildingIndex) internal view {
        uint256 typeId = _building[user][buildingIndex].typeId;
        uint256[] memory slots = _types[typeId].slots;
        for (uint256 i; i < slots.length; i++) {
            if (_items[user][buildingIndex][slots[i]].tokenAddress != address(0)) {
                revert("Building slots are not released");
            }
        }
    }

    function _setSpeedMod(address user, uint256 buildingIndex, address resource, bytes32 sourceId, uint256 value) internal {
        _speedMod[user][buildingIndex][resource].add(sourceId, value);
    }

    function _setVolumeMod(address user, uint256 buildingIndex, address resource, bytes32 sourceId, uint256 value) internal {
        _volumeMod[user][buildingIndex][resource].add(sourceId, value);
    }

    function _removeSpeedMod(address user, uint256 buildingIndex, address resource, bytes32 sourceId) internal {
        _speedMod[user][buildingIndex][resource].remove(sourceId);
    }

    function _removeVolumeMod(address user, uint256 buildingIndex, address resource, bytes32 sourceId) internal {
        _volumeMod[user][buildingIndex][resource].remove(sourceId);
    }

    function _claimBuilding(address user, uint256 buildingIndex) internal {
        uint256 typeId = _building[user][buildingIndex].typeId;
        try IEmClaimer(_types[typeId].functionality).claimFor(user, buildingIndex) {} catch {}
    }

    function _applyBuildingParams(address user, uint256 buildingIndex, bytes32 sourceId, ResourceMod[] memory params) internal {
        _claimBuilding(user, buildingIndex);
        for (uint256 i; i < params.length; i++) {
            if (params[i].isVolume) {
                _setVolumeMod(user, buildingIndex, params[i].resource, sourceId, params[i].mod);
            } else {
                _setSpeedMod(user, buildingIndex, params[i].resource, sourceId, params[i].mod);
            }
        }
    }

    function _retractBuildingParams(address user, uint256 buildingIndex, bytes32 sourceId, ResourceMod[] memory params) internal {
        _claimBuilding(user, buildingIndex);
        for (uint256 i; i < params.length; i++) {
            if (params[i].isVolume) {
                _removeVolumeMod(user, buildingIndex, params[i].resource, sourceId);
            } else {
                _removeSpeedMod(user, buildingIndex, params[i].resource, sourceId);
            }
        }
    }

    function _applyBuildingBorderingMods(address user, uint256 buildingIndex) internal {
        uint256[] memory buildings = _map.getBorderingBuildings(user, buildingIndex);
        for (uint256 b; b < buildings.length; b++) {
            uint256 typeId = _building[user][buildingIndex].typeId;
            uint256[] memory slots = _types[typeId].slots;
            for (uint256 i; i < slots.length; i++) {
                Item storage item = _items[user][buildingIndex][slots[i]];
                if (item.tokenAddress != address(0)) {
                    IEmEquipment token = IEmEquipment(item.tokenAddress);
                    bytes32 sourceId = _getSourceId(item.tokenAddress, item.tokenId);
                    ResourceMod[] memory params = token.getBorderingMods(item.tokenId);
                    _applyBuildingParams(user, buildingIndex, sourceId, params);
                }
            }
        }
    }

    function _equip(address user, address tokenAddress, uint256 tokenId, uint256 buildingIndex, uint256 slotId) internal {
        _requireOwnership(user, tokenAddress, tokenId);
        Item storage item = _items[user][buildingIndex][slotId];
        if (item.tokenAddress != address(0)) {
            revert SlotOccupiedError(item.tokenAddress, item.tokenId);
        }

        IEmEquipment token = IEmEquipment(tokenAddress);
        bytes32 sourceId = _getSourceId(tokenAddress, tokenId);
        /// Lock token in slot
        token.lock(tokenId);
        /// Apply params mods
        {
            ResourceMod[] memory params = token.getBuildingMods(tokenId);
            _applyBuildingParams(user, buildingIndex, sourceId, params);
        }
        /// Apply mods to bordering buildings
        {
            ResourceMod[] memory params = token.getBorderingMods(tokenId);
            uint256[] memory buildings = _map.getBorderingBuildings(user, buildingIndex);
            for (uint256 i; i < buildings.length; i++) {
                _applyBuildingParams(user, buildings[i], sourceId, params);
            }
        }
        /// Set slot oppupied
        item.tokenAddress = tokenAddress;
        item.tokenId = tokenId;
        emit ItemEquiped(user, tokenAddress, tokenId, buildingIndex, slotId);
    }

    function _unequip(address user, uint256 buildingIndex, uint256 slotId) internal {
        Item storage item = _items[user][buildingIndex][slotId];
        require(item.tokenAddress != address(0), "Slot is empty");

        IEmEquipment token = IEmEquipment(item.tokenAddress);
        bytes32 sourceId = _getSourceId(item.tokenAddress, item.tokenId);
        /// Unlock token
        token.unlock(item.tokenId);
        /// Retract params mods
        {
            ResourceMod[] memory params = token.getBuildingMods(item.tokenId);
            _retractBuildingParams(user, buildingIndex, sourceId, params);
        }
        /// Retract mods to bordering buildings
        {
            ResourceMod[] memory params = token.getBorderingMods(item.tokenId);
            uint256[] memory buildings = _map.getBorderingBuildings(user, buildingIndex);
            for (uint256 i; i < buildings.length; i++) {
                _retractBuildingParams(user, buildings[i], sourceId, params);
            }
        }
        emit ItemUnequiped(user, item.tokenAddress, item.tokenId, buildingIndex, slotId);
        /// Release slot
        delete _items[user][buildingIndex][slotId];
    }

}