// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEmResFactory} from "../../../token/EmResource/interfaces/IEmResFactory.sol";
import {IEmStarsExternal} from "../../../token/EmStars/interfaces/IEmStarsExternal.sol";
import {Proxy} from "../../../Proxy/Proxy.sol";
import {Coords} from "../../lib/coords.sol";
import {Object} from "../interfaces/IEmMap.sol";
import {Progression} from "../../../utils/Progression.sol";

abstract contract EmMapContext is Proxy {

    bytes32 internal constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 internal constant BUILDER_ROLE = keccak256("BUILDER_ROLE");
    bytes32 internal constant MOD_ROLE = keccak256("MOD_ROLE");

    IEmStarsExternal internal immutable _stars;
    IEmResFactory internal immutable _res;

    Progression.ProgressionParams internal _price;
    Progression.ProgressionParams internal _starsPrice;

    mapping(address user => EnumerableSet.Bytes32Set) internal _claimedHashes;
    mapping(address user => mapping(bytes32 hash => Coords.Point)) internal _claimedAreas;
    mapping(address user => uint256 count) internal _paidAreas;
    mapping(address user => uint256 count) internal _starsPaidAreas;

    mapping(address user => EnumerableSet.Bytes32Set) internal _objectsHashes;
    mapping(address user => mapping(bytes32 hash => Object)) internal _objects;
    mapping(address user => mapping(uint256 buildingIndex => bytes32 hash)) internal _buildings;
    mapping(address user => mapping(uint256 x => mapping(uint256 y => bytes32 hash))) internal _tiles;

    constructor(address starsAddress, address resFactoryAddress) Proxy() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        _grantRole(BUILDER_ROLE, _msgSender());

        _stars = IEmStarsExternal(starsAddress);
        _res = IEmResFactory(resFactoryAddress);
    }

}