// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "hardhat/console.sol";

import "./MASP.sol";

contract PUBTC is SimpleMerkleTree {
    constructor(
        uint32 _levels,
        address _noteVerifier,
        address _depositVerifier
    ) SimpleMerkleTree(_levels, _noteVerifier, _depositVerifier) {}

    function convertToUint256(
        bytes32[] memory _publicInputs,
        uint start,
        uint end
    ) internal pure returns (uint256) {
        uint256 amount;
        for (uint i = start; i < end; i++) {
            amount |=
                uint256(uint8(uint256(_publicInputs[i]))) <<
                (248 - (i - start) * 8);
        }
        return amount;
    }

    function endsWith(bytes32 data, uint256 value) public pure returns (bool) {
        for (uint256 i = 0; i < 32; i++) {
            uint8 dataByte = uint8(data[31 - i]);
            uint8 valueByte = uint8(value >> (i * 8));
            if (dataByte != valueByte) {
                return false;
            }
        }

        return true;
    }

    function fullArrayConversion(
        bytes32[] calldata _publicInputs
    ) public payable {
        bytes1[] memory recon = new bytes1[](32);
        bytes memory tester = new bytes(32);

        uint256 full = 0;

        for (uint i = 0; i < 32; i++) {
            bytes1 rightmostByte = _publicInputs[i][31];

            recon[i] = rightmostByte;
            console.logBytes1(rightmostByte);

            // full = full + uint256(rightmostByte) * 10 ** 31 - i;
            // full = full * 10 + uint256(rightmostByte);

            // console.log(uint256(rightmostByte));
        }

        console.log(full);
        // for (uint i = 0; i < 32; i++) {
        // console.logBytes(abi.encodePacked("1", "2"));
        // }
        // console.log(reconUint256);

        console.log(msg.value);
    }

    function deposit(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs,
        bytes32 leaf
    ) public payable {
        require(_publicInputs.length == 64, "Invalid public inputs length");

        bytes32 reconstructedLeaf;
        bytes32 reconstructedAmount = 0;

        for (uint i = 0; i < 32; i++) {
            reconstructedLeaf |= bytes32(
                uint256(uint8(uint256(_publicInputs[i]))) << (248 - i * 8)
            );
            reconstructedAmount |= bytes32(
                uint256(uint8(uint256(_publicInputs[i + 32]))) << (248 - i * 8)
            );
        }

        console.log(msg.value);
        console.logBytes32(reconstructedAmount);

        uint256 extractedValue = uint256(reconstructedAmount) &
            ((1 << 160) - 1);
        console.log(extractedValue);

        bytes32 msgValueBytes32 = bytes32(uint256(msg.value));
        console.logBytes32(msgValueBytes32);

        require(
            leaf == reconstructedLeaf,
            "Circuit and contract values don't match"
        );
        // TODO
        // require(reconstructedAmount == bytes32(msg.value), "Amount mismatch");

        _deposit(_proof, _publicInputs, leaf);
    }

    function transfer(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs,
        uint256[] calldata _externalAmounts,
        bytes32[] calldata _nullifiers,
        bytes32[] calldata _outputHashes
    ) public {
        _transact(
            _proof,
            _publicInputs,
            _externalAmounts,
            _nullifiers,
            _outputHashes
        );
    }

    function withdraw(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs,
        uint256[] calldata _externalAmounts,
        bytes32[] calldata _nullifiers,
        bytes32[] calldata _outputHashes,
        address _withdrawalAddress // TODO this is front runnable
    ) public {
        _transact(
            _proof,
            _publicInputs,
            _externalAmounts,
            _nullifiers,
            _outputHashes
        );

        for (uint256 i; i < _externalAmounts.length; i++) {
            (bool success, ) = payable(_withdrawalAddress).call{
                value: _externalAmounts[0]
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
