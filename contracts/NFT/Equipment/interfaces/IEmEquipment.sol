// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEmERC721} from "../../EmERC721/interfaces/IEmERC721.sol";
import {IEmEquipmentMod} from "./IEmEquipmentMod.sol";
import "./structs.sol";

interface IEmEquipment is IEmERC721 {

    error TokenLockedError(address locker);

    event CollectionAdded(uint256 indexed collectionId, string title);
    event CollectionUpdated(uint256 indexed collectionId, string title);
    event TokenLocked(uint256 indexed tokenId, address locker);
    event TokenUnlocked(uint256 indexed tokenId, address locker);

    event TypeAdded(
        uint256 indexed typeId,
        uint256 indexed collectionId,
        uint256 transferableAfter,
        string imageURI,
        string name
    );

    event TypeUpdated(
        uint256 indexed typeId,
        uint256 indexed collectionId,
        uint256 transferableAfter,
        string imageURI,
        string name
    );

    event TypeModsSet(
        uint256 indexed typeId,
        ParamMod[] userMods,
        ResourceMod[] buildingMods,
        ResourceMod[] borderingMods
    );

    event Minted(address indexed user, uint256 indexed typeId, uint256 tokenId);
    event Burned(address indexed user, uint256 indexed typeId, uint256 tokenId);

    function getCollections(uint256 offset, uint256 limit) external view returns (Collection[] memory, uint256 count);
    function getTypes(uint256 offset, uint256 limit) external view returns (EquipmentType[] memory, uint256 count);
    function getTokens(address user, uint256 offset, uint256 limit) external view returns (Item[] memory, uint256 count);

    function addCollection(string calldata title) external;
    function updateCollection(uint256 collectionId, string calldata title) external;
    function addType(
        uint256 collectionId,
        uint256 transferableAfter,
        string calldata imageURI,
        string calldata name
    ) external;
    function updateType(
        uint256 typeId,
        uint256 collectionId,
        uint256 transferableAfter,
        string calldata imageURI,
        string calldata name
    ) external;
    function setTypeMods(
        uint256 typeId,
        ParamMod[] calldata userMods,
        ResourceMod[] calldata buildingMods,
        ResourceMod[] calldata borderingMods
    ) external;

}