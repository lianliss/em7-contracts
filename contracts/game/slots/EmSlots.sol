// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEmSlots, Slot} from "./interfaces/IEmSlots.sol";
import {IEmLevel} from "../level/interfaces/IEmLevel.sol";
import {Range, Parameter, ParameterMod} from "./interfaces/structs.sol";
import {Modificator} from "../lib/mod.sol";
import {PERCENT_PRECISION} from "../../core/const.sol";
import {IEmEquipmentMod} from "../../NFT/Equipment/interfaces/IEmEquipmentMod.sol";

contract EmSlots is AccessControl, IEmSlots {

    using Modificator for Modificator.Mod;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    IEmLevel private immutable _level;

    Slot[] private _slots;
    Parameter[] private _params;

    mapping(address user => mapping(uint256 paramIndex => Modificator.Mod mod)) private _mod;
    EnumerableSet.AddressSet private _nftWhitelist;

    constructor(address levelAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        _grantRole(MOD_ROLE, _msgSender());

        _level = IEmLevel(levelAddress);
        _addParameter("Research", Range.Values(PERCENT_PRECISION / 2, PERCENT_PRECISION));
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

    /// TODO Add ability to insert NFT to independent slots

    function _requireSlotExists(uint256 slotIndex) internal view {
        require(slotIndex < _slots.length, "Slot is not exists");
    }

    function _requireParamExists(uint256 paramIndex) internal view {
        require(paramIndex < _params.length, "Parameter is not exists");
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

}