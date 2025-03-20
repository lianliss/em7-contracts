// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Proxy} from "../../../Proxy/Proxy.sol";
import {IEmTech} from "../../tech/interfaces/IEmTech.sol";
import {IEmSlots} from "../../slots/interfaces/IEmSlots.sol";
import {IEmMapExternal} from "../../map/interfaces/IEmMapExternal.sol";
import {BuildingType, Building} from "../interfaces/IEmBuilding.sol";
import {Modificator} from "../../lib/mod.sol";
import {Item} from "../../slots/interfaces/structs.sol";

abstract contract EmBuildingContext is Proxy {

    bytes32 internal constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 internal constant MOD_ROLE = keccak256("MOD_ROLE");

    IEmTech internal immutable _tech;
    IEmMapExternal internal immutable _map;
    IEmSlots internal immutable _slots;

    /// Devider for resources amount to return on demolish
    uint256 internal _returnDevider = 2;

    /// Building types counter
    uint256 internal _typesLength;
    /// Building types
    mapping(uint256 typeId => BuildingType) internal _types;
    /// User building data
    mapping(address user => mapping(uint256 buildingIndex => Building)) internal _building;
    /// User buildings indexes
    mapping(address user => EnumerableSet.UintSet) internal _indexes;
    /// User building index counter
    mapping(address user => uint256 buildingIndex) internal _counter;
    /// User building type amount
    mapping(address user => mapping(uint256 typeId => uint256 count)) internal _count;

    /// User mining speed modificator
    mapping(address user =>
        mapping(uint256 buildingIndex => 
            mapping(address resource => Modificator.Mod mod))) internal _speedMod;
    /// User storage volume modificator
    mapping(address user =>
        mapping(uint256 buildingIndex => 
            mapping(address resource => Modificator.Mod mod))) internal _volumeMod;
    /// Equipped items
    mapping(address user =>
        mapping(uint256 buildingIndex =>
            mapping(uint256 slotId => Item item))) internal _items;

    constructor(
        address techAddress,
        address mapAddress,
        address slotsAddress
    ) Proxy() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());

        _tech = IEmTech(techAddress);
        _map = IEmMapExternal(mapAddress);
        _slots = IEmSlots(slotsAddress);
    }

}