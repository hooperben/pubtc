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

    function deposit(bytes32 leaf) public payable {
        _deposit(leaf);
    }

    function transfer(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs,
        InputNote calldata inputNote,
        OutputNote[] calldata outputNotes
    ) public {
        _transact(_proof, _publicInputs, inputNote, outputNotes);
    }

    function withdraw(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs,
        InputNote calldata inputNote,
        OutputNote[] calldata outputNotes,
        address _withdrawalAddress // TODO this is front runnable
    ) public {
        _transact(_proof, _publicInputs, inputNote, outputNotes);

        // TODO need to check output note external amount sum == public inputs sum amount

        for (uint256 i; i < outputNotes.length; i++) {
            (bool success, ) = payable(_withdrawalAddress).call{
                value: outputNotes[0].external_amount
            }("");
            require(success, "Failed to send ETH");
        }
    }

    receive() external payable {
        revert("Direct ETH transfers not supported");
    }

    fallback() external payable {
        revert("Function not found");
    }
}
