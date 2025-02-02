// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IProxy {
    error DelegateCallFailed(bytes data);
    function delegate(string memory method, bytes calldata dataBytes) external returns (bool, bytes memory);
}