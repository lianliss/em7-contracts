// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct Tech {
    uint256 index;
    string title;
    uint256 price;
    uint256 parentTech;
    bool disabled;
}

interface IEmTech {

    event TechAdded(uint256 indexed techIndex, string title, uint256 price, uint256 parentTech);
    event TechUpdated(uint256 indexed techIndex, string title, uint256 price, uint256 parentTech);
    event TechDisabled(uint256 indexed techIndex);
    event TechEnabled(uint256 indexed techIndex);
    event TechResearched(address indexed user, uint256 indexed techIndex);
    event ScienceBurned(address indexed user, uint256 amount);

    /// @notice Parent technology required;
    /// @param parentTech Parent technology index;
    error ParentTechRequired(uint256 parentTech);

    function getTree(uint256 offset, uint256 limit) external view returns (Tech[] memory, uint256 count);
    function haveTech(address user, uint256 techIndex) external view returns (bool);
    function research(uint256 techIndex) external;
    function researchFor(address user, uint256 techIndex, bool force) external;
    function addTech(string calldata title, uint256 price, uint256 parentTech) external;
    function updateTech(uint256 techIndex, string calldata title, uint256 price, uint256 parentTech) external;
    function disableTech(uint256 techIndex) external;
    function enableTech(uint256 techIndex) external;


}