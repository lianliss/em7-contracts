// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEmReferral, ReferralPercents} from "./interfaces/IEmReferral.sol";
import {PERCENT_PRECISION} from "../const.sol";

contract EmReferral is AccessControl, IEmReferral {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant CONNECTOR_ROLE = keccak256("CONNECTOR_ROLE");
    bytes32 public constant MODIFIER_ROLE = keccak256("MODIFIER_ROLE");

    mapping(address child => address parent) private _parents;
    mapping(address parent => EnumerableSet.AddressSet children) private _children;

    uint256[] private _percents = [100000, 50000];
    uint256[] private _percentsLimits = [200000, 150000];

    mapping(address account => EnumerableSet.Bytes32Set sourceHash) private _adderSource;
    mapping(bytes32 sourceHash => uint256 adder) private _sourceAdders;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(CONNECTOR_ROLE, _msgSender());
        _grantRole(MODIFIER_ROLE, _msgSender());
    }

    function getReferralPercents(address childAddress) external view returns (ReferralPercents[] memory) {
        ReferralPercents[] memory result = new ReferralPercents[](_percents.length);
        address parent = _parents[childAddress];
        for (uint256 i; i < _percents.length; i++) {
            uint256 limit = _percentsLimits[i] == 0
                ? _percents[i]
                : _percentsLimits[i];
            result[i].parentAddress = parent;
            result[i].percents = _percents[i] + _getAdder(parent);
            if (result[i].percents > limit) {
                result[i].percents = limit;
            }
            parent = _parents[parent];
        }
        return result;
    }

    function getParent(address childAddress) public view returns (address) {
        return _parents[childAddress];
    }

    function getChildrenCount(address parentAddress) public view returns (uint256) {
        return _children[parentAddress].length();
    }

    function getChildren(address parentAddress, uint256 offset, uint256 limit) public view returns (address[] memory) {
        uint256 count = getChildrenCount(parentAddress);
        if (offset >= count) return new address[](0);
        count -= offset;
        uint256 length = count < limit
            ? count
            : limit;
        address[] memory children = new address[](length);
        for (uint256 i = offset; i < offset + limit; i++) {
            children[i - offset] = _children[parentAddress].at(i);
        }
        return children;
    }

    function addRelation(address parentAddress, address childAddress) public onlyRole(CONNECTOR_ROLE) {
        _removeRelation(childAddress);
        _parents[childAddress] = parentAddress;
        _children[parentAddress].add(childAddress);
        emit RelationAdded(parentAddress, childAddress);
    }

    function addAccountPercents(address account, uint256 sourceId, uint256 adder) external onlyRole(MODIFIER_ROLE) {
        bytes32 sourceHash = _getSourceHash(sourceId);
        require(!_adderSource[account].contains(sourceHash), "Referral percents is already installed from this source");
        _adderSource[account].add(sourceHash);
        _sourceAdders[sourceHash] = adder;
        emit AccountPercentsAdded(account, _msgSender(), sourceId, adder);
    }

    function removeAccountPercents(address account, uint256 sourceId) external onlyRole(MODIFIER_ROLE) {
        bytes32 sourceHash = _getSourceHash(sourceId);
        require(_adderSource[account].contains(sourceHash), "Referral percents from this source is not found");
        uint256 adder = _sourceAdders[sourceHash];
        _adderSource[account].remove(sourceHash);
        emit AccountPercentsAdded(account, _msgSender(), sourceId, adder);
    }

    function setPercents(uint256[] calldata percents, uint256[] calldata limits) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(percents.length == limits.length, "Lengths mismatch");
        _percents = percents;
        _percentsLimits = limits;
        emit PercentsSet(percents, limits);
    }

    function _getSourceHash(uint256 sourceId) internal view returns(bytes32) {
        return keccak256(abi.encode(_msgSender(), sourceId));
    }

    function _getAdder(address account) internal view returns(uint256) {
        uint256 adder;
        for (uint256 i; i < _adderSource[account].length(); i++) {
            adder += _sourceAdders[_adderSource[account].at(i)];
        }
        return adder;
    }

    function _removeRelation(address childAddress) internal {
        address parentAddress = _parents[childAddress];
        if (parentAddress != address(0)) {
            delete _parents[childAddress];
            _children[parentAddress].remove(childAddress);
            emit RelationRemoved(parentAddress, childAddress);
        }
    }

}