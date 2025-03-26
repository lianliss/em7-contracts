// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EmPipeContext, Proxy} from "../context/EmPipeContext.sol";
import {Progression} from "../../../utils/Progression.sol";
import {EmPipeInternal} from "./EmPipeInternal.sol";
import {IEmBuilding, Building} from "../interfaces/IEmBuilding.sol";
import {IEmPipe} from "../interfaces/IEmPipe.sol";
import {IEmTech} from "../../tech/interfaces/IEmTech.sol";
import {Errors} from "../../errors.sol";
import {Consumer} from "../interfaces/structs.sol";

/// @notice Pipe extention for building functionality;
/// @dev Use in building functionality contract;
abstract contract EmPipe is EmPipeContext, EmPipeInternal, IEmPipe {

    using Progression for Progression.Params;

    constructor(address buildingAddress, address techAddress) Proxy() {
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
    function getConsumers(address user, uint256 buildingIndex) public view returns (Consumer[] memory) {
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
    function lockPipe(address user, uint256 buildingIndex, uint8 pipeIndex, uint256 consumerIndex) public virtual onlyRole(CONSUMER_ROLE) {
        if (techRequired == 0 || !_tech.haveTech(user, techRequired)) {
            revert Errors.TechNotResearchedError(techRequired);
        }
        Building memory building = _building.getBuilding(user, buildingIndex);
        _requirePipeExists(building, pipeIndex);
        address consumerAddress = _msgSender();
        Consumer storage consumer = _consumers[user][building.index][pipeIndex];
        if (consumer.functionality != address(0)) {
            revert Errors.HaveConsumersError(pipeIndex, consumer.functionality, consumer.buildingIndex);
        }
        consumer.functionality = consumerAddress;
        consumer.buildingIndex = consumerIndex;

        emit PipeLocked(user, building.index, pipeIndex, consumerAddress, consumerIndex);
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
        address consumerAddress = _msgSender();
        Consumer storage consumer = _consumers[user][building.index][pipeIndex];
        if (consumer.functionality != consumerAddress) {
            revert Errors.WrongConsumerError(pipeIndex, consumer.functionality, consumer.buildingIndex);
        }
        emit PipeUnlocked(user, building.index, pipeIndex, consumer.functionality, consumer.buildingIndex);
        delete _consumers[user][building.index][pipeIndex];
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

}