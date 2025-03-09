// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IProxy} from "contracts/Proxy/IProxy.sol";

abstract contract Proxy is IProxy, AccessControl {

    IProxy private _proxy;

    bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");

    constructor() {
        _grantRole(PROXY_ROLE, address(this));
        _grantRole(PROXY_ROLE, _msgSender());
    }

    function delegate(string memory method, bytes calldata callData) external virtual onlyRole(PROXY_ROLE)
    returns (bool, bytes memory) {
        (bool success, bytes memory data) = _msgSender().delegatecall(
            abi.encodeWithSignature(method, callData)
        );
        return (success, data);
    }

    function _setProxy(address proxyAddress) internal virtual {
        _proxy = IProxy(proxyAddress);
    }

    function _getProxy() internal view virtual returns (IProxy) {
        return _proxy;
    }
}