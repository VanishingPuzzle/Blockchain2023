// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract LENDCOIN2 is ERC20, ERC20Burnable, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("LENDCOIN2", "lND2") ERC20Permit("LENDCOIN2") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
     //Changes Admin Role

    function changeMinterRole(address _newMinter) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_newMinter != address(0), "New admin cannot be zero address");
    grantRole(MINTER_ROLE, _newMinter);
    revokeRole(MINTER_ROLE, msg.sender);
}
}
