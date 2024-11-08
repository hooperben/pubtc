// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import "hardhat/console.sol";

import "./SimpleMerkleTree.sol";

contract PUBTC is SimpleMerkleTree {
    constructor(
        uint32 _levels,
        address _noteVerifier
    ) SimpleMerkleTree(_levels, _noteVerifier) {}

    function deposit(bytes32 leaf) public payable override {
        super.deposit(leaf);
    }

    function withdraw(uint256 amount) public {
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send ETH");
    }

    receive() external payable {
        revert("Direct ETH transfers not supported");
    }

    fallback() external payable {
        revert("Function not found");
    }
}
