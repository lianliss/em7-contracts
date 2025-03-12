// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Proxy} from "../../../Proxy/Proxy.sol";
import {IEmSlots} from "../../slots/interfaces/IEmSlots.sol";
import {IEmTech} from "../../tech/interfaces/IEmTech.sol";
import {BuildingType} from "../interfaces/IEmBuilding.sol";

abstract contract EmBuildingContext is Proxy {

    bytes32 internal constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    IEmSlots internal immutable _slots;
    IEmTech internal immutable _tech;

    uint256 internal _typesLength;
    mapping(uint256 typeId => BuildingType) internal _types;

    constructor(address slotsAddress, address techAddress) Proxy() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());

        _slots = IEmSlots(slotsAddress);
        _tech = IEmTech(techAddress);
    }

}