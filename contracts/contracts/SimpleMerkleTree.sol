// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Poseidon2/Poseidon2.sol";

import "./verifiers/contract.sol";

import "hardhat/console.sol";

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

    constructor(uint32 _levels, address _noteVerifier) {
        require(_levels > 0, "_levels should be greater than zero");
        require(_levels < 32, "_levels should be less than 32");
        levels = _levels;

        roots[0] = ZERO_VALUE;

        poseidon2Hasher = new Poseidon2();
        noteVerifier = UltraVerifier(_noteVerifier);
    }

    function verifyProof(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) public view returns (bool) {
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

    function compareHashes(
        uint256 x,
        uint256 y
    ) public returns (bytes32, bytes32, uint256, uint256) {
        // Measure gas for keccak256
        uint256 startGas = gasleft();
        bytes32 keccakHash = keccak256(abi.encodePacked(x, y));
        uint256 keccakGas = startGas - gasleft();
        console.log("Keccak gas used:", keccakGas);

        // Measure gas for poseidon2
        startGas = gasleft();
        uint256 poseidonResult = poseidon2Hasher
            .hash_2(uint256(x).toField(), uint256(y).toField())
            .toUint256();
        bytes32 poseidonHash = bytes32(poseidonResult);
        uint256 poseidonGas = startGas - gasleft();
        console.log("Poseidon gas used:", poseidonGas);

        return (keccakHash, poseidonHash, keccakGas, poseidonGas);
    }

    event LeafAdded(uint256 indexed leafIndex, bytes32 indexed leaf);

    function _deposit(bytes32 leaf) internal {
        uint256 index = _insert(leaf);
        emit LeafAdded(index, leaf);
    }

    struct InputNote {
        bytes32 nullifier;
        bytes32 root;
    }
    struct OutputNote {
        bytes32 leaf;
        uint256 external_amount;
    }

    function _transact(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs,
        InputNote calldata inputNote,
        OutputNote[] calldata outputNotes
    ) internal {
        require(!nullifierUsed[inputNote.nullifier], "Nullifier used");

        // run the proof here
        verifyProof(_proof, _publicInputs);

        for (uint256 i = 0; i < outputNotes.length; i++) {
            // we need to verify this root
            uint256 index = _insert(outputNotes[i].leaf);
            emit LeafAdded(index, outputNotes[i].leaf);
        }
        nullifierUsed[inputNote.nullifier];
    }

    function zeros(uint256 i) public pure returns (bytes32) {
        if (i == 4) {
            return
                bytes32(
                    0x010185aeae0f692bb0c289bed20658067d4cd55800d95b3a2d25d9696dc92d9a
                );
        }
        if (i == 3) {
            return
                bytes32(
                    0x154d4ad9f6ec7b100aa165d72d5068613d2c3129bb19a54fff82850f8cf0a464
                );
        }
        if (i == 2) {
            return
                bytes32(
                    0x0bb7701b39c1ba621c04938017d07e70baeae094fbbf80606b978030ce78453e
                );
        }
        if (i == 1) {
            return
                bytes32(
                    0x1c936490f40b64fcb00e7b92a9a3cf68933465ec4d0a2fb7f1442c82810b894d
                );
        }
        if (i == 0) {
            return
                bytes32(
                    0x0124e2a36fa18ec18993d7a281e8270ac93340ccf0785ab75e18cc3f4f74296c
                );
        }

        return bytes32(0);
    }

    function _insert(bytes32 leaf) internal returns (uint32 index) {
        uint32 current_index = nextIndex;
        require(current_index != 2 ** (levels - 1), "Merkle tree is full");

        bytes32 current_level_hash = leaf;
        bytes32 left;
        bytes32 right;

        for (uint256 i = 0; i < levels; i++) {
            if (current_index % 2 == 0) {
                left = current_level_hash;
                right = zeros(i);

                filledSubtrees[i] = current_level_hash;
            } else {
                left = filledSubtrees[i];
                right = current_level_hash;
            }

            current_level_hash = hashLeftRight(left, right);

            current_index /= 2;
        }

        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = current_level_hash;
        nextIndex = current_index + 1;
        console.log(nextIndex);
        console.logBytes32(current_level_hash);
        return nextIndex;
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
