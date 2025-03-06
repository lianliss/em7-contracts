// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {NFTTokenType} from "./interfaces/IEmERC721.sol";

abstract contract EmERC721Context {

    using EnumerableSet for EnumerableSet.UintSet;

    string internal constant _name = "EmERC721";
    string internal constant _symbol = "PXLNFT";
    bool internal _transfersDisabled = true;

    NFTTokenType[] internal _types;

    mapping(uint256 tokenId => address) internal _tokenApprovals;
    mapping(address owner => mapping(address operator => bool)) internal _operatorApprovals;
    mapping(uint256 tokenId => uint256 typeId) internal _tokenTypes;
    uint256 _typesIndex = 1;

    mapping(uint256 tokenId => address) internal _owners;
    mapping(address owner => uint256) internal _balances;

    mapping(address owner => EnumerableSet.UintSet) internal _ownerTokens;

}