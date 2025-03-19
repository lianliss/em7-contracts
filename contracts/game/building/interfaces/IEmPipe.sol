// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEmPipe {

    error HaveConsumersError(uint8 pipeIndex, address consumerAddress);
    error WrongConsumerError(uint8 pipeIndex, address consumerAddress);

    event PipeLocked(address indexed user, uint256 indexed buildingIndex, uint8 indexed pipeIndex, address consumer);
    event PipeUnlocked(address indexed user, uint256 indexed buildingIndex, uint8 indexed pipeIndex, address consumer);

    function getPipeOutput(address user, uint256 buildingIndex, uint8 pipeIndex) external returns (address consumer, address resource, uint256 amountPerSecond);

}