// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Poseidon2/Poseidon2.sol";

import "hardhat/console.sol";

interface UltraVerifier {
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external view returns (bool);
}

contract SimpleMerkleTree {
    using Field for *;

    uint256 public depth; // Depth of the Merkle tree
    bytes32[] public nodes; // Array representing the entire tree nodes
    uint256 public nextLeafIndex = 0; // Tracks where the next leaf should go
    uint256 public maxLeaves; // Maximum leaves based on depth

    Poseidon2 poseidon2Hasher;
    uint32 public immutable levels;

    UltraVerifier public noteVerifier;

    bytes32 EMPTY_NOTE =
        0x0124e2a36fa18ec18993d7a281e8270ac93340ccf0785ab75e18cc3f4f74296c;
    uint256 public constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    bytes32 ZERO_VALUE =
        0x2a3b7d44e9164f5e90a2a1675849ef1e3f6fb923463b69308593e27710f5dfb8;

    // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
    // it removes index range check on every interaction
    mapping(uint256 => bytes32) public filledSubtrees;
    mapping(uint256 => bytes32) public roots;

    mapping(bytes32 => bool) public nullifierUsed;

    uint32 public constant ROOT_HISTORY_SIZE = 100;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;

    function deployFromBytecode(
        bytes memory bytecode
    ) public returns (address) {
        address child;
        assembly {
            mstore(0x0, bytecode)
            child := create(0, 0xa0, calldatasize())
        }
        return child;
    }

    constructor(uint32 _levels, bytes memory bytecode) {
        require(_levels > 0, "_levels should be greater than zero");
        require(_levels < 32, "_levels should be less than 32");
        levels = _levels;

        roots[0] = ZERO_VALUE;

        poseidon2Hasher = new Poseidon2();
        noteVerifier = UltraVerifier(deployFromBytecode(bytecode));
    }

    function verifyProof(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs // [root, nullifier, receiver]
    ) public view returns (bool) {
        // check their proof against our verifier contract
        bool validProof = noteVerifier.verify(_proof, _publicInputs);
        require(validProof, "Invalid proof :(");

        return true;
    }

    function poseidonHash2(uint256 x, uint256 y) public view returns (bytes32) {
        uint256 test_hash = poseidon2Hasher
            .hash_2(uint256(x).toField(), uint256(y).toField())
            .toUint256();

        return bytes32(test_hash);
    }

    event LeafAdded(uint256 indexed leafIndex, bytes32 indexed leaf);

    function deposit(
        // bytes32 owner,
        // uint256 amount,
        // uint256 asset,
        bytes32 leaf,
        bytes32 newRoot
    ) public {
        uint256 index = _insert(leaf, newRoot);
        emit LeafAdded(index, leaf);
    }

    struct InputNote {
        bytes32 nullifier;
        bytes32 root;
    }
    struct OutputNote {
        bytes32 leaf;
        bytes32 root;
    }

    function transact(
        InputNote calldata inputNote,
        OutputNote[] calldata outputNotes
    ) public {
        require(!nullifierUsed[inputNote.nullifier], "Nullifier used");

        // run the proof here

        for (uint256 i = 0; i < outputNotes.length; i++) {
            uint256 index = _insert(outputNotes[i].leaf, outputNotes[i].root);
            emit LeafAdded(index, outputNotes[i].leaf);
        }
        nullifierUsed[inputNote.nullifier];
    }

    function _insert(
        bytes32,
        bytes32 _newRoot
    ) internal returns (uint32 index) {
        uint32 _nextIndex = nextIndex;
        require(_nextIndex != uint32(2) ** levels, "Merkle tree is full");

        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = _newRoot;
        nextIndex = _nextIndex + 1;
        return _nextIndex;
    }

    function hashLeftRight(
        bytes32 _left,
        bytes32 _right
    ) public view returns (bytes32) {
        require(
            uint256(_left) < FIELD_SIZE,
            "_left should be inside the field"
        );
        require(
            uint256(_right) < FIELD_SIZE,
            "_right should be inside the field"
        );

        return poseidonHash2(uint256(_left), uint256(_right));
    }

    /**
      @dev Whether the root is present in the root history
    */
    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }
        uint32 _currentRootIndex = currentRootIndex;
        uint32 i = _currentRootIndex;
        do {
            if (_root == roots[i]) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != _currentRootIndex);
        return false;
    }

    /**
      @dev Returns the last root
    */
    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }
}
