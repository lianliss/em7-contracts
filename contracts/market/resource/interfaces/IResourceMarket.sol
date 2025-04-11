// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./structs.sol";

interface IResourceMarket {

    event OfferSet(address indexed resource, uint256 buyPrice, uint256 sellPrice);
    event OfferDeleted(address indexed resource);

    event ResourcePurchased(address indexed user, address indexed resource, uint256 amount, uint256 price);
    event ResourceSold(address indexed user, address indexed resource, uint256 amount, uint256 price);

    function getOffers(uint256 offset, uint256 limit) external view returns (ResourceOffer[] memory, uint256 count);
    function buy(address resourceAddress, uint256 amount) external returns (uint256 price);
    function sell(address resourceAddress, uint256 amount) external returns (uint256 price);

    function setOffer(ResourceOffer calldata offer) external;


}