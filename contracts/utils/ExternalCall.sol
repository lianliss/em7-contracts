// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CallData} from "./CallData.sol";

abstract contract ExternalCall {

    error CustomRevert(bytes data);

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
                revert CustomRevert(data);
            }
        }
    }

    /// @notice Call methos in the external contract by the address and method ABI.
    /// @param contractAddress Address of the callable contract.
    /// @param method ABI of method where the first param is a user address
    /// @param userAddress The user for whom the method is called
    /// @param extraParams ABI encoded static params
    /// @return External method result
    /// @dev To avoid incorrect calldata conversion, use only static data
    /// @dev Prohibited params types: string, bytes, dymanic arrays, dynamic tuples
    /// @dev method param example: "test(address,uint256[2],bytes4)"
    function externalCall(
        address contractAddress,
        string memory method,
        address userAddress,
        bytes memory extraParams
    ) internal returns(bytes memory) {
        bytes4 signature = bytes4(keccak256(bytes(method)));
        (bool success, bytes memory data) = contractAddress.call(bytes.concat(
            signature, 
            abi.encode(userAddress),
            extraParams
        ));
        return processCalldata(success, data);
    }

}