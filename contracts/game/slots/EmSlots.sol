// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEmSlots, Slot, Item} from "./interfaces/IEmSlots.sol";
import {IEmLevel} from "../level/interfaces/IEmLevel.sol";
import {Range, Parameter, ParameterMod} from "./interfaces/structs.sol";
import {Modificator} from "../lib/mod.sol";
import {PERCENT_PRECISION} from "../../core/const.sol";
import {IEmEquipment, UserMod} from "../../NFT/Equipment/interfaces/IEmEquipment.sol";

contract EmSlots is AccessControl, IEmSlots {

    using Modificator for Modificator.Mod;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    IEmLevel private immutable _level;

    Slot[] private _slots;
    Parameter[] private _params;

    mapping(address user => mapping(uint256 paramIndex => Modificator.Mod mod)) private _mod;
    mapping(address user => mapping(uint256 slotId => Item item)) private _items;
    EnumerableSet.AddressSet private _nftWhitelist;

    constructor(address levelAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        _grantRole(MOD_ROLE, _msgSender());
        _grantRole(EMERGENCY_ROLE, _msgSender());

        _level = IEmLevel(levelAddress);
        _addParameter("Research", Range.Values(PERCENT_PRECISION / 2, PERCENT_PRECISION));
        _addParameter("Demolish return", Range.Values(PERCENT_PRECISION, PERCENT_PRECISION * 2));
    }

    function addSlot(string calldata title, uint256 minLevel, bool independent) public onlyRole(EDITOR_ROLE) {
        _slots.push(Slot(
            _slots.length,
            title,
            minLevel,
            false,
            independent
        ));
        emit SlotAdded(_slots.length - 1, title, minLevel, independent);
    }

    function updateSlot(uint256 slotIndex, string calldata title, uint256 minLevel) public onlyRole(EDITOR_ROLE) {
        _requireSlotExists(slotIndex);
        _slots[slotIndex].title = title;
        _slots[slotIndex].minLevel = minLevel;
        emit SlotUpdated(slotIndex, title, minLevel);
    }

    function disableSlot(uint256 slotIndex) public onlyRole(EDITOR_ROLE) {
        _requireSlotExists(slotIndex);
        _slots[slotIndex].disabled = true;
        emit SlotDisabled(slotIndex);
    }

    function enableSlot(uint256 slotIndex) public onlyRole(EDITOR_ROLE) {
        _requireSlotExists(slotIndex);
        _slots[slotIndex].disabled = false;
        emit SlotEnabled(slotIndex);
    }

    function addParameter(string calldata title, Range.Values calldata limits) public onlyRole(EDITOR_ROLE) {
        _addParameter(title, limits);
    }

    function updateParameter(uint256 paramIndex, string calldata title, Range.Values calldata limits) public onlyRole(EDITOR_ROLE) {
        _params[paramIndex].title = title;
        _params[paramIndex].limits = limits;
        emit ParameterUpdated(paramIndex, title, limits);
    }

    function addNft(address nftAddress) public onlyRole(EDITOR_ROLE) {
        _nftWhitelist.add(nftAddress);
        emit NFTWhitelisted(nftAddress);
    }

    function removeNft(address nftAddress) public onlyRole(EDITOR_ROLE) {
        _nftWhitelist.remove(nftAddress);
        emit NFTBlacklisted(nftAddress);
    }

    function getSlots(uint256 offset, uint256 limit) public view returns (Slot[] memory, uint256 count) {
        count = _slots.length;
        if (offset >= count || limit == 0) return (new Slot[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Slot[] memory data = new Slot[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _slots[i];
        }
        return (data, count);
    }

    function getParams(uint256 offset, uint256 limit) public view returns (Parameter[] memory, uint256 count) {
        count = _params.length;
        if (offset >= count || limit == 0) return (new Parameter[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Parameter[] memory data = new Parameter[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _params[i];
        }
        return (data, count);
    }

    function getItems(address user, uint256 offset, uint256 limit) public view returns (Item[] memory, uint256 count) {
        count = _slots.length;
        if (offset >= count || limit == 0) return (new Item[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Item[] memory data = new Item[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _items[user][i];
        }
        return (data, count);
    }

    function userSlotAvailable(address user, uint256 slotIndex) public view returns (bool) {
        _requireSlotExists(slotIndex);
        return !_slots[slotIndex].disabled
            && _level.levelOf(user) >= _slots[slotIndex].minLevel;
    }

    function getMod(address user, uint256 paramIndex) public view returns (uint256) {
        return paramIndex < _params.length
            ? _mod[user][paramIndex].get(_params[paramIndex].limits)
            : PERCENT_PRECISION;
    }

    function getMods(address user, uint256 offset, uint256 limit) public view returns (ParameterMod[] memory, uint256 count) {
        count = _params.length;
        if (offset >= count || limit == 0) return (new ParameterMod[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        ParameterMod[] memory data = new ParameterMod[](length);
        for (uint256 i; i < length; i++) {
            data[i] = ParameterMod(
                i,
                _params[i].title,
                getMod(user, i)
            );
        }
        return (data, count);
    }

    function equip(address tokenAddress, uint256 tokenId, uint256 slotId) public {
        _equip(_msgSender(), tokenAddress, tokenId, slotId);
    }

    function unequip(uint256 slotId) public {
        _unequip(_msgSender(), slotId);
    }

    function unequipFor(address user, uint256 slotId) public onlyRole(EMERGENCY_ROLE) {
        _unequip(user, slotId);
    }

    function _requireSlotExists(uint256 slotIndex) internal view {
        require(slotIndex < _slots.length, "Slot is not exists");
    }

    function _requireParamExists(uint256 paramIndex) internal view {
        if (paramIndex > _params.length) {
            revert ParamNotExistsError(paramIndex);
        }
    }

    function _addParameter(string memory title, Range.Values memory limits) internal returns (uint256 paramIndex) {
        paramIndex = _params.length;
        _params.push(Parameter(
            paramIndex,
            title,
            limits
        ));
        emit ParameterAdded(paramIndex, title, limits);
        return paramIndex;
    }

    function _setMod(address user, uint256 paramIndex, bytes32 sourceId, uint256 value) internal {
        _mod[user][paramIndex].add(sourceId, value);
    }

    function _removeMod(address user, uint256 paramIndex, bytes32 sourceId) internal {
        _mod[user][paramIndex].remove(sourceId);
    }

    function _getSourceId(address tokenAddress, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encode(tokenAddress, tokenId));
    }

    function _requireOwnership(address user, address tokenAddress, uint256 tokenId) internal view {
        IEmEquipment token = IEmEquipment(tokenAddress);
        require(token.ownerOf(tokenId) == user, "Wrong token owner");
    }

    function _equip(address user, address tokenAddress, uint256 tokenId, uint256 slotId) internal {
        _requireOwnership(user, tokenAddress, tokenId);
        if (_items[user][slotId].tokenAddress != address(0)) {
            revert SlotOccupiedError(_items[user][slotId].tokenAddress, _items[user][slotId].tokenId);
        }

        IEmEquipment token = IEmEquipment(tokenAddress);
        /// Lock token in slot
        token.lock(tokenId);
        /// Apply params mods
        bytes32 sourceId = _getSourceId(tokenAddress, tokenId);
        UserMod[] memory params = token.getUserMods(tokenId);
        for (uint256 i; i < params.length; i++) {
            _requireParamExists(params[i].paramIndex);
            _setMod(user, params[i].paramIndex, sourceId, params[i].mod);
        }
        /// Set slot oppupied
        _items[user][slotId].tokenAddress = tokenAddress;
        _items[user][slotId].tokenId = tokenId;
        emit ItemEquiped(user, tokenAddress, tokenId, slotId, params);
    }

    function _unequip(address user, uint256 slotId) internal {
        address tokenAddress = _items[user][slotId].tokenAddress;
        uint256 tokenId = _items[user][slotId].tokenId;
        require(tokenAddress != address(0), "Slot is empty");

        IEmEquipment token = IEmEquipment(tokenAddress);
        /// Unlock token
        token.unlock(tokenId);
        /// Retract params mods
        bytes32 sourceId = _getSourceId(tokenAddress, tokenId);
        UserMod[] memory params = token.getUserMods(tokenId);
        for (uint256 i; i < params.length; i++) {
            _requireParamExists(params[i].paramIndex);
            _removeMod(user, params[i].paramIndex, sourceId);
        }
        /// Release slot
        delete _items[user][slotId];
        emit ItemUnequiped(user, tokenAddress, tokenId, slotId, params);
    }

}