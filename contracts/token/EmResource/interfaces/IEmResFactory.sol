// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

struct ResourceData {
    address resource;
    string name;
    string symbol;
}

interface IEmResFactory is IAccessControl {

    event WhitelistMemberAdded(address account);
    event WhitelistMemberRemoved(address account);
    event ResourceCreated(address resource, string name, string symbol);
    event ResourceRemoved(address resource);
    event TransfersAllowanceSet(bool isAllowed);

    function isWhitelisted(address account) external view returns (bool);
    function isTransfersAllowed() external view returns (bool);
    function addToWhitelist(address account) external;
    function removeFromWhitelist(address account) external;
    function setTransfersAllowed(bool isAllowed) external;
    function createResource(string calldata name, string calldata symbol) external;
    function removeResource(address resource) external;
    function getResources() external view returns (ResourceData[] memory);
    function at(uint256 index) external view returns (ResourceData memory);
    function addressAt(uint256 index) external view returns (address);
    function getWhitelist() external view returns (address[] memory);

}