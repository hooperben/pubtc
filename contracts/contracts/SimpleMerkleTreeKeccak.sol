// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./verifiers/contract.sol";

import "hardhat/console.sol";

contract SimpleMerkleTree {
    uint256 public depth; // Depth of the Merkle tree
    bytes32[] public nodes; // Array representing the entire tree nodes
    uint256 public nextLeafIndex = 0; // Tracks where the next leaf should go
    uint256 public maxLeaves; // Maximum leaves based on depth

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

    function keccakHashTest(
        uint256 x,
        uint256 y
    ) public view returns (bytes32) {
        console.logBytes(abi.encodePacked(x, y));
        bytes32 test_hash = keccak256(abi.encodePacked(x, y));
        // .hash_2(uint256(x).toField(), uint256(y).toField())
        // .toUint256();

        return test_hash;
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
                    0x1eaa70c243de9a7a453b65e388655c43b646833440c79bce232f1726b4e88c0a
                );
        }
        if (i == 3) {
            return
                bytes32(
                    0x2c692f37fcee439fca4e75b11a9733d0c400ec71504874af418ca7539cb9a3ef
                );
        }
        if (i == 2) {
            return
                bytes32(
                    0x632ee21698d3f67d6f130e2f810680e484fd4a212d59c489498616f08eaf3af8
                );
        }
        if (i == 1) {
            return
                bytes32(
                    0x7aae10b7f5d71c0ef964acd0e2345cacbe6cfe63fb1250fba51ee7b24bd2477c
                );
        }
        if (i == 0) {
            return
                bytes32(
                    0xff75bed8157875f8473157742dc4636c47c3db82be9ab886a27c64ff04e7606d
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

        return keccak256(abi.encodePacked([uint256(_left), uint256(_right)]));
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
