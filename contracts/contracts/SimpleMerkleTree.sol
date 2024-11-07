// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./Poseidon2/Poseidon2.sol";

import "hardhat/console.sol";

contract SimpleMerkleTree {
    using Field for *;

    uint256 public depth; // Depth of the Merkle tree
    bytes32[] public nodes; // Array representing the entire tree nodes
    uint256 public nextLeafIndex = 0; // Tracks where the next leaf should go
    uint256 public maxLeaves; // Maximum leaves based on depth

    Poseidon2 poseidon2Hasher;

    constructor(uint256 _depth) {
        require(_depth > 0, "Depth must be greater than 0");
        depth = _depth;
        maxLeaves = 2 ** depth;
        nodes = new bytes32[](2 * maxLeaves - 1); // Array to store nodes of the tree

        poseidon2Hasher = new Poseidon2();
    }

    function poseidonHash2(uint256 x, uint256 y) public view returns (bytes32) {
        uint256 test_hash = poseidon2Hasher
            .hash_2(uint256(x).toField(), uint256(y).toField())
            .toUint256();

        return bytes32(test_hash);
    }

    function insert(bytes32 leaf) public {
        require(nextLeafIndex < maxLeaves, "Tree is full");

        // Set the leaf at the correct position
        uint256 leafPos = maxLeaves - 1 + nextLeafIndex;
        nodes[leafPos] = leaf;
        nextLeafIndex++;

        // Update the Merkle tree by recalculating hashes up to the root
        uint256 parentPos = (leafPos - 1) / 2;
        while (parentPos > 0) {
            uint256 leftChild = 2 * parentPos + 1;
            uint256 rightChild = leftChild + 1;
            nodes[parentPos] = keccak256(
                abi.encodePacked(nodes[leftChild], nodes[rightChild])
            );
            parentPos = (parentPos - 1) / 2;
        }

        // Update the root
        nodes[0] = keccak256(abi.encodePacked(nodes[1], nodes[2]));
    }

    function getRoot() public view returns (bytes32) {
        return nodes[0];
    }

    function getNode(uint256 index) public view returns (bytes32) {
        return nodes[index];
    }
}
