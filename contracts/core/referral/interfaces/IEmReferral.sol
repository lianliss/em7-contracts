// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEmReferralPercents, ReferralPercents} from "./IEmReferralPercents.sol";

interface IEmReferral is IEmReferralPercents {

    event RelationAdded(address indexed parent, address indexed child);
    event RelationRemoved(address indexed parent, address indexed child);
    event AccountPercentsAdded(address indexed parent, address indexed sender, uint256 indexed sourceId, uint256 adder);
    event AccountPercentsRemoved(address indexed parent, address indexed sender, uint256 indexed sourceId, uint256 adder);
    event PercentsSet(uint256[] percents, uint256[] limits);
    
    function addRelation(address parentAddress, address childAddress) external;
    function addAccountPercents(address account, uint256 sourceId, uint256 adder) external;
    function removeAccountPercents(address account, uint256 sourceId) external;

    function getParent(address childAddress) external view returns (address);
    function getChildrenCount(address parentAddress) external view returns (uint256);
    function getChildren(address parentAddress, uint256 offset, uint256 limit) external view returns (address[] memory);

}