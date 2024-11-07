import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { SimpleMerkleTree } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { Wallet } from "ethers";

// Create a wrapper function that uses dynamic import
const loadPoseidon = async () => {
  // Use Function constructor to avoid CommonJS static analysis
  const importModule = new Function(
    'return import("@aztec/foundation/crypto")',
  );
  const module = await importModule();
  return module.poseidon2Hash;
};

describe("Merkle Tree Test", function () {
  let simpleMerkleTree: SimpleMerkleTree;

  let alice: Wallet;
  let bob: Wallet;

  before(async () => {
    const [funder] = await hre.ethers.getSigners();

    const alice_private_key =
      "0x91b1ba753a83576e85b0bc41b3335e58a8f5a064bd4379c70b5295221277aa8e";
    const bob_private_key =
      "0x04b84dc399d3384bc4b7d5e88567160a897e0cd1bb382713c4db0f4a95d1825f";

    alice = new ethers.Wallet(alice_private_key, hre.ethers.provider);
    bob = new ethers.Wallet(bob_private_key, hre.ethers.provider);

    // Fund alice and bob with 10 ETH each
    await funder.sendTransaction({
      to: alice.address,
      value: ethers.parseEther("10.0"),
    });

    await funder.sendTransaction({
      to: bob.address,
      value: ethers.parseEther("10.0"),
    });

    expect(alice.privateKey).equal(BigInt(alice_private_key));
    expect(bob.privateKey).equal(BigInt(bob_private_key));

    const SimpleMerkleTree = await hre.ethers.getContractFactory(
      "SimpleMerkleTree",
    );
    simpleMerkleTree = await SimpleMerkleTree.deploy(5);
  });

  it("should run", async () => {
    const initialNote = {
      amount: 50n,
    };
  });

  it("poseidon solidity test", async () => {
    const test = await simpleMerkleTree.poseidonHash2(12341241n, 12341241n);

    expect(test).eql(
      "0x0dd8218a93222c13ac6228d4190bc19d01234b5f99e33cc43a16cc0db0759e57",
    );
  });

  it("poseidon ts test", async () => {
    const poseidon2Hash = await loadPoseidon();
    // // in noir:
    // println(poseidon2::Poseidon2::hash([12341241, 12341241], 2));
    const test = await poseidon2Hash([12341241n, 12341241n]).toString();

    expect(test).eql(
      "0x0dd8218a93222c13ac6228d4190bc19d01234b5f99e33cc43a16cc0db0759e57",
    );
  });
});
