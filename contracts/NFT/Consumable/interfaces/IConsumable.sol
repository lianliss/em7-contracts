// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEmERC721} from "../../EmERC721/interfaces/IEmERC721.sol";
import "./structs.sol";

interface IConsumable is IEmERC721 {

    event CollectionAdded(uint256 indexed collectionId, string title);
    event CollectionUpdated(uint256 indexed collectionId, string title);

    event Minted(address indexed user, uint256 indexed typeId, uint256 indexed tokenId);
    event Burned(address indexed user, uint256 indexed typeId, uint256 indexed tokenId);

    event TypeAdded(uint256 indexed typeId, ConsumableType newType);
    event TypeUpdated(uint256 indexed typeId, ConsumableType existingType);

    event ItemUsed(address indexed user, uint256 indexed typeId, uint256 indexed tokenId, uint256 chargesLeft);

    function mint(address user, uint256 typeId) external returns (uint256 tokenId);
    function burn(uint256 tokenId) external;

}