// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmBuilding, Building} from "../interfaces/IEmBuilding.sol";
import {IEmPipe} from "../interfaces/IEmPipe.sol";

abstract contract EmPipe is AccessControl, IEmPipe {

    using Progression for Progression.Params;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

    IEmBuilding internal immutable _building;

    mapping(uint256 typeId => Progression.Params amount) internal _pipes;
    mapping(
        address user => mapping(
            uint256 buildingIndex => mapping(
                uint8 pipeIndex => address consumer))) internal _consumers;

    constructor(address buildingAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        _grantRole(CONSUMER_ROLE, _msgSender());

        _building = IEmBuilding(buildingAddress);
    }

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

    function lockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) public virtual onlyRole(CONSUMER_ROLE) {
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

}