// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Slot, Range, Parameter, ParameterMod} from "./structs.sol";

interface IEmSlots {

    event SlotAdded(uint256 slotIndex, string title, uint256 minLevel, bool independent);
    event SlotUpdated(uint256 slotIndex, string title, uint256 minLevel);
    event SlotDisabled(uint256 slotIndex);
    event SlotEnabled(uint256 slotIndex);

    event ParameterAdded(uint256 paramIndex, string title, Range.Values limits);
    event ParameterUpdated(uint256 paramIndex, string title, Range.Values limits);
    event NFTWhitelisted(address nftAddress);
    event NFTBlacklisted(address nftAddress);

    function getSlots(uint256 offset, uint256 limit) external view returns (Slot[] memory, uint256 count);
    function getParams(uint256 offset, uint256 limit) external view returns (Parameter[] memory, uint256 count);
    function userSlotAvailable(address user, uint256 slotIndex) external view returns (bool);

    function addSlot(string calldata title, uint256 minLevel, bool independent) external;
    function disableSlot(uint256 slotIndex) external;
    function enableSlot(uint256 slotIndex) external;

    function addParameter(string calldata title, Range.Values calldata limits) external;

    function getMod(address user, uint256 paramIndex) external view returns (uint256);
    function getMods(address user, uint256 offset, uint256 limit) external view returns (ParameterMod[] memory, uint256 count);

}