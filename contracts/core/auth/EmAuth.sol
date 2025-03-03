// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEmAuth} from "./interfaces/IEmAuth.sol";

contract EmAuth is AccessControl, IEmAuth {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant AUTHORIZER_ROLE = keccak256("AUTHORIZER_ROLE");
    bytes32 public constant BLACKLIST_ROLE = keccak256("BLACKLIST_ROLE");

    mapping(address account => EnumerableSet.UintSet) private _auths;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(AUTHORIZER_ROLE, _msgSender());
        _grantRole(BLACKLIST_ROLE, _msgSender());
    }

    function hasAuth(address account, uint256 level) public view returns (bool) {
        return _auths[account].contains(level) && !_auths[account].contains(0);
    }

    function isBlocked(address account) public view returns (bool) {
        return _auths[account].contains(0);
    }

    function getAuths(address account) public view returns (uint256[] memory) {
        if (isBlocked(account)) {
            return new uint256[](0);
        } else {
            uint256 length = _auths[account].length();
            uint256[] memory auths = new uint256[](length);
            for (uint256 i; i < length; i++) {
                auths[i] = _auths[account].at(i);
            }
            return auths;
        }
    }

    function blockAccount(address account) public onlyRole(BLACKLIST_ROLE) {
        _auths[account].add(0);
        emit AccountBlocked(account);
    }

    function unblockAccount(address account) public onlyRole(BLACKLIST_ROLE) {
        _auths[account].remove(0);
        emit AccountUnblocked(account);
    }

    function addAccountAuth(address account, uint256 level) public onlyRole(AUTHORIZER_ROLE) {
        require(!isBlocked(account), "Account blocked");
        _auths[account].add(level);
        emit AccountAuthorized(account, level);
    }

    function removeAccountAuth(address account, uint256 level) public onlyRole(AUTHORIZER_ROLE) {
        _auths[account].remove(level);
        emit AccountDeauthorized(account, level);
    }
}