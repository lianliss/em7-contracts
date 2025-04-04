//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Balances {

    function getBalances(address recipient, address[] calldata tokens) public view returns (uint[] memory) {
        uint length = tokens.length;
        uint[] memory response = new uint[](length);
        for (uint i = 0; i < length; i++) {
            try IERC20(tokens[i]).balanceOf(recipient) returns (uint balance) {
                response[i] = balance;
            } catch {
                response[i] = 0;
            }
        }
        return response;
    }

}