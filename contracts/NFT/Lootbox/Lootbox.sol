// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ILootbox} from "./interfaces/ILootbox.sol";
import {EmERC721, IERC165, IEmERC721} from "../EmERC721/EmERC721.sol";
import "./interfaces/structs.sol";
import {Errors} from "../../game/errors.sol";
import {PERCENT_PRECISION} from "../../core/const.sol";

contract Lootbox is AccessControl, EmERC721, ILootbox {

    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    uint256 internal _typesLength;
    mapping(uint256 typeId => LootboxType) internal _types;
    mapping(uint256 tokenId => LootboxItem) internal _items;
    mapping(uint256 tokenId => address locker) internal _lockers;
    Collection[] internal _collections;

    uint256 private _randomCounter;

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

    function getTypes(uint256 offset, uint256 limit) public view returns (LootboxType[] memory, uint256 count) {
        count = _typesLength;
        if (offset >= count || limit == 0) return (new LootboxType[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        LootboxType[] memory data = new LootboxType[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _types[i];
        }
        return (data, count);
    }

    function getTokens(address user, uint256 offset, uint256 limit) public view returns (LootboxItem[] memory, uint256 count) {
        count = _ownerTokens[user].length();
        if (offset >= count || limit == 0) return (new LootboxItem[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        LootboxItem[] memory data = new LootboxItem[](length);
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

    function open(uint256 tokenId) public {
        address user = _requireOwned(tokenId);
        if (user != _msgSender()) {
            revert ERC721InvalidOwner(user);
        }
        uint256 typeId = _tokenTypes[tokenId];
        uint256 transferableAfter = _items[tokenId].transferableAfter;
        (,address nftAddress, uint256 nftTypeId) = _rollDrop(typeId);
        uint256 nftItemId = IEmERC721(nftAddress).mint(user, nftTypeId, transferableAfter);
        emit DropRolled(user, typeId, tokenId, nftAddress, nftTypeId, nftItemId);
        /// Burn lootbox
        _burn(tokenId);
        delete _items[tokenId];
        _types[typeId].count--;
        emit Burned(user, typeId, tokenId);
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
        LootboxType calldata newType
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
        LootboxType calldata existingType
    ) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(existingType.typeId);
        _requireCollectionExists(existingType.collectionId);
        _types[existingType.typeId] = existingType;
        
        emit TypeUpdated(
            existingType.typeId,
            existingType
        );
    }

    function addDrop(
        uint256 typeId,
        Drop[] calldata drop
    ) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        for (uint256 i; i < drop.length; i++) {
            _types[typeId].drop.push(drop[i]);
        }
        emit DropAdded(typeId, drop);
    }

    function clearDrop(
        uint256 typeId
    ) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        delete _types[typeId].drop;
        emit DropCleared(typeId);
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
        uint256 transferable = _types[typeId].transferableAfter;
        if (lockup > transferable) {
            transferable = lockup;
        }
        if (transferable > 0) {
            _items[tokenId].transferableAfter = block.timestamp + transferable;
        }
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
        if (transferableAfter == 0) {
            return false;
        } else {
            return block.timestamp > transferableAfter;
        }
    }

    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view override  returns (bool) {
        return
            _isTransferable(tokenId)
            && spender != address(0)
            && ((owner == spender) || (_getApproved(tokenId) == spender));
    }

    function _pseudoRandom(uint256 mod) internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, ++_randomCounter)))
            % mod;
    }

    function _rollRarity(uint256 typeId) internal returns (uint256) {
        uint rand = _pseudoRandom(PERCENT_PRECISION);
        uint chance;
        if (_types[typeId].drop.length > 1) {
            for (uint256 rarity = _types[typeId].drop.length - 1; rarity > 0; rarity--) {
                chance += _types[typeId].drop[rarity].chanceRatio;
                if (rand <= chance) {
                    return rarity;
                }
            }
        }
        return 0;
    }

    function _rollDrop(uint256 typeId) internal returns (uint256 rarity, address nftAddress, uint256 nftTypeId) {
        LootboxType storage box = _types[typeId];
        rarity = _rollRarity(typeId);
        Drop storage drop = box.drop[rarity];
        uint256 itemIndex = _pseudoRandom(drop.typeId.length);
        nftAddress = drop.nftAddress;
        nftTypeId = drop.typeId[itemIndex];
    }

}