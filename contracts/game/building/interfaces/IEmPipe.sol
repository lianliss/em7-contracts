// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEmErrors} from "../../errors.sol";
import {Progression} from "../../../utils/Progression.sol";

interface IEmPipe is IEmErrors {

    event TechRequiredSet(uint256 techIndex);
    event PipesSet(uint256 typeId, Progression.Params amount);
    event PipeLocked(address indexed user, uint256 indexed buildingIndex, uint8 indexed pipeIndex, address consumer);
    event PipeUnlocked(address indexed user, uint256 indexed buildingIndex, uint8 indexed pipeIndex, address consumer);

    function getPipeOutput(address user, uint256 buildingIndex, uint8 pipeIndex) external view returns (address consumer, address resource, uint256 amountPerSecond);
    function getConsumers(address user, uint256 buildingIndex) external view returns (address[] memory);
    function lockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) external;
    function unlockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) external;

}