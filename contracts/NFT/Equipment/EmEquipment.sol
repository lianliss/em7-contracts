// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEmEquipment} from "./interfaces/IEmEquipment.sol";
import {EmERC721, IERC165} from "../EmERC721/EmERC721.sol";
import {ResourceMod, UserMod, EquipmentType, Item, Collection} from "./interfaces/structs.sol";
import {Errors} from "../../game/errors.sol";

contract EmEquipment is AccessControl, EmERC721, IEmEquipment {

    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    uint256 internal _typesLength;
    mapping(uint256 typeId => EquipmentType) internal _types;
    mapping(uint256 tokenId => Item) internal _items;
    mapping(uint256 tokenId => address locker) internal _lockers;
    Collection[] internal _collections;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        _grantRole(MOD_ROLE, _msgSender());
    }


    /// Read methods

    function getCollections(uint256 offset, uint256 limit) public view returns (Collection[] memory, uint256 count) {
        count = _collections.length;
        if (offset >= count || limit == 0) return (new Collection[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Collection[] memory data = new Collection[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _collections[i];
        }
        return (data, count);
    }

    function getTypes(uint256 offset, uint256 limit) public view returns (EquipmentType[] memory, uint256 count) {
        count = _typesLength;
        if (offset >= count || limit == 0) return (new EquipmentType[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        EquipmentType[] memory data = new EquipmentType[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _types[i];
        }
        return (data, count);
    }

    function getTokens(address user, uint256 offset, uint256 limit) public view returns (Item[] memory, uint256 count) {
        count = _ownerTokens[user].length();
        if (offset >= count || limit == 0) return (new Item[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Item[] memory data = new Item[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _items[i];
        }
        return (data, count);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        return _types[_tokenTypes[tokenId]].tokenURI;
    }


    /// Admin methods

    function addCollection(string calldata title) public onlyRole(EDITOR_ROLE) {
        uint256 collectionId = _collections.length;
        _collections.push(Collection(
            collectionId,
            title
        ));
        emit CollectionAdded(collectionId, title);
    }

    function updateCollection(uint256 collectionId, string calldata title) public onlyRole(EDITOR_ROLE) {
        _requireCollectionExists(collectionId);
        _collections[collectionId].title = title;
        emit CollectionUpdated(collectionId, title);
    }

    function addType(
        uint256 collectionId,
        uint256 slotId,
        uint256 transferableAfter,
        string calldata imageURI,
        string calldata name
    ) public onlyRole(EDITOR_ROLE) {
        _requireCollectionExists(collectionId);
        uint256 typeId = _typesLength++;
        _types[typeId].collectionId = collectionId;
        _types[typeId].slotId = slotId;
        _types[typeId].transferableAfter = transferableAfter;
        _types[typeId].tokenURI = imageURI;
        _types[typeId].name = name;
        
        emit TypeAdded(
            typeId,
            collectionId,
            slotId,
            transferableAfter,
            imageURI,
            name
        );
    }

    function updateType(
        uint256 typeId,
        uint256 collectionId,
        uint256 slotId,
        uint256 transferableAfter,
        string calldata imageURI,
        string calldata name
    ) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        _requireCollectionExists(collectionId);
        _types[typeId].collectionId = collectionId;
        _types[typeId].slotId = slotId;
        _types[typeId].transferableAfter = transferableAfter;
        _types[typeId].tokenURI = imageURI;
        _types[typeId].name = name;
        
        emit TypeUpdated(
            typeId,
            collectionId,
            slotId,
            transferableAfter,
            imageURI,
            name
        );
    }

    function setTypeMods(
        uint256 typeId,
        UserMod[] calldata userMods,
        ResourceMod[] calldata buildingMods,
        ResourceMod[] calldata borderingMods
    ) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        delete _types[typeId].userMods;
        for (uint256 i; i < _types[typeId].userMods.length; i++) {
            _types[typeId].userMods.push(userMods[i]);
        }
        delete _types[typeId].buildingMods;
        for (uint256 i; i < _types[typeId].buildingMods.length; i++) {
            _types[typeId].buildingMods.push(buildingMods[i]);
        }
        delete _types[typeId].borderingMods;
        for (uint256 i; i < _types[typeId].borderingMods.length; i++) {
            _types[typeId].borderingMods.push(borderingMods[i]);
        }
        emit TypeModsSet(
            typeId,
            userMods,
            buildingMods,
            borderingMods
        );
    }


    /// External methods

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl, EmERC721) returns (bool) {
        return
            interfaceId == type(AccessControl).interfaceId ||
            interfaceId == type(EmERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mint(address user, uint256 typeId, uint256 lockup) external onlyRole(MOD_ROLE) returns (uint256 tokenId) {
        return _mintLocked(user, typeId, lockup);
    }

    function mint(address user, uint256 typeId) external onlyRole(MOD_ROLE) returns (uint256 tokenId) {
        return _mintLocked(user, typeId, 1);
    }

    function burn(uint256 tokenId) external onlyRole(MOD_ROLE) {
        if (_items[tokenId].locked) {
            revert Errors.TokenLockedError(_lockers[tokenId]);
        }
        address user = _requireOwned(tokenId);
        uint256 typeId = _items[tokenId].typeId;
        _burn(tokenId);
        delete _items[tokenId];
        _types[typeId].count--;
        emit Burned(user, typeId, tokenId);
    }

    function lock(uint256 tokenId) external onlyRole(MOD_ROLE) {
        _requireOwned(tokenId);
        if (_items[tokenId].locked) {
            revert Errors.TokenLockedError(_lockers[tokenId]);
        } else {
            _lockers[tokenId] = _msgSender();
            _items[tokenId].locked = true;
            emit TokenLocked(tokenId, _msgSender());
        }
    }

    function unlock(uint256 tokenId) external onlyRole(MOD_ROLE) {
        _requireOwned(tokenId);
        if (_items[tokenId].locked) {
            delete _lockers[tokenId];
            _items[tokenId].locked = false;
            emit TokenUnlocked(tokenId, _msgSender());
        } else {
            revert("Token unlocked");
        }
    }

    function getUserMods(uint256 tokenId) external view returns (UserMod[] memory) {
        _requireOwned(tokenId);
        return _types[_tokenTypes[tokenId]].userMods;
    }

    function getBuildingMods(uint256 tokenId) external view returns (ResourceMod[] memory) {
        _requireOwned(tokenId);
        return _types[_tokenTypes[tokenId]].buildingMods;
    }

    function getBorderingMods(uint256 tokenId) external view returns (ResourceMod[] memory) {
        _requireOwned(tokenId);
        return _types[_tokenTypes[tokenId]].borderingMods;
    }

    function getSlot(uint256 tokenId) external view returns (uint256) {
        _requireOwned(tokenId);
        return _types[_tokenTypes[tokenId]].slotId;
    }


    /// Internal methods

    function _mintLocked(address user, uint256 typeId, uint256 lockup) internal returns (uint256 tokenId) {
        _requireTypeExists(typeId);
        tokenId = _tokensIndex++;
        _mint(user, tokenId);
        _items[tokenId].tokenId = tokenId;
        _items[tokenId].typeId = typeId;
        uint256 transferable = _types[typeId].transferableAfter;
        if (lockup > transferable) {
            transferable = lockup;
        }
        if (transferable > 0) {
            _items[tokenId].transferableAfter = block.timestamp + transferable;
        }
        _types[typeId].count++;
        emit Minted(user, typeId, tokenId);
    }

    function _requireTypeExists(uint256 typeId) internal view {
        require(typeId < _typesLength, "Type is not exists");
    }

    function _requireCollectionExists(uint256 collectionId) internal view {
        require(collectionId < _collections.length, "Collection is not exists");
    }

    function _isTransferable(uint256 tokenId) internal view returns (bool) {
        uint256 transferableAfter = _items[tokenId].transferableAfter;
        if (transferableAfter == 0) {
            return false;
        } else {
            return block.timestamp > transferableAfter
            && !_items[tokenId].locked;
        }
    }

    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view override  returns (bool) {
        return
            _isTransferable(tokenId)
            && spender != address(0)
            && ((owner == spender) || (_getApproved(tokenId) == spender));
    }

}