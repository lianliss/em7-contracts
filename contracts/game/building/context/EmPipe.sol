// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmBuilding, Building} from "../interfaces/IEmBuilding.sol";
import {IEmPipe} from "../interfaces/IEmPipe.sol";
import {IEmTech} from "../../tech/interfaces/IEmTech.sol";

/// @notice Pipe extention for building functionality;
/// @dev Use in building functionality contract;
abstract contract EmPipe is AccessControl, IEmPipe {

    using Progression for Progression.Params;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

    IEmTech internal immutable _tech;
    IEmBuilding internal immutable _building;

    uint256 public techRequired;
    /// Building type pipes amount progression
    mapping(uint256 typeId => Progression.Params amount) internal _pipes;
    /// Connected consumers
    mapping(
        address user => mapping(
            uint256 buildingIndex => mapping(
                uint8 pipeIndex => address consumer))) internal _consumers;

    constructor(address buildingAddress, address techAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        _grantRole(CONSUMER_ROLE, _msgSender());

        _building = IEmBuilding(buildingAddress);
        _tech = IEmTech(techAddress);
    }


    /// Read methods

    /// @notice Get building connected consumers;
    /// @param user Account address;
    /// @param buildingIndex Building identificator;
    /// @return Array of consumers addresses;
    function getConsumers(address user, uint256 buildingIndex) public view returns (address[] memory) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        return _getConsumers(user, building);
    }


    /// Write methods

    /// @notice Lock the building pipe with consumer;
    /// @param user Account address;
    /// @param buildingIndex Building identificator;
    /// @param pipeIndex Pipe index;
    /// @dev The message sender will be a consumer;
    /// @dev CONSUMER_ROLE required;
    function lockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) public virtual onlyRole(CONSUMER_ROLE) {
        if (techRequired == 0 || !_tech.haveTech(user, techRequired)) {
            revert TechNotResearched(techRequired);
        }
        Building memory building = _building.getBuilding(user, buildingIndex);
        _requirePipeExists(building, pipeIndex);
        address consumer = _msgSender();
        address current = _consumers[user][building.index][pipeIndex];
        if (current != address(0)) {
            revert HaveConsumersError(pipeIndex, current);
        }
        _consumers[user][building.index][pipeIndex] = consumer;
        emit PipeLocked(user, building.index, pipeIndex, consumer);
    }

    /// @notice Unlock the building pipe connection;
    /// @param user Account address;
    /// @param buildingIndex Building identificator;
    /// @param pipeIndex Pipe index;
    /// @dev Will check if the connection exitst and the consumer the same as message sender;
    /// @dev CONSUMER_ROLE required;
    function unlockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) public virtual onlyRole(CONSUMER_ROLE) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        _requirePipeExists(building, pipeIndex);
        address consumer = _msgSender();
        address current = _consumers[user][building.index][pipeIndex];
        if (current != consumer) {
            revert WrongConsumerError(pipeIndex, current);
        }
        _consumers[user][building.index][pipeIndex] = address(0);
        emit PipeUnlocked(user, building.index, pipeIndex, consumer);
    }


    /// Admin methods

    /// @notice Sets technology required for using pipes interface;
    /// @param techIndex Index of a technology;
    /// @dev EDITOR_ROLE required;
    function setTechRequired(uint256 techIndex) public onlyRole(EDITOR_ROLE) {
        techRequired = techIndex;
        emit TechRequiredSet(techIndex);
    }

    /// @notice Sets building type pipes amount;
    /// @param typeId Building type index;
    /// @param amount Pipes amount progression;
    /// @dev EDITOR_ROLE required;
    function setPipes(uint256 typeId, Progression.Params memory amount) public onlyRole(EDITOR_ROLE) {
        _pipes[typeId] = amount;
        emit PipesSet(typeId, amount);
    }


    /// Internal methods

    function _requireConstructed(Building memory building) internal view {
        require(building.constructedAt <= block.timestamp, "Building is not constructed");
    }

    function _requirePipeExists(Building memory building, uint8 pipeIndex) internal view {
        require(pipeIndex < _getPipes(building), "Pipe is not reachable");
    }

    function _requireNoConsumers(address user, Building memory building) internal view {
        uint8 pipes = _getPipes(building);
        for (uint8 i; i < pipes; i++) {
            if (_consumers[user][building.index][i] != address(0)) {
                revert HaveConsumersError(i, _consumers[user][building.index][i]);
            }
        }
    }

    function _getPipes(Building memory building) internal view returns (uint8) {
        uint256 realPipes = _pipes[building.typeId].get(building.level);
        return realPipes <= type(uint8).max
            ? uint8(realPipes)
            : type(uint8).max;
    }

    function _getConsumers(address user, Building memory building) internal view returns (address[] memory) {
        uint8 pipes = _getPipes(building);
        address[] memory consumers = new address[](pipes);
        for (uint8 i; i < pipes; i++) {
            consumers[i] = _consumers[user][building.index][i];
        }
        return consumers;
    }

}