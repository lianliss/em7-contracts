// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {NFTTokenType} from "../EmERC721Structs.sol";

interface IEmERC721 is IERC721Metadata, IERC721Errors {
    
}