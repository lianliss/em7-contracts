// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {EmERC721, IERC165} from "../EmERC721/EmERC721.sol";
import {IConsumable} from "./interfaces/IConsumable.sol";
import {ExternalCall} from "../../utils/ExternalCall.sol";
import {Errors} from "../../game/errors.sol";
import "./interfaces/structs.sol";

contract Consumable is AccessControl, EmERC721, ExternalCall, IConsumable {

    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    uint256 internal _typesLength;
    mapping(uint256 typeId => ConsumableType) internal _types;
    mapping(uint256 tokenId => ConsumableItem) internal _items;
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

    function getTypes(uint256 offset, uint256 limit) public view returns (ConsumableType[] memory, uint256 count) {
        count = _typesLength;
        if (offset >= count || limit == 0) return (new ConsumableType[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        ConsumableType[] memory data = new ConsumableType[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _types[i];
        }
        return (data, count);
    }

    function getTokens(address user, uint256 offset, uint256 limit) public view returns (ConsumableItem[] memory, uint256 count) {
        count = _ownerTokens[user].length();
        if (offset >= count || limit == 0) return (new ConsumableItem[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        ConsumableItem[] memory data = new ConsumableItem[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _items[i];
        }
        return (data, count);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        return _types[_tokenTypes[tokenId]].tokenURI;
    }


    /// Write methods

    function use(uint256 tokenId, uint256 x, uint256 y) public {
        address user = _requireOwned(tokenId);
        if (user != _msgSender()) {
            revert ERC721InvalidOwner(user);
        }
        uint256 typeId = _tokenTypes[tokenId];
        ConsumableItem storage item = _items[tokenId];
        ConsumableType storage tokenType = _types[typeId];
        bytes memory params = tokenType.useCoords
            ? abi.encode(user, x, y, tokenType.params)
            : abi.encode(user, tokenType.params);
        externalCall(
            tokenType.contractAddress,
            tokenType.method,
            params
        );
        item.charges--;
        emit ItemUsed(user, typeId, tokenId, item.charges);
        if (item.charges == 0) {
            _burn(tokenId);
            delete _items[tokenId];
            _types[typeId].count--;
            emit Burned(user, typeId, tokenId);
        }
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
        ConsumableType calldata newType
    ) public onlyRole(EDITOR_ROLE) {
        _requireCollectionExists(newType.collectionId);
        uint256 typeId = _typesLength++;
        _types[typeId] = newType;
        _types[typeId].typeId = typeId;
        
        emit TypeAdded(
            typeId,
            _types[typeId]
        );
    }

    function updateType(
        ConsumableType calldata existingType
    ) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(existingType.typeId);
        _requireCollectionExists(existingType.collectionId);
        _types[existingType.typeId] = existingType;
        
        emit TypeUpdated(
            existingType.typeId,
            existingType
        );
    }


    /// External methods

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, IERC165, EmERC721) returns (bool) {
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
        address user = _requireOwned(tokenId);
        uint256 typeId = _items[tokenId].typeId;
        _burn(tokenId);
        delete _items[tokenId];
        _types[typeId].count--;
        emit Burned(user, typeId, tokenId);
    }


    /// Internal methods

    function _mintLocked(address user, uint256 typeId, uint256 lockup) internal returns (uint256 tokenId) {
        _requireTypeExists(typeId);
        tokenId = _tokensIndex++;
        _mint(user, tokenId);
        _items[tokenId].tokenId = tokenId;
        _items[tokenId].typeId = typeId;
        _items[tokenId].charges = _types[typeId].charges;
        _items[tokenId].transferableAfter = lockup > 0
            ? block.timestamp + lockup
            : 0;
        _types[typeId].count++;
        emit Minted(user, typeId, tokenId, _items[tokenId].transferableAfter);
    }

    function _requireTypeExists(uint256 typeId) internal view {
        require(typeId < _typesLength, "Type is not exists");
    }

    function _requireCollectionExists(uint256 collectionId) internal view {
        require(collectionId < _collections.length, "Collection is not exists");
    }
    
    function _isTransferable(uint256 tokenId) internal view returns (bool) {
        uint256 transferableAfter = _items[tokenId].transferableAfter;
        if (_types[_items[tokenId].typeId].transferable) {
            if (transferableAfter == 0) {
                return false;
            } else {
                return block.timestamp > transferableAfter;
            }
        } else {
            return false;
        }
    }

    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view override  returns (bool) {
        return
            _isTransferable(tokenId)
            && spender != address(0)
            && ((owner == spender) || (_getApproved(tokenId) == spender));
    }

}

