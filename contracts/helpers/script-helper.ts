import { ethers } from "hardhat";
import { loadPoseidon } from "../helpers";

export const scriptHelper = async () => {
  const poseidon2Hash = await loadPoseidon();

  const alice_private_key =
    "0x91b1ba753a83576e85b0bc41b3335e58a8f5a064bd4379c70b5295221277aa8e";
  const bob_private_key =
    "0x04b84dc399d3384bc4b7d5e88567160a897e0cd1bb382713c4db0f4a95d1825f";
  const charlie_private_key =
    "0x58409f99febb8326dff7fd504d8dd1978a26c00af8029754d83948b0e88b8362";

  const alicePrivateKey =
    BigInt(alice_private_key) %
    21888242871839275222246405745257275088548364400416034343698204186575808495617n;
  const alicePosAddress = poseidon2Hash([alicePrivateKey]);

  const bobPrivateKey =
    BigInt(bob_private_key) %
    21888242871839275222246405745257275088548364400416034343698204186575808495617n;
  const bobPosAddress = poseidon2Hash([bobPrivateKey]);

  const charliePrivateKey =
    BigInt(charlie_private_key) %
    21888242871839275222246405745257275088548364400416034343698204186575808495617n;
  const charliePosAddress = poseidon2Hash([charliePrivateKey]);

  const alice = new ethers.Wallet(alice_private_key, ethers.provider);
  const bob = new ethers.Wallet(bob_private_key, ethers.provider);
  const charlie = new ethers.Wallet(charlie_private_key, ethers.provider);

  return {
    poseidon2Hash,
    alice_private_key,
    bob_private_key,
    charlie_private_key,
    alicePrivateKey,
    alicePosAddress,
    bobPrivateKey,
    bobPosAddress,
    charliePrivateKey,
    charliePosAddress,
    alice,
    bob,
    charlie,
  };
};
