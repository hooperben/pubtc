// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {NotesVerifier} from "./verifiers/NotesVerifier.sol";
import {DepositVerifier} from "./verifiers/DepositVerifier.sol";

import "hardhat/console.sol";

contract SimpleMerkleTree {
    uint256 public depth; // Depth of the Merkle tree
    bytes32[] public nodes; // Array representing the entire tree nodes
    uint256 public nextLeafIndex = 0; // Tracks where the next leaf should go
    uint256 public maxLeaves; // Maximum leaves based on depth

    uint32 public immutable levels; // 5

    NotesVerifier public notesVerifier;
    DepositVerifier public depositVerifier;

    // keccak256("PRIVATE_UNSTOPPABLE_BITCOIN")
    bytes32 public constant EMPTY_NOTE =
        0xe1bc205401da5e8e8e271e396cdfeb53e574c19af66ffa65e47fad18a61e8fb7;
    bytes32 public constant INITIAL_ROOT =
        0x4bae24af03a38508f27c9d5b1ca655a57408c047f8ad0e250b61eae68ad21e48;

    // root hash of merkle tree with 32 leaves as EMPTY_NOTE
    uint256 public constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
    // it removes index range check on every interaction
    mapping(uint256 => bytes32) public filledSubtrees;
    mapping(uint256 => bytes32) public roots;

    mapping(bytes32 => bool) public nullifierUsed;

    uint32 public constant ROOT_HISTORY_SIZE = 100;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;

    constructor(
        uint32 _levels,
        address _noteVerifier,
        address _depositVerifier
    ) {
        require(_levels > 0, "_levels should be greater than zero");
        require(_levels < 32, "_levels should be less than 32");
        levels = _levels;

        roots[0] = INITIAL_ROOT;

        notesVerifier = NotesVerifier(_noteVerifier);
        depositVerifier = DepositVerifier(_depositVerifier);
    }

    function verifyTransactProof(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) public view {
        bool validProof = notesVerifier.verify(_proof, _publicInputs);
        require(validProof, "Invalid transact proof :(");
    }

    function verifyDepositProof(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) public view {
        bool validProof = depositVerifier.verify(_proof, _publicInputs);
        require(validProof, "Invalid deposit proof :(");
    }

    event LeafAdded(uint256 indexed leafIndex, bytes32 indexed leaf);

    function _deposit(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs,
        bytes32 leaf
    ) internal {
        verifyDepositProof(_proof, _publicInputs);

        uint256 index = _insert(leaf);
        emit LeafAdded(index, leaf);
    }

    function _transact(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs,
        uint256[] calldata _externalAmounts,
        bytes32[] calldata _nullifiers,
        bytes32[] calldata _outputHashes
    ) internal {
        // run the proof here
        verifyTransactProof(_proof, _publicInputs);

        for (uint256 i = 0; i < _externalAmounts.length; i++) {
            require(!nullifierUsed[_nullifiers[i]], "Nullifier already used");

            // Process each external amount
            uint256 externalAmount = _externalAmounts[i];
            // You can add your logic here to handle each external amount
            console.log("Processing external amount: ", externalAmount);

            nullifierUsed[_nullifiers[i]] = true;

            // we need to verify this root
            uint256 index = _insert(_outputHashes[i]);
            emit LeafAdded(index, _outputHashes[i]);
        }
    }

    function zeros(uint256 i) public pure returns (bytes32) {
        if (i == 4) {
            return
                bytes32(
                    0x07f85f95046d647f8fca47046b80ef9448548c979789772bcbe1d42269526e79
                );
        }
        if (i == 3) {
            return
                bytes32(
                    0x3ae7775d26be7cfcfb6c0ca5cbaec4c3bc5aea6ea368de89cf8eefcf1fa6bae4
                );
        }
        if (i == 2) {
            return
                bytes32(
                    0x1dca0d498d0392985f12e22232480653178bb13791878621d726132f58832cc6
                );
        }
        if (i == 1) {
            return
                bytes32(
                    0xb6b9b6b71111b8b9350178e20a8fa629da76f99efe14b8511c3f6e8c00656212
                );
        }
        if (i == 0) {
            return
                bytes32(
                    0xe1bc205401da5e8e8e271e396cdfeb53e574c19af66ffa65e47fad18a61e8fb7
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

        return nextIndex;
    }

    function hashLeftRight(
        bytes32 _left,
        bytes32 _right
    ) public pure returns (bytes32) {
        // require(
        //     uint256(_left) < FIELD_SIZE,
        //     "_left should be inside the field"
        // );
        // require(
        //     uint256(_right) < FIELD_SIZE,
        //     "_right should be inside the field"
        // );

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
