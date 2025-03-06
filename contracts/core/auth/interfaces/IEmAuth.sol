// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEmAuth {

    event AccountAuthorized(address indexed account, uint256 level);
    event AccountDeauthorized(address indexed account, uint256 level);
    event AccountBlocked(address indexed account);
    event AccountUnblocked(address indexed account);

    function hasAuth(address account, uint256 level) external view returns (bool);
    function isBlocked(address account) external view returns (bool);
    function banCheck(address account) external view;
    function getAuths(address account) external view returns (uint256[] memory);
    function blockAccount(address account) external;
    function unblockAccount(address account) external;
    function addAccountAuth(address account, uint256 level) external;
    function removeAccountAuth(address account, uint256 level) external;

}