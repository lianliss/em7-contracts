// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20, IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IEmResource} from "./interfaces/IEmResource.sol";
import {IEmResFactory} from "./interfaces/IEmResFactory.sol";
import {IEmAuth} from "../../core/auth/interfaces/IEmAuth.sol";

contract EmResource is ERC20, IEmResource {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    IEmResFactory private immutable _factory;
    IEmAuth private immutable _auth;

    constructor(
        string memory name,
        string memory symbol,
        address authAddress
        ) ERC20(name, symbol) {
        _factory = IEmResFactory(_msgSender());
        _auth = IEmAuth(authAddress);
    }

    function transferFrom(address from, address to, uint256 value) public override(ERC20, IERC20) returns (bool) {
        _auth.banCheck(from);
        address spender = _msgSender();
        if (!_factory.isWhitelisted(spender)) {
            require(_factory.isTransfersAllowed(), "Transfers are not allowed");
            _spendAllowance(from, spender, value);
        }
        _transfer(from, to, value);
        return true;
    }

    function transfer(address to, uint256 value) public override(ERC20, IERC20) returns (bool) {
        require(_factory.isTransfersAllowed(), "Transfers are not allowed");
        _auth.banCheck(to);
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function mint(address to, uint256 amount) external {
        require(_factory.hasRole(MINTER_ROLE, _msgSender()), "Mint action is not allowed");
        _auth.banCheck(to);
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(_factory.hasRole(BURNER_ROLE, _msgSender()), "Burn action is not allowed");
        _burn(from, amount);
    }

}