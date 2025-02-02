// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct IncomeDestination {
    address destination;
    string title;
    uint24 share;
}

interface IIncomeDistributor {

    event IncomeDistributed(address indexed sender, address indexed destination, uint256 total, uint256 distributed);
    event DestinationAdded(address indexed destination, string title, uint24 share);
    event DestinationRemoved(address indexed destination);
    event DestinationShareUpdated(address indexed destination, uint24 share);
    event DestinationTitleUpdated(address indexed destination, string title);
    event DefaultDestinationUpdated(address indexed destination);

    function getDestinations() external view returns(IncomeDestination[] memory);
    function spread(address sender) external payable;
    function spreadFrom(address sender, uint256 amount) external;

}