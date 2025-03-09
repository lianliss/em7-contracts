// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct Slot {
    uint256 slotIndex;
    string title;
    uint256 minLevel;
    bool disabled;
    bool independent;
}

interface IEmSlots {

    event SlotAdded(uint256 slotIndex, string title, uint256 minLevel, bool independent);
    event SlotDisabled(uint256 slotIndex);
    event SlotEnabled(uint256 slotIndex);

    function getSlots() external view returns (Slot[] memory);
    function userSlotAvailable(address user, uint256 slotIndex) external view returns (bool);

    function addSlot(string calldata title, uint256 minLevel, bool independent) external;
    function disableSlot(uint256 slotIndex) external;
    function enableSlot(uint256 slotIndex) external;

}