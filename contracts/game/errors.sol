// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEmErrors {

    error TechNotResearched(uint256 techIndex);

    error AreaAlreadyClaimed(uint256 x, uint256 y);
    error PositionIsOccupied(uint256 x, uint256 y, uint8 size);

    error BuildingTypeCountLimit(uint256 limit);
    error SlotOccupiedError(address tokenAddress, uint256 tokenId);

    error HaveConsumersError(uint8 pipeIndex, address consumerAddress);
    error WrongConsumerError(uint8 pipeIndex, address consumerAddress);

}