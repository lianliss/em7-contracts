// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IEmSlots, Slot} from "./interfaces/IEmSlots.sol";
import {IEmLevel} from "../level/interfaces/IEmLevel.sol";

contract EmSlots is AccessControl, IEmSlots {

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    IEmLevel private immutable _level;

    uint256 public length;
    mapping (uint256 slotIndex => Slot) private _slots;

    constructor(address levelAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());

        _level = IEmLevel(levelAddress);
    }

    function addSlot(string calldata title, uint256 minLevel, bool independent) public onlyRole(EDITOR_ROLE) {
        uint256 slotIndex = length++;
        _slots[slotIndex] = Slot(
            slotIndex,
            title,
            minLevel,
            false,
            independent
        );
        emit SlotAdded(slotIndex, title, minLevel, independent);
    }

    function disableSlot(uint256 slotIndex) public onlyRole(EDITOR_ROLE) {
        require(slotIndex < length, "Slot is not exists");
        _slots[slotIndex].disabled = true;
        emit SlotDisabled(slotIndex);
    }

    function enableSlot(uint256 slotIndex) public onlyRole(EDITOR_ROLE) {
        require(slotIndex < length, "Slot is not exists");
        _slots[slotIndex].disabled = false;
        emit SlotEnabled(slotIndex);
    }

    function getSlots() public view returns (Slot[] memory) {
        Slot[] memory slots = new Slot[](length);
        for (uint256 i; i < length; i++) {
            slots[i] = _slots[i];
        }
        return slots;
    }

    function userSlotAvailable(address user, uint256 slotIndex) public view returns (bool) {
        require(slotIndex < length, "Slot is not exists");
        return !_slots[slotIndex].disabled
            && _level.levelOf(user) >= _slots[slotIndex].minLevel;
    }

    /// TODO Add ability to insert NFT to independent slots

}