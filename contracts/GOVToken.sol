// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract GovernanceToken is ERC20, Ownable, ERC20Permit {
    constructor()
        ERC20("GovernanceToken", "GOV")
        ERC20Permit("GovernanceToken")
    {
        _mint(msg.sender, 40000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
