// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract SafeDAO is Ownable {
    bytes32 public constant GOV_TOKEN = keccak256("GOV_TOKEN");
    bytes32 public constant EXCHANGE_TOKEN = keccak256("EXCHANGE_TOKEN");

    address public governanceTokenAddress;
    address public exchangeTokenAddress;

    event GOVShareDistributed(address indexed to, uint256 amount);
    event EXCShareDistributed(address indexed to, uint256 amount);

    struct Shares {
        uint256 amount;
        address target;
        bytes32 typeOfToken;
    }

    constructor(address _govTokenAddress, address _exchangeTokenAddress)
        payable
    {
        exchangeTokenAddress = _exchangeTokenAddress;
        governanceTokenAddress = _govTokenAddress;
    }

    function _setupShares(Shares[] memory _shares) public onlyOwner {
        IERC20 govToken = IERC20(governanceTokenAddress);
        IERC20 exchangeToken = IERC20(exchangeTokenAddress);
        for (uint256 i = 0; i < _shares.length; i++) {
            if (_shares[i].typeOfToken == GOV_TOKEN) {
                bool _success = govToken.approve(
                    _shares[i].target,
                    _shares[i].amount
                );
            } else if (_shares[i].typeOfToken == EXCHANGE_TOKEN) {
                bool _success = exchangeToken.approve(
                    _shares[i].target,
                    _shares[i].amount
                );
            }
        }
    }

    receive() external payable {
        require(msg.sender == owner(), "Owner cannot send ETH to the contract");
    }

    function exchangeTokenToCurrency(address to, uint256 amount)
        public
        onlyOwner
    {
        IERC20 exchangeToken = IERC20(exchangeTokenAddress);
        exchangeToken.transferFrom(to, address(this), amount);
        payable(to).transfer(convertToCurrency(amount));
    }

    function convertToCurrency(uint256 amount) public view returns (uint256) {
        return
            (amount * address(this).balance) /
            IERC20(exchangeTokenAddress).balanceOf(address(this));
    }
}
