// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IIncomeDistributor, IncomeDestination} from "./interfaces/IIncomeDistributor.sol";
import {PERCENT_PRECISION} from "../const.sol";

contract IncomeDistributor is AccessControl, IERC20Errors, IIncomeDistributor {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");

    IERC20 private immutable _erc20;
    EnumerableSet.AddressSet private _destination;
    address private _defaultDestination;
    mapping (address destination => uint24 percents) private _share;
    mapping (address destination => string title) private _title;

    constructor(address erc20Address) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(SPENDER_ROLE, erc20Address);

        _erc20 = IERC20(erc20Address);
        _defaultDestination = _msgSender();
        emit DefaultDestinationUpdated(_msgSender());
    }

    receive() external payable {
        _distribute(_msgSender(), msg.value);
    }

    /// Public getters

    /// @notice Returns all income destinations
    /// @return IncomeDestination structure
    function getDestinations() public view returns(IncomeDestination[] memory) {
        IncomeDestination[] memory result = new IncomeDestination[](_destination.length() + 1);
        uint24 defaultShare = uint24(PERCENT_PRECISION);
        for (uint256 i; i < _destination.length(); i++) {
            result[i].destination = _destination.at(i);
            result[i].title = _title[result[i].destination];
            result[i].share = _share[result[i].destination];
            defaultShare -= result[i].share;
        }
        result[result.length - 1].destination = _defaultDestination;
        result[result.length - 1].title = "Default shares remainder";
        result[result.length - 1].share = defaultShare;
        return result;
    }

    /// Public setters

    /// @notice Distributes coin income
    /// @param sender Income origin
    function distribute(address sender) external payable {
        _distribute(sender, msg.value);
    }

    /// @notice Distributes ERC20 income
    /// @param sender Income origin
    /// @param amount Amount of ERC20 token
    /// @dev Require SPENDER_ROLE
    function distributeFrom(address sender, uint256 amount) external onlyRole(SPENDER_ROLE) {
        uint256 allowance = _erc20.allowance(sender, address(this));
        if (amount < allowance) {
            revert ERC20InsufficientAllowance(address(this), allowance, amount);
        }
        _distribute(sender, amount);
    }

    /// Admin methods

    /// @notice Adds a new income destination
    /// @param destinationAddress Income receiver
    /// @param title Destination description
    /// @param sharePercents Share percents with 6 digits of precition (100% = 1 million)
    function addDestination(address destinationAddress, string calldata title, uint24 sharePercents) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_destination.contains(destinationAddress), "This destination is already exists");
        require(_getTotalPercents() + sharePercents <= PERCENT_PRECISION, "Total share more than 100%");
        
        _destination.add(destinationAddress);
        _share[destinationAddress] = sharePercents;
        _title[destinationAddress] = title;
        emit DestinationAdded(destinationAddress, title, sharePercents);
    }

    /// @notice Removes an income destination
    /// @param destinationAddress Income receiver
    function removeDestination(address destinationAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_destination.contains(destinationAddress), "This destination is not exists");
        _destination.remove(destinationAddress);
        delete _share[destinationAddress];
        emit DestinationRemoved(destinationAddress);
    }

    /// @notice Updates an income destination share
    /// @param destinationAddress Income receiver
    /// @param sharePercents Share percents with 6 digits of precition (100% = 1 million)
    function updateDestinationShare(address destinationAddress, uint24 sharePercents) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_destination.contains(destinationAddress), "This destination is not exists");
        require(_getTotalPercents() - _share[destinationAddress] + sharePercents <= PERCENT_PRECISION, "Total share more than 100%");

        _share[destinationAddress] = sharePercents;
        emit DestinationShareUpdated(destinationAddress, sharePercents);
    }

    /// @notice Updates an income destination title
    /// @param destinationAddress Income receiver
    /// @param title Destination description
    function updateDestinationTitle(address destinationAddress, string calldata title) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_destination.contains(destinationAddress), "This destination is not exists");

        _title[destinationAddress] = title;
        emit DestinationTitleUpdated(destinationAddress, title);
    }

    /// @notice Updates the default destination of an income remainder
    /// @param destinationAddress Income receiver
    function setDefaultDestination(address destinationAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _defaultDestination = destinationAddress;
        emit DefaultDestinationUpdated(destinationAddress);
    }

    /// @notice Sends income to the single destination
    function _send(address sender, address destination, uint256 amount) internal {
        if (address(_erc20) == address(0)) {
            (bool sent,) = destination.call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            require(_erc20.transferFrom(
                sender,
                destination,
                amount
            ), "Can't transfer ERC20");
        }
    }

    /// @notice Distributes income to all destinations based on it's shares
    function _distribute(address sender, uint256 amount) internal {
        uint256 value = address(_erc20) == address(0)
            ? msg.value
            : amount;
        uint256 amountLeft = value;
        for (uint256 i; i < _destination.length(); i++) {
            address destination = _destination.at(i);
            uint256 share = value * _share[destination] / PERCENT_PRECISION;
            _send(sender, destination, share);
            amountLeft -= share;
            emit IncomeDistributed(sender, destination, value, share);
        }
        if (amountLeft > 0) {
            _send(sender, _defaultDestination, amountLeft);
            emit IncomeDistributed(sender, _defaultDestination, value, amountLeft);
        }
    }

    /// @notice Returns total shares sum
    function _getTotalPercents() internal view returns(uint24 total) {
        for (uint256 i; i < _destination.length(); i++) {
            total += _share[_destination.at(i)];
        }
    }

}