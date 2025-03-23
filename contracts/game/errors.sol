// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Errors {

    error TechNotResearchedError(uint256 techIndex);

    error AreaAlreadyClaimedError(uint256 x, uint256 y);
    error PositionIsOccupiedError(uint256 x, uint256 y, uint8 size);

    error BuildingTypeCountLimitError(uint256 limit);
    error SlotOccupiedError(address tokenAddress, uint256 tokenId);

    error HaveConsumersError(uint8 pipeIndex, address consumerAddress);
    error WrongConsumerError(uint8 pipeIndex, address consumerAddress);
    error HaveSourcesError(uint8 sourceIndex, address sourceAddress);

}