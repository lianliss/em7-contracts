// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/Proxy/Proxy.sol";
import {CallData} from "../utils/CallData.sol";
import {Errors} from "../game/errors.sol";

abstract contract ProxyImplementation is Proxy {

    constructor(address proxyAddress) {
        _setProxy(proxyAddress);
    }

    /// @notice Process external call data
    /// @param success Is successful call
    /// @param data External call data. Can be error calldata
    /// @return Call data
    function processCalldata(bool success, bytes memory data) private pure returns (bytes memory) {
        if (success) {
            return data;
        } else {
            bytes4 errorSignature = bytes4(data);
            if (errorSignature == 0x08c379a0) {
                /// Default error method: Error(string)
                (string memory errorMessage) = abi.decode(CallData.extract(data), (string));
                revert(errorMessage);
            } else {
                /// Unknown custom error method

                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, data), mload(data))
                }
            }
        }
    }

    function routedDelegate(string memory method, bytes memory callData) internal virtual
    returns (bool isOrigin, bytes memory resultData) {
        if (address(_getProxy()) == address(0)) {
            return (true, bytes(""));
        } else {
            (bool success, bytes memory data) = _getProxy().delegate(method, callData);
            return (false, processCalldata(success, data));
        }
    }
    
}