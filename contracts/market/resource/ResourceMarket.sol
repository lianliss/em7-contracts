// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IResourceMarket} from "./interfaces/IResourceMarket.sol";
import {IEmResource} from "../../token/EmResource/interfaces/IEmResource.sol";
import {IEmSlots} from "../../game/slots/interfaces/IEmSlots.sol";
import {IEmResFactory} from "../../token/EmResource/interfaces/IEmResFactory.sol";
import {ResourceOffer} from "./interfaces/structs.sol";
import {Errors} from "../../game/errors.sol";
import {RES_BUY_PARAM_ID, RES_SELL_PARAM_ID, MONEY_RES_ID} from "../../game/const.sol";
import {PERCENT_PRECISION} from "../../core/const.sol";

/// @dev Require EmResFactory MINTER_ROLE;
/// @dev Require EmResFactory BURNER_ROLE;
contract ResourceMarket is AccessControl, IResourceMarket {

    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    IEmSlots internal _slots;
    IEmResFactory internal _res;

    EnumerableSet.AddressSet internal _resources;
    mapping(address resource => ResourceOffer offer) internal _offers;

    constructor(address slotsAddress, address resFactoryAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(EDITOR_ROLE, _msgSender());
        
        _slots = IEmSlots(slotsAddress);
        _res = IEmResFactory(resFactoryAddress);
    }


    /// Read methods

    /// @notice Returns resources market offers;
    /// @param offset Offset from the beginning;
    /// @param limit Return array length limit;
    /// @return Array of offers;
    /// @return count Total amount of offers;
    function getOffers(uint256 offset, uint256 limit) public view returns (ResourceOffer[] memory, uint256 count) {
        count = _resources.length();
        if (offset >= count || limit == 0) return (new ResourceOffer[](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        ResourceOffer[] memory data = new ResourceOffer[](length);
        for (uint256 i; i < length; i++) {
            data[i] = _offers[_resources.at(i)];
        }
        return (data, count);
    }


    /// Write methods

    /// @notice Buy some amount of resource;
    /// @param resourceAddress Resource contract address;
    /// @param amount Amount of the resource;
    /// @return price Purchase price;
    function buy(address resourceAddress, uint256 amount) public returns (uint256 price) {
        address user = _msgSender();
        ResourceOffer storage offer = _offers[resourceAddress];
        IEmResource resource = IEmResource(resourceAddress);
        require(offer.buyPrice > 0 && amount > 0, "This offer is not available");
        price = offer.buyPrice * amount / 10**resource.decimals();
        price = price * _slots.getMod(user, RES_BUY_PARAM_ID) / PERCENT_PRECISION;
        if (price > 0) {
            _money().burn(user, price);
        }
        resource.mint(user, amount);

        emit ResourcePurchased(user, resourceAddress, amount, price);
    }

    /// @notice Sell some amount of resource;
    /// @param resourceAddress Resource contract address;
    /// @param amount Amount of the resource;
    /// @return price Selling price;
    function sell(address resourceAddress, uint256 amount) public returns (uint256 price) {
        address user = _msgSender();
        ResourceOffer storage offer = _offers[resourceAddress];
        IEmResource resource = IEmResource(resourceAddress);
        require(offer.sellPrice > 0 && amount > 0, "This offer is not available");
        price = offer.sellPrice * amount / 10**resource.decimals();
        price = price * _slots.getMod(user, RES_SELL_PARAM_ID) / PERCENT_PRECISION;
        if (price > 0) {
            _money().mint(user, price);
        }
        resource.burn(user, amount);
        
        emit ResourceSold(user, resourceAddress, amount, price);
    }


    /// Admin methods

    function setOffer(ResourceOffer calldata offer) public onlyRole(EDITOR_ROLE) {
        if (offer.buyPrice > 0 || offer.sellPrice > 0) {
            _offers[offer.resource] = offer;
            _resources.add(offer.resource);
            emit OfferSet(offer.resource, offer.buyPrice, offer.sellPrice);
        } else {
            _resources.remove(offer.resource);
            delete _offers[offer.resource];
            emit OfferDeleted(offer.resource);
        }
    }


    /// Internal methods

    function _money() internal view returns (IEmResource) {
        return IEmResource(_res.addressAt(MONEY_RES_ID));
    }
    

}