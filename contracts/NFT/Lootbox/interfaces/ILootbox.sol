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

    event Minted(address indexed user, uint256 indexed typeId, uint256 tokenId, uint256 transferableAfter);
    event Burned(address indexed user, uint256 indexed typeId, uint256 tokenId);

    function mint(address user, uint256 typeId) external returns (uint256 tokenId);
    function mint(address user, uint256 typeId, uint256 lockup) external returns (uint256 tokenId);
    function burn(uint256 tokenId) external;
    function open(uint256 tokenId) external;

}