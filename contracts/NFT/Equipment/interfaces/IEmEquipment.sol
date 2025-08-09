// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEmERC721} from "../../EmERC721/interfaces/IEmERC721.sol";
import "./structs.sol";

interface IEmEquipment is IEmERC721 {

    event CollectionAdded(uint256 indexed collectionId, string title);
    event CollectionUpdated(uint256 indexed collectionId, string title);
    event TokenLocked(uint256 indexed tokenId, address locker);
    event TokenUnlocked(uint256 indexed tokenId, address locker);

    event TypeAdded(
        uint256 indexed typeId,
        uint256 indexed collectionId,
        uint256 indexed slotId,
        uint256 transferableAfter,
        string imageURI,
        string name
    );

    event TypeUpdated(
        uint256 indexed typeId,
        uint256 indexed collectionId,
        uint256 indexed slotId,
        uint256 transferableAfter,
        string imageURI,
        string name
    );

    event TypeModsSet(
        uint256 indexed typeId,
        UserMod[] userMods,
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
        uint256 slotId,
        uint256 transferableAfter,
        string calldata imageURI,
        string calldata name
    ) external;
    function updateType(
        uint256 typeId,
        uint256 collectionId,
        uint256 slotId,
        uint256 transferableAfter,
        string calldata imageURI,
        string calldata name
    ) external;
    function setTypeMods(
        uint256 typeId,
        UserMod[] calldata userMods,
        ResourceMod[] calldata buildingMods,
        ResourceMod[] calldata borderingMods
    ) external;

    function mint(address user, uint256 typeId) external returns (uint256 tokenId);
    function mint(address user, uint256 typeId, uint256 lockup) external returns (uint256 tokenId);
    function burn(uint256 tokenId) external;
    function lock(uint256 tokenId) external;
    function unlock(uint256 tokenId) external;
    function getUserMods(uint256 tokenId) external view returns (UserMod[] memory);
    function getBuildingMods(uint256 tokenId) external view returns (ResourceMod[] memory);
    function getBorderingMods(uint256 tokenId) external view returns (ResourceMod[] memory);
    function getSlot(uint256 tokenId) external view returns (uint256);

}