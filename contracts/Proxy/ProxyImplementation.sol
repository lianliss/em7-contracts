// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/Proxy/Proxy.sol";

abstract contract ProxyImplementation is Proxy {

    constructor(address proxyAddress) {
        setProxy(proxyAddress);
    }

    function routedDelegate(string memory method, bytes memory callData) internal virtual
    returns(bool isOrigin, bytes memory resultData) {
        if (address(getProxy()) == address(0)) {
            return (true, bytes(""));
        } else {
            (bool success, bytes memory data) = getProxy().delegate(method, callData);
            if (success) {
                return (false, data);
            } else {
                revert DelegateCallFailed(data);
            }
        }
    }
    
}