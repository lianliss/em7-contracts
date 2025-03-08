// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEmResFactory, ResourceData} from "./interfaces/IEmResFactory.sol";
import {EmResource, IERC20Metadata} from "./EmResource.sol";

contract EmResFactory is AccessControl, IEmResFactory {

    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address private immutable _auth;
    EnumerableSet.AddressSet private _whitelist;
    EnumerableSet.AddressSet private _resources;
    bool public isTransfersAllowed;

    constructor(address authAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(BURNER_ROLE, _msgSender());

        _auth = authAddress;
    }

    function getResources() public view returns (ResourceData[] memory) {
        uint256 length = _resources.length();
        ResourceData[] memory data = new ResourceData[](length);

        for (uint256 i; i < length; i++) {
            data[i].resource = _resources.at(i);
            IERC20Metadata token = IERC20Metadata(data[i].resource);
            data[i].name = token.name();
            data[i].symbol = token.symbol();
        }
        return data;
    }

    function getWhitelist() public view returns (address[] memory) {
        return _whitelist.values();
    }

    function isWhitelisted(address account) external view returns (bool) {
        return _whitelist.contains(account);
    }

    function addToWhitelist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_whitelist.contains(account), "Account already in whitelist");
        _whitelist.add(account);
        emit WhitelistMemberAdded(account);
    }

    function removeFromWhitelist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_whitelist.contains(account), "Account is not in whitelist");
        _whitelist.remove(account);
        emit WhitelistMemberRemoved(account);
    }

    function setTransfersAllowed(bool isAllowed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isTransfersAllowed = isAllowed;
        emit TransfersAllowanceSet(isAllowed);
    }

    function createResource(string calldata name, string calldata symbol) public onlyRole(EDITOR_ROLE) {
        address resource = address(new EmResource(name, symbol, _auth));
        _resources.add(resource);
        emit ResourceCreated(resource, name, symbol);
    }

    function removeResource(address resource) public onlyRole(EDITOR_ROLE) {
        require(_resources.contains(resource), "Resource is not in the list");
        _resources.remove(resource);
        emit ResourceRemoved(resource);
    }

}
