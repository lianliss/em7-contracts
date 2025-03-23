// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Proxy} from "../../../Proxy/Proxy.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmBuilding} from "../interfaces/IEmBuilding.sol";
import {IEmTech} from "../../tech/interfaces/IEmTech.sol";

/// @notice Pipe extention for building functionality;
/// @dev Use in building functionality contract;
abstract contract EmPipeContext is Proxy {

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

}