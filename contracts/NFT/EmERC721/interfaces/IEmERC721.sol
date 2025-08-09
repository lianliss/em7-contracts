// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

interface IEmERC721 is IERC721, IERC721Metadata, IERC721Errors {

    event Minted(address indexed user, uint256 indexed typeId, uint256 indexed tokenId, uint256 transferableAfter);
    event Burned(address indexed user, uint256 indexed typeId, uint256 indexed tokenId);

    function mint(address user, uint256 typeId) external returns (uint256 tokenId);
    function mint(address user, uint256 typeId, uint256 lockup) external returns (uint256 tokenId);
    function burn(uint256 tokenId) external;

}