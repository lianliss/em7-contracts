// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Progression} from "../../../utils/Progression.sol";
import {Consumer} from "./structs.sol";

interface IEmPipe {

    event TechRequiredSet(uint256 techIndex);
    event PipesSet(uint256 typeId, Progression.Params amount);
    event PipeLocked(address indexed user, uint256 indexed buildingIndex, uint8 indexed pipeIndex, address consumer, uint256 consumerIndex);
    event PipeUnlocked(address indexed user, uint256 indexed buildingIndex, uint8 indexed pipeIndex, address consumer, uint256 consumerIndex);

    function getPipeOutput(address user, uint256 buildingIndex, uint8 pipeIndex) external view returns (Consumer memory consumer, address resource, uint256 amountPerSecond);
    function getConsumers(address user, uint256 buildingIndex) external view returns (Consumer[] memory);
    function lockPipe(address user, uint256 buildingIndex, uint8 pipeIndex, uint256 consumerIndex) external;
    function unlockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) external;

}