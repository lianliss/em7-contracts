//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import {EmBuildingContext, Modificator, Item} from "./context/EmBuildingContext.sol";
import {ProxyImplementation} from "../../Proxy/ProxyImplementation.sol";
import {IEmBuildingEditor} from "./interfaces/IEmBuildingEditor.sol";
import {BuildRequirements, ResourceProgression, Progression} from "./interfaces/structs.sol";

contract EmBuildingEditor is EmBuildingContext, ProxyImplementation, IEmBuildingEditor {

    constructor(
        address slotsAddress,
        address techAddress,
        address mapAddress,
        address buildingAddress
    ) EmBuildingContext(slotsAddress, techAddress, mapAddress) ProxyImplementation(buildingAddress) {}

    function _setReturnDevider(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xSetReturnDevider(bytes)", encoded);
        if (isProxy) {
            (uint256 devider) = abi.decode(encoded, (uint256));
            require(devider > 0, "Devider can't be zero");
            _returnDevider = devider;
            emit ReturnDeviderSet(devider);
        }
    }
    /// @notice Proxy entrance
    function xSetReturnDevider(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _setReturnDevider(encoded);
    }
    /// @notice public entrance
    function setReturnDevider(uint256 devider) public onlyRole(EDITOR_ROLE) {
        _setReturnDevider(abi.encode(devider));
    }


    function _addType(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xAddType(bytes)", encoded);
        if (isProxy) {
            (
                string memory title,
                address functionalityAddress,
                uint256 minLevel,
                uint256 maxLevel
            ) = abi.decode(encoded, (string, address, uint256, uint256));
            uint256 typeId = _typesLength++;
            _types[typeId].typeId = typeId;
            _setType(typeId, title, functionalityAddress, minLevel, maxLevel);
        }
    }
    /// @notice Proxy entrance
    function xAddType(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _addType(encoded);
    }
    /// @notice public entrance
    function addType(
        string memory title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel
    ) public onlyRole(EDITOR_ROLE) {
        _addType(abi.encode(title, functionalityAddress, minLevel, maxLevel));
    }


    function _updateType(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xUpdateType(bytes)", encoded);
        if (isProxy) {
            (
                uint256 typeId,
                string memory title,
                address functionalityAddress,
                uint256 minLevel,
                uint256 maxLevel
            ) = abi.decode(encoded, (uint256, string, address, uint256, uint256));
            _requireTypeExists(typeId);
            _setType(typeId, title, functionalityAddress, minLevel, maxLevel);
        }
    }
    /// @notice Proxy entrance
    function xUpdateType(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _updateType(encoded);
    }
    /// @notice public entrance
    function updateType(
        uint256 typeId,
        string memory title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel
    ) public onlyRole(EDITOR_ROLE) {
        _updateType(abi.encode(typeId, title, functionalityAddress, minLevel, maxLevel));
    }


    function _setTypeSlots(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xSetTypeSlots(bytes)", encoded);
        if (isProxy) {
            (
                uint256 typeId, uint256[] memory slots
            ) = abi.decode(encoded, (uint256, uint256[]));
            _requireTypeExists(typeId);
            _types[typeId].slots = slots;
            emit BuildingTypeSlotsSet(typeId, slots);
        }
    }
    /// @notice Proxy entrance
    function xSetTypeSlots(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _setTypeSlots(encoded);
    }
    /// @notice public entrance
    function setTypeSlots(uint256 typeId, uint256[] memory slots) public onlyRole(EDITOR_ROLE) {
        _setTypeSlots(abi.encode(typeId, slots));
    }


    function _setBuildingRequirements(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xSetBuildingRequirements(bytes)", encoded);
        if (isProxy) {
            (
                uint256 typeId, BuildRequirements memory requirements
            ) = abi.decode(encoded, (uint256, BuildRequirements));
            _requireTypeExists(typeId);
            delete _types[typeId].construction.resources;
            for (uint256 i; i < requirements.resources.length; i++) {
                _types[typeId].construction.resources.push(ResourceProgression(
                    requirements.resources[i].resource,
                    requirements.resources[i].amount
                ));
            }
            _types[typeId].construction.time = requirements.time;
            _types[typeId].construction.levelTech = requirements.levelTech;
            emit BuildingRequirementsSet(typeId, requirements);
        }
    }
    /// @notice Proxy entrance
    function xSetBuildingRequirements(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _setBuildingRequirements(encoded);
    }
    /// @notice public entrance
    function setBuildingRequirements(uint256 typeId, BuildRequirements memory requirements) public onlyRole(EDITOR_ROLE) {
        _setBuildingRequirements(abi.encode(typeId, requirements));
    }


    function _disableType(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xDisableType(bytes)", encoded);
        if (isProxy) {
            (
                uint256 typeId
            ) = abi.decode(encoded, (uint256));
            _requireTypeExists(typeId);
            _types[typeId].disabled = true;
            emit BuildingTypeDisabled(typeId);
        }
    }
    /// @notice Proxy entrance
    function xDisableType(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _disableType(encoded);
    }
    /// @notice public entrance
    function disableType(uint256 typeId) public onlyRole(EDITOR_ROLE) {
        _disableType(abi.encode(typeId));
    }


    function _enableType(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xEnableType(bytes)", encoded);
        if (isProxy) {
            (
                uint256 typeId
            ) = abi.decode(encoded, (uint256));
            _requireTypeExists(typeId);
            _types[typeId].disabled = false;
            emit BuildingTypeEnabled(typeId);
        }
    }
    /// @notice Proxy entrance
    function xEnableType(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _disableType(encoded);
    }
    /// @notice public entrance
    function enableType(uint256 typeId) public onlyRole(EDITOR_ROLE) {
        _disableType(abi.encode(typeId));
    }


    /// Internal methods

    function _requireTypeExists(uint256 typeId) internal view {
        require(typeId < _typesLength, "Building type is not exists");
    }

    function _setType(
        uint256 typeId,
        string memory title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel
    ) internal {
        _types[typeId].title = title;
        _types[typeId].functionality = functionalityAddress;
        _types[typeId].minLevel = minLevel;
        _types[typeId].maxLevel = maxLevel;

        emit BuildingTypeSet(typeId, functionalityAddress, title, minLevel, maxLevel);
    }

}