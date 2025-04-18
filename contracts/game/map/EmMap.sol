// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {MemoryQueue} from "../../utils/sequence/MemoryQueue.sol";
import {EmMapContext, Coords, Object, Progression} from "./context/EmMapContext.sol";
import {IEmResFactory} from "../../token/EmResource/interfaces/IEmResFactory.sol";
import {IEmResource} from "../../token/EmResource/interfaces/IEmResource.sol";
import {IEmSlots} from "../slots/interfaces/IEmSlots.sol";
import {IEmMap} from "./interfaces/IEmMap.sol";
import {PERCENT_PRECISION} from "../../core/const.sol";
import {MONEY_RES_ID, CLAIM_PARAM_ID, CLAIM_STARS_PARAM_ID} from "../const.sol";
import {Errors} from "../errors.sol";

/// @dev Require EmStars SPENDER_ROLE;
/// @dev Require EmResFactory BURNER_ROLE;
contract EmMap is EmMapContext, IEmMap {

    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using MemoryQueue for MemoryQueue.Queue;
    using Progression for Progression.Params;
    using Coords for Coords.Point;

    constructor(address starsAddress, address resFactoryAddress, address slotsAddress)
    EmMapContext(starsAddress, resFactoryAddress, slotsAddress) {}
    

    /// Read methods

    function getClaimedAreas(address user, uint256 offset, uint256 limit) public view returns (Coords.Point[] memory, uint256 count) {
        count = _claimedHashes[user].length();
        if (offset >= count || limit == 0) return (new Coords.Point[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Coords.Point[] memory data = new Coords.Point[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _claimedAreas[user][_claimedHashes[user].at(offset + i)];
        }
        return (data, count);
    }

    function getBuildingObject(address user, uint256 buildingIndex) public view returns (Object memory) {
        return _objects[user][_buildings[user][buildingIndex]];
    }

    function getObjects(address user, uint256 offset, uint256 limit) public view returns (Object[] memory, uint256 count) {
        count = _objectsHashes[user].length();
        if (offset >= count || limit == 0) return (new Object[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Object[] memory data = new Object[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _objects[user][_objectsHashes[user].at(offset + i)];
        }
        return (data, count);
    }

    function getTileObject(address user, uint256 x, uint256 y) public view returns (Object memory) {
        bytes32 hash = _tiles[user][x][y];
        if (hash == bytes32(0)) {
            return Object(
                Coords.Point(x, y),
                0,
                0
            );
        } else {
            return _objects[user][hash];
        }
    }

    function getTileBuilding(address user, uint256 x, uint256 y) public view returns (uint256) {
        return getTileObject(user, x, y).buildingIndex;
    }

    function getBorderingBuildings(address user, uint256 buildingIndex) public view returns (uint256[] memory) {
        require(_buildings[user][buildingIndex] != bytes32(0), "Building is not placed");
        MemoryQueue.Queue memory set;
        Object memory obj = _objects[user][_buildings[user][buildingIndex]];
        if (obj.origin.x != 0 && obj.origin.y != 0) {
            uint256 b = getTileBuilding(user, obj.origin.x - 1, obj.origin.y - 1);
            if (b > 0) set.push(b);
        }
        for (uint256 i = obj.origin.x; i <= obj.origin.x + uint256(obj.size); i++) {
            if (obj.origin.y > 0) {
                uint256 bottom = getTileBuilding(user, i, obj.origin.y - 1);
                if (bottom > 0 && !_inArray(set.values(), bottom)) set.push(bottom);
            }
            uint256 top = getTileBuilding(user, i, obj.origin.y + uint256(obj.size));
            if (top > 0 && !_inArray(set.values(), top)) set.push(top);
        }
        for (uint256 i = obj.origin.y; i <= obj.origin.y + uint256(obj.size); i++) {
            if (obj.origin.x > 0) {
                uint256 left = getTileBuilding(user, obj.origin.x - 1, i);
                if (left > 0 && !_inArray(set.values(), left)) set.push(left);
            }
            uint256 right = getTileBuilding(user, obj.origin.x + uint256(obj.size), i);
            if (right > 0 && !_inArray(set.values(), right)) set.push(right);
        }
        return set.values();
    }


    /// Write methods

    function claimArea(uint256 x, uint256 y) public {
        address user = _msgSender();
        uint256 price = _price.get(_paidAreas[user]++);
        IEmResource money = _money();
        price = price * _slots.getMod(user, CLAIM_PARAM_ID) / PERCENT_PRECISION;
        if (price > 0) money.burn(user, price);
        _claimArea(user, x, y);
        emit AreaPaid(user, x, y, address(money), price);
    }

    function claimAreaStars(uint256 x, uint256 y) public {
        address user = _msgSender();
        uint256 price = _price.get(_starsPaidAreas[user]++);
        price = price * _slots.getMod(user, CLAIM_STARS_PARAM_ID) / PERCENT_PRECISION;
        if (price > 0) _stars.spend(user, price);
        _claimArea(user, x, y);
        emit AreaPaid(user, x, y, address(_stars), price);
    }

    function claimFor(address user, uint256 x, uint256 y) public onlyRole(MOD_ROLE) {
        _claimArea(user, x, y);
    }


    /// Admin methods

    function setClaimPrice(Progression.Params calldata params) public onlyRole(EDITOR_ROLE) {
        _price = params;
        emit ClaimPriceSet(params);
    }

    function setClaimStarsPrice(Progression.Params calldata params) public onlyRole(EDITOR_ROLE) {
        _starsPrice = params;
        emit ClaimStarsPriceSet(params);
    }


    /// External methods

    function setObject(address user, uint256 x, uint256 y, uint8 size, uint256 buildingIndex) public onlyRole(BUILDER_ROLE) {
        if (_isOccupied(user, x, y, size)) {
            revert Errors.PositionIsOccupiedError(x, y, size);
        }
        bytes32 hash = Coords.Point(x, y).hash();
        _buildings[user][buildingIndex] = hash;
        _objectsHashes[user].add(hash);
        _objects[user][hash] = Object(
            Coords.Point(x, y),
            size,
            buildingIndex
        );
        uint256 xLimit = x + uint256(size);
        uint256 yLimit = y + uint256(size);
        for (uint256 h = x; h < xLimit; h++) {
            for (uint256 v = y; v < yLimit; v++) {
                _tiles[user][h][v] = hash;
            }
        }
        emit ObjectSet(user, x, y, size, buildingIndex);
    }

    function removeObject(address user, uint256 buildingIndex) public onlyRole(BUILDER_ROLE) {
        bytes32 hash = _buildings[user][buildingIndex];
        require(hash != bytes32(0), "Building is not placed");
        Object memory object = _objects[user][hash];
        uint256 x = object.origin.x;
        uint256 y = object.origin.y;
        uint8 size = object.size;
        uint256 xLimit = x + uint256(size);
        uint256 yLimit = y + uint256(size);
        for (uint256 h = x; h < xLimit; h++) {
            for (uint256 v = y; v < yLimit; v++) {
                delete _tiles[user][x][y];
            }
        }
        delete _objects[user][hash];
        _objectsHashes[user].remove(hash);
        delete _buildings[user][buildingIndex];
        emit ObjectRemoved(user, x, y, size, buildingIndex);
    }


    /// Internal methods

    function _money() internal view returns (IEmResource) {
        return IEmResource(_res.addressAt(MONEY_RES_ID));
    }

    function _requireBorderingArea(address user, uint256 x, uint256 y) internal view {
        if (x == 0 && y == 0) return;
        if (x != 0 && _isClaimed(user, x - Coords.AREA_SIZE, y)) return;
        if (x != y && _isClaimed(user, x, y - Coords.AREA_SIZE)) return;
        if (_isClaimed(user, x + Coords.AREA_SIZE, y)) return;
        if (_isClaimed(user, x, y + Coords.AREA_SIZE)) return;
        require(false, "Claimed bordering area required");
    }

    function _claimArea(address user, uint256 x, uint256 y) internal {
        Coords.Point memory origin = Coords.Point(x, y).area();
        _requireBorderingArea(user, origin.x, origin.y);
        bytes32 hash = origin.hash();
        if (_claimedHashes[user].contains(hash)) {
            revert Errors.AreaAlreadyClaimedError(x,y);
        }
        _claimedHashes[user].add(hash);
        _claimedAreas[user][hash] = origin;
        emit AreaClaimed(user, origin.x, origin.y);
    }

    function _isClaimed(address user, uint256 x, uint256 y) internal view returns(bool) {
        return _claimedHashes[user].contains(Coords.Point(x, y).hash());
    }

    function _inArray(uint256[] memory array, uint256 value) internal pure returns (bool) {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == value) return true;
        }
        return false;
    }

    function _isOccupied(address user, uint256 x, uint256 y) internal view returns (bool) {
        return _tiles[user][x][y] != bytes32(0);
    }

    function _isOccupied(address user, uint256 x, uint256 y, uint8 size) internal view returns (bool) {
        uint256 xLimit = x + uint256(size);
        uint256 yLimit = y + uint256(size);
        for (uint256 h = x; h < xLimit; h++) {
            for (uint256 v = y; v < yLimit; v++) {
                if (_isOccupied(user, h, v)) return true;
            }
        }
        return false;
    }

}