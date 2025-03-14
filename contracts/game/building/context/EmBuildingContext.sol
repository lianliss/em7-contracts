// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Proxy} from "../../../Proxy/Proxy.sol";
import {IEmSlots} from "../../slots/interfaces/IEmSlots.sol";
import {IEmTech} from "../../tech/interfaces/IEmTech.sol";
import {IEmMapExternal} from "../../map/interfaces/IEmMapExternal.sol";
import {BuildingType, Building} from "../interfaces/IEmBuilding.sol";

abstract contract EmBuildingContext is Proxy {

    bytes32 internal constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 internal constant MOD_ROLE = keccak256("MOD_ROLE");

    IEmSlots internal immutable _slots;
    IEmTech internal immutable _tech;
    IEmMapExternal internal immutable _map;

    uint256 internal _returnDevider = 2;

    uint256 internal _typesLength;
    mapping(uint256 typeId => BuildingType) internal _types;
    mapping(address user => mapping(uint256 buildingIndex => Building)) internal _building;
    mapping(address user => EnumerableSet.UintSet) internal _indexes;
    mapping(address user => uint256 buildingIndex) internal _counter;
    mapping(address user => mapping(uint256 typeId => uint256 count)) internal _count;

    constructor(
        address slotsAddress,
        address techAddress,
        address mapAddress
    ) Proxy() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());

        _slots = IEmSlots(slotsAddress);
        _tech = IEmTech(techAddress);
        _map = IEmMapExternal(mapAddress);
    }

}