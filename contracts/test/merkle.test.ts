import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { SimpleMerkleTree } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { Wallet } from "ethers";
import { getTestingAPI, loadPoseidon } from "../helpers";

describe("Merkle Tree Test", function () {
  let simpleMerkleTree: SimpleMerkleTree;

  let alice: Wallet;
  let bob: Wallet;

  let poseidon2Hash: any;

  before(async () => {
    ({ alice, bob, simpleMerkleTree } = await getTestingAPI());

    poseidon2Hash = await loadPoseidon();

    const aliceBal = await alice.provider?.getBalance(alice.address);
    expect(aliceBal).equal(10000000000000000000n);
  });

  it("should run", async () => {
    const notes = [
      [alice.address, 50n, "BTC"],
      [alice.address, 100n, "BTC"],
      [bob.address, 10n, "BTC"],
      [alice.address, 69n, "BTC"],
    ];

    console.log(notes);

    const noteHashes = notes.map(
      (note) =>
        poseidon2Hash([BigInt(note[0]), note[1], BigInt(123123123)]).toString(), // "BTC" = 123123123
    );

    console.log(noteHashes);
  });

  it("poseidon solidity test", async () => {
    const test = await simpleMerkleTree.poseidonHash2(12341241n, 12341241n);

    expect(test).eql(
      "0x0dd8218a93222c13ac6228d4190bc19d01234b5f99e33cc43a16cc0db0759e57",
    );
  });

  it("poseidon ts test", async () => {
    // // in noir:
    // println(poseidon2::Poseidon2::hash([12341241, 12341241], 2));
    const test = await poseidon2Hash([12341241n, 12341241n]).toString();

    expect(test).eql(
      "0x0dd8218a93222c13ac6228d4190bc19d01234b5f99e33cc43a16cc0db0759e57",
    );
  });
});
