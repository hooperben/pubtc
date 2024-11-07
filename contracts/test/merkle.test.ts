import { expect } from "chai";
import { SimpleMerkleTree } from "../typechain-types";
import { Wallet } from "ethers";
import { MerkleTree } from "merkletreejs";
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

  it("merkle tree changes should track", async () => {
    const emptyNote = poseidon2Hash([BigInt(57_69_240)]).toString();
    const emptyNotes = Array(32).fill(emptyNote);
    const noteHashes = emptyNotes;

    const hasherFn = (input: string) => {
      const [left, right] = [
        input.slice(0, input.length / 2) as unknown as Buffer,
        input.slice(input.length / 2) as unknown as Buffer,
      ];

      const leftBigInt = BigInt("0x" + left.toString("hex"));
      const rightBigInt = BigInt("0x" + right.toString("hex"));

      const hash = poseidon2Hash([leftBigInt, rightBigInt]).toString();
      return hash;
    };

    const tree = new MerkleTree(noteHashes, hasherFn, {
      sort: false,
      complete: true,
    });

    const root = tree.getRoot().toString("hex");

    expect(await simpleMerkleTree.isKnownRoot("0x" + root)).to.be.true;

    const alicePrivateKey =
      BigInt(alice.privateKey) %
      21888242871839275222246405745257275088548364400416034343698204186575808495617n;
    const alicePosAddress = poseidon2Hash([alicePrivateKey]);

    const bobPosAddress = poseidon2Hash([
      BigInt(bob.privateKey) %
        21888242871839275222246405745257275088548364400416034343698204186575808495617n,
    ]);

    const btcAssetId = 69_57_420n;
    const inputNotes = [[alicePosAddress, 50n, btcAssetId]];
    const outputNotes = [
      [bobPosAddress, 10n, btcAssetId],
      [alicePosAddress, 40n, btcAssetId],
    ];

    const inputNoteHashes = inputNotes.map((note) =>
      poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
    );

    const outputNoteHashes = outputNotes.map((note) =>
      poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
    );

    // const proof = tree.getProof(newNoteHashes[0]).map((step) => {
    //   return {
    //     path: step.position === "right" ? 1 : 0,
    //     value: step.data.toString("hex"),
    //   };
    // });

    // const paths = proof.map((x) => x.path);
    // const values = proof.map((x) => x.value);

    // deposit
    tree.updateLeaf(0, inputNoteHashes[0]);
    let newRoot = "0x" + tree.getRoot().toString("hex");
    await simpleMerkleTree.deposit(inputNoteHashes[0], newRoot);
    expect(await simpleMerkleTree.isKnownRoot(newRoot)).to.be.true;

    // transfer 40 to bob from alice
    tree.updateLeaf(1, outputNoteHashes[0]);
    const outputRoot1 = "0x" + tree.getRoot().toString("hex");

    tree.updateLeaf(2, outputNoteHashes[0]);
    const outputRoot2 = "0x" + tree.getRoot().toString("hex");

    const nullifierHash = poseidon2Hash([0, alicePrivateKey, 50, btcAssetId]);
    const tx = await simpleMerkleTree.transact(
      {
        nullifier: nullifierHash.toString(),
        root: outputRoot1,
      },
      outputNoteHashes.map((hash, i) => ({
        leaf: hash,
        root: i === 0 ? outputRoot1 : outputRoot2,
      })),
    );

    console.log(nullifierHash.toString());
    expect(await simpleMerkleTree.isKnownRoot(outputRoot2)).to.be.true;
  });

  it("poseidon sol test", async () => {
    const test = await simpleMerkleTree.poseidonHash2(12341241n, 12341241n);
    expect(test).eql(
      "0x0dd8218a93222c13ac6228d4190bc19d01234b5f99e33cc43a16cc0db0759e57",
    );
  });

  it("poseidon ts test", async () => {
    const test = await poseidon2Hash([12341241n, 12341241n]).toString();

    expect(test).eql(
      "0x0dd8218a93222c13ac6228d4190bc19d01234b5f99e33cc43a16cc0db0759e57",
    );
  });
});
