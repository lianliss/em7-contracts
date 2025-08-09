// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEmERC721} from "../../EmERC721/interfaces/IEmERC721.sol";
import "./structs.sol";

interface ILootbox is IEmERC721 {

    event CollectionAdded(uint256 indexed collectionId, string title);
    event CollectionUpdated(uint256 indexed collectionId, string title);
    event TokenLocked(uint256 indexed tokenId, address locker);
    event TokenUnlocked(uint256 indexed tokenId, address locker);

    event TypeAdded(uint256 indexed typeId, LootboxType newType);
    event TypeUpdated(uint256 indexed typeId, LootboxType existingType);
    event DropAdded(uint256 indexed typeId, Drop[] drop);
    event DropCleared(uint256 indexed typeId);
    event DropRolled(address indexed user, uint256 indexed typeId, uint256 boxId, address nftAddress, uint256 nftTypeId, uint256 nftTokenId);

    function open(uint256 tokenId) external;

}