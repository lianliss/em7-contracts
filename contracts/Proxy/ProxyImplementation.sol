// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/Proxy/Proxy.sol";

abstract contract ProxyImplementation is Proxy {

    constructor(address proxyAddress) {
        _setProxy(proxyAddress);
    }

    function routedDelegate(string memory method, bytes memory callData) internal virtual
    returns(bool isOrigin, bytes memory resultData) {
        if (address(_getProxy()) == address(0)) {
            return (true, bytes(""));
        } else {
            (bool success, bytes memory data) = _getProxy().delegate(method, callData);
            if (success) {
                return (false, data);
            } else {
                revert DelegateCallFailed(data);
            }
        }
    }
    
}