import { expect } from "chai";
import { PUBTC } from "../typechain-types";
import { Wallet } from "ethers";
import { MerkleTree } from "merkletreejs";
import { getTestingAPI, loadPoseidon } from "../helpers";
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import { Noir } from "@noir-lang/noir_js";

describe("Merkle Tree Test", function () {
  let simpleMerkleTree: PUBTC;

  let alice: Wallet;
  let bob: Wallet;
  let charlie: Wallet;

  let poseidon2Hash: any;

  let poseidonNoir: Noir;
  let poseidonBackend: BarretenbergBackend;

  before(async () => {
    ({ alice, bob, charlie, simpleMerkleTree, poseidonNoir, poseidonBackend } =
      await getTestingAPI());

    poseidon2Hash = await loadPoseidon();
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

    const bobPrivateKey =
      BigInt(bob.privateKey) %
      21888242871839275222246405745257275088548364400416034343698204186575808495617n;
    const bobPosAddress = poseidon2Hash([bobPrivateKey]);

    const charliePrivateKey =
      BigInt(charlie.privateKey) %
      21888242871839275222246405745257275088548364400416034343698204186575808495617n;
    const charliePosAddress = poseidon2Hash([charliePrivateKey]);

    const btcAssetId = 69_57_420n;

    // First Transaction
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

    // deposit
    tree.updateLeaf(0, inputNoteHashes[0]);
    const firstRoot = "0x" + tree.getRoot().toString("hex");
    await simpleMerkleTree.deposit(inputNoteHashes[0], { value: 50n });
    expect(await simpleMerkleTree.isKnownRoot(firstRoot)).to.be.true;

    const proof = tree.getProof(inputNoteHashes[0]).map((step) => {
      return {
        path: step.position === "right" ? 1 : 0,
        value: step.data.toString("hex"),
      };
    });

    // transfer 40 to bob from alice
    tree.updateLeaf(1, outputNoteHashes[0]);
    const outputRoot1 = "0x" + tree.getRoot().toString("hex");

    const outputRoot2 = "0x" + tree.getRoot().toString("hex");

    const nullifierHash = poseidon2Hash([0, alicePrivateKey, 50, btcAssetId]);

    const paths = proof.map((x) => x.path);
    const values = proof.map((x) => "0x" + x.value);

    const input = {
      privateKey: "0x" + alicePrivateKey.toString(16), // Changed privateKey to private_key
      root: firstRoot,
      nullifier: nullifierHash.toString(16),
      inputNote: {
        address: alicePosAddress.toString(16),
        amount: 50,
        asset_id: 6957420,
        leafIndex: 0,
        path: paths,
        path_data: values,
      },
      outputNotes: [
        {
          amount: 10,
          asset_id: 69_57_420,
          owner: alicePosAddress.toString(16),
          external_amount: 0,
        },
        {
          amount: 40,
          asset_id: 69_57_420,
          owner: bobPosAddress.toString(),
          external_amount: 0,
        },
      ],
    };

    // generate our zk proof
    const { witness } = await poseidonNoir.execute(input);
    const zkProof = await poseidonBackend.generateProof(witness);

    // submit our transaction
    await simpleMerkleTree.transfer(
      zkProof.proof,
      zkProof.publicInputs,
      {
        nullifier: nullifierHash.toString(),
        root: outputRoot1,
      },
      outputNoteHashes.map((hash, i) => ({
        leaf: hash,
        external_amount: 0,
      })),
    );

    // now, as Bob we should able to send 40 BTC to Charlie
    const b2cInputNotes = [[bobPosAddress, 10n, btcAssetId]];
    const b2cOutputNotes = [
      [bobPosAddress, 1n, btcAssetId],
      [charliePosAddress, 9n, btcAssetId],
    ];

    const b2cInputNoteHashes = b2cInputNotes.map((note) =>
      poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
    );

    const b2cOutputNoteHashes = b2cOutputNotes.map((note) =>
      poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
    );

    const b2cProof = tree.getProof(b2cInputNoteHashes[0]).map((step) => {
      return {
        path: step.position === "right" ? 1 : 0,
        value: step.data.toString("hex"),
      };
    });

    const b2cNullifierHash = poseidon2Hash([1, bobPrivateKey, 10n, btcAssetId]);

    const b2cPaths = b2cProof.map((x) => x.path);
    const b2cValues = b2cProof.map((x) => "0x" + x.value);

    const b2c2NoteRoot = "0x" + tree.getRoot().toString("hex");

    const b2CInput = {
      privateKey: "0x" + bobPrivateKey.toString(16), // Changed privateKey to private_key
      root: b2c2NoteRoot,
      nullifier: b2cNullifierHash.toString(16),
      inputNote: {
        address: bobPosAddress.toString(16),
        amount: 10,
        asset_id: 6957420,
        leafIndex: 1,
        path: b2cPaths,
        path_data: b2cValues,
      },
      outputNotes: [
        {
          amount: 1,
          asset_id: 69_57_420,
          owner: bobPosAddress.toString(16),
          external_amount: 0,
        },
        {
          amount: 9,
          asset_id: 69_57_420,
          owner: charliePosAddress.toString(),
          external_amount: 0,
        },
      ],
    };

    // generate our zk proof
    const { witness: b2cWitness } = await poseidonNoir.execute(b2CInput);
    const b2cZKProof = await poseidonBackend.generateProof(b2cWitness);

    // submit our transaction
    await simpleMerkleTree.transfer(
      b2cZKProof.proof,
      b2cZKProof.publicInputs,
      {
        nullifier: b2cNullifierHash.toString(),
        root: b2c2NoteRoot,
      },
      b2cOutputNoteHashes.map((hash, i) => ({
        leaf: hash,
        external_amount: 0,
      })),
    );

    tree.updateLeaf(3, b2cOutputNoteHashes[0]);
    tree.updateLeaf(4, b2cOutputNoteHashes[1]); // charlie

    const withdrawalNullifierHash = poseidon2Hash([
      4,
      charliePrivateKey,
      9n,
      btcAssetId,
    ]);

    const withdrawalProof = tree
      .getProof(b2cOutputNoteHashes[1])
      .map((step) => {
        return {
          path: step.position === "right" ? 1 : 0,
          value: step.data.toString("hex"),
        };
      });

    const withdrawalPaths = withdrawalProof.map((x) => x.path);
    const withdrawalValues = withdrawalProof.map((x) => "0x" + x.value);
    const withdrawalRoot = "0x" + tree.getRoot().toString("hex");

    const withdrawalOutputNotes = [
      {
        amount: 5,
        asset_id: 6957420,
        owner: 0n,
        external_amount: 5,
      },
      {
        amount: 4,
        asset_id: 6957420,
        owner: charliePosAddress.toString(),
        external_amount: 0,
      },
    ];

    const withdrawalOutputNoteHashes = withdrawalOutputNotes.map((note) =>
      poseidon2Hash([
        BigInt(note.owner),
        note.amount,
        note.asset_id,
      ]).toString(),
    );

    // charlie is going to be withdrawing
    const withdrawalInput = {
      privateKey: "0x" + charliePrivateKey.toString(16), // Changed privateKey to private_key
      root: withdrawalRoot,
      nullifier: withdrawalNullifierHash.toString(16),
      inputNote: {
        address: charliePosAddress.toString(16),
        amount: 9,
        asset_id: 6957420,
        leafIndex: 4,
        path: withdrawalPaths,
        path_data: withdrawalValues,
      },
      outputNotes: [
        {
          amount: 5,
          asset_id: 6957420,
          owner:
            "0x84cf1c96ee76f15cbfeb1e2eaf55413059e78b501728133facb4664277dead",
          external_amount: 5,
        },
        {
          amount: 4,
          asset_id: 6957420,
          owner: charliePosAddress.toString(),
          external_amount: 0,
        },
      ],
    };

    // generate our zk proof
    const { witness: withdrawalWitness } = await poseidonNoir.execute(
      withdrawalInput,
    );
    const withdrawalZKProof = await poseidonBackend.generateProof(
      withdrawalWitness,
    );

    await simpleMerkleTree.withdraw(
      withdrawalZKProof.proof,
      withdrawalZKProof.publicInputs,
      {
        nullifier: withdrawalNullifierHash.toString(),
        root: withdrawalRoot,
      },
      withdrawalOutputNoteHashes.map((hash, i) => ({
        leaf: hash,
        external_amount: i === 0 ? 5 : 0,
      })),
      charlie.address,
    );
  });

  it("testing hash gas cost dif", async () => {
    await simpleMerkleTree.compareHashes(12341241n, 12341241n);
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
