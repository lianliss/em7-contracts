// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEmStarsERC20Extention is IERC20 {

    /// @notice Returns holder balance of unlocked funds;
    /// @param holder Holder address;
    /// @return Available balance
    function balanceOf(address holder) external view returns (uint256);

    /// @notice Returns holder locked balance available for payments only;
    /// @param holder Holder address;
    /// @return Locked balance for payments;
    function lockedOf(address holder) external view returns (uint256);

    /// @notice Returns total supply with currently unlocked lockups;
    /// @return Total Supply
    function totalSupply() external view returns (uint256);
    
    /// @notice Returns total supply locked by dates;
    /// @return Locked Total Supply
    function lockedSupply() external view returns (uint256);

    /// @notice Transfer current holder funds;
    /// @param to Recipient address;
    /// @param value Tokens to transfer;
    /// @return Transaction success
    function transfer(address to, uint256 value) external returns (bool);

    /// @notice Transfer holder funds;
    /// @param from Holder address;
    /// @param to Recipient address;
    /// @param value Tokens to transfer;
    /// @return Transaction success
    function transferFrom(address from, address to, uint256 value) external returns (bool);

}