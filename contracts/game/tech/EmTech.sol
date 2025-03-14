// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IEmResFactory} from "../../token/EmResource/interfaces/IEmResFactory.sol";
import {IEmResource} from "../../token/EmResource/interfaces/IEmResource.sol";
import {IEmTech, Tech} from "./interfaces/IEmTech.sol";
import {SCIENCE_RES_ID} from "../const.sol";
import {PERCENT_PRECISION} from "../../core/const.sol";
import {Modificator} from "../../utils/Modificator.sol";

contract EmTech is AccessControl, IEmTech {

    using Modificator for Modificator.Mod;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    IEmResFactory private immutable _res;
    
    Tech[] private _tech;
    mapping(address user => Modificator.Mod mod) private _mod;
    mapping(address user => mapping(uint256 techIndex => bool isResearched)) private _users;

    constructor(address resFactoryAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        _grantRole(MOD_ROLE, _msgSender());

        _res = IEmResFactory(resFactoryAddress);
    }


    /// Read methods

    /// @notice Returns technologies structures;
    /// @param offset Offset from the beginning;
    /// @param limit Maximum of technoligies to return;
    /// @return Array of technologies and count;
    function getTree(uint256 offset, uint256 limit) public view returns (Tech[] memory, uint256 count) {
        count = _tech.length;
        if (offset >= count || limit == 0) return (new Tech[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Tech[] memory data = new Tech[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _tech[offset + i];
        }
        return (data, count);
    }

    /// @notice Checks if user have researched a technology;
    /// @param user Account address;
    /// @param techIndex Technology index;
    /// @return Technology researched status;
    function haveTech(address user, uint256 techIndex) public view returns (bool) {
        return _users[user][techIndex];
    }


    /// Write methods

    /// @notice Researches a technology;
    /// @param techIndex Technology index;
    /// @dev Burns caller's science resource tokens;
    function research(uint256 techIndex) public {
        address user = _msgSender();
        uint256 mod = _mod[user].get();
        if (mod > PERCENT_PRECISION) mod = PERCENT_PRECISION;
        uint256 price = _tech[techIndex].price;
        price -= price * mod / PERCENT_PRECISION;
        if (price > 0) {
            _science().burn(user, price);
            emit ScienceBurned(user, price);
        }
        _research(user, techIndex, false);
    }

    /// External modificator methods

    /// @notice Researches a technology for user for free;
    /// @param user Account address;
    /// @param techIndex Technology index;
    function researchFor(address user, uint256 techIndex, bool force) public onlyRole(MOD_ROLE) {
        _research(user, techIndex, force);
    }

    /// @notice Sets user's science discount size
    function setMod(address user, bytes32 sourceId, uint256 value) public onlyRole(MOD_ROLE) {
        bytes32 modId = _getModId(sourceId);
        _mod[user].add(modId, value);
        emit ModSet(user, sourceId, value);
    }

    /// @notice Removes user's science discount
    function unsetMod(address user, bytes32 sourceId) public onlyRole(MOD_ROLE) {
        bytes32 modId = _getModId(sourceId);
        _mod[user].remove(modId);
        emit ModUnset(user, sourceId);
    }


    /// Admin methods

    function addTech(string calldata title, uint256 price, uint256 parentTech) public onlyRole(EDITOR_ROLE) {
        _tech.push(Tech(
            _tech.length,
            title,
            price,
            parentTech,
            false
        ));
        Tech memory tech = _tech[_tech.length - 1];
        emit TechAdded(tech.index, title, price, parentTech);
    }

    function updateTech(uint256 techIndex, string calldata title, uint256 price, uint256 parentTech) public onlyRole(EDITOR_ROLE) {
        _checkExists(techIndex);
        _tech[techIndex].title = title;
        _tech[techIndex].price = price;
        _tech[techIndex].parentTech = parentTech;
        emit TechUpdated(techIndex, title, price, parentTech);
    }

    function disableTech(uint256 techIndex) public onlyRole(EDITOR_ROLE) {
        _checkExists(techIndex);
        _tech[techIndex].disabled = true;
        emit TechDisabled(techIndex);
    }

    function enableTech(uint256 techIndex) public onlyRole(EDITOR_ROLE) {
        _checkExists(techIndex);
        _tech[techIndex].disabled = false;
        emit TechEnabled(techIndex);
    }


    /// Internal methods

    function _research(address user, uint256 techIndex, bool force) internal {
        _checkExists(techIndex);
        require(!_users[user][techIndex], "Technology already researched");
        require(!_tech[techIndex].disabled, "Technology disabled");

        uint256 parentTech = _tech[techIndex].parentTech;
        if (!force && parentTech != 0 && !haveTech(user, parentTech)) {
            revert ParentTechRequired(parentTech);
        }
        _users[user][techIndex] = true;
        emit TechResearched(user, techIndex);
    }

    function _science() internal view returns (IEmResource) {
        return IEmResource(_res.addressAt(SCIENCE_RES_ID));
    }

    function _checkExists(uint256 techIndex) internal view {
        require(techIndex < _tech.length, "Tech is not exists");
    }

    function _getModId(bytes32 sourceId) internal view returns (bytes32) {
        return keccak256(abi.encode(_msgSender(), sourceId));
    }

}