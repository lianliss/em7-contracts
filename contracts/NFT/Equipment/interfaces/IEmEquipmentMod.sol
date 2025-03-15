// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./structs.sol";

interface IEmEquipmentMod {

    function mint(address user, uint256 typeId) external;
    function burn(uint256 tokenId) external;
    function lock(uint256 tokenId) external;
    function unlock(uint256 tokenId) external;
    function getUserMods(uint256 tokenId) external view returns (ParamMod[] memory);
    function getBuildingMods(uint256 tokenId) external view returns (ResourceMod[] memory);
    function getBorderingMods(uint256 tokenId) external view returns (ResourceMod[] memory);
    function getSlot(uint256 tokenId) external view returns (uint256);

}