import { ethers } from "hardhat";
import { scriptHelper } from "../helpers/script-helper";

async function main() {
  const [signer] = await ethers.getSigners();

  const {
    PUTBTC,
    poseidon2Hash,
    tree,
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
    btcAssetId,
    noir,
    backend,
  } = await scriptHelper();

  // update our tree with our deposit tx
  const depositInputNotes = [[alicePosAddress, 69420n, btcAssetId]];
  const depositInputNoteHashes = depositInputNotes.map((note) =>
    poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
  );
  tree.updateLeaf(0, depositInputNoteHashes[0]);

  // update our tree after first transfer
  const a2bOutputNotes = [
    [alicePosAddress, 69000n, btcAssetId],
    [bobPosAddress, 420n, btcAssetId],
  ];
  const a2bOutputNoteHashes = a2bOutputNotes.map((note) =>
    poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
  );
  tree.updateLeaf(1, a2bOutputNoteHashes[0]);
  tree.updateLeaf(2, a2bOutputNoteHashes[1]);

  // update our tree after second transfer
  const b2cOutputNotes = [
    [bobPosAddress, 351n, btcAssetId],
    [charliePosAddress, 69n, btcAssetId],
  ];
  const b2cOutputNoteHashes = b2cOutputNotes.map((note) =>
    poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
  );
  tree.updateLeaf(3, b2cOutputNoteHashes[0]);
  const charlieInputNote = b2cOutputNoteHashes[1];
  tree.updateLeaf(4, charlieInputNote);

  const updatedRoot = "0x" + tree.getRoot().toString("hex");

  const nullifierHash = poseidon2Hash([4, charliePrivateKey, 69, btcAssetId]);

  const proof = tree.getProof(charlieInputNote).map((step) => {
    return {
      path: step.position === "right" ? 1 : 0,
      value: step.data.toString("hex"),
    };
  });
  const paths = proof.map((x) => x.path);
  const values = proof.map((x) => "0x" + x.value);

  const withdrawalInput = {
    privateKey: "0x" + charliePrivateKey.toString(16), // Changed privateKey to private_key
    root: updatedRoot,
    nullifier: nullifierHash.toString(16),
    inputNote: {
      address: charliePosAddress.toString(16),
      amount: 69,
      asset_id: 6957420,
      leafIndex: 4,
      path: paths,
      path_data: values,
    },
    outputNotes: [
      {
        amount: 24,
        asset_id: 6957420,
        owner:
          "0x84cf1c96ee76f15cbfeb1e2eaf55413059e78b501728133facb4664277dead", // DEAD address
        external_amount: 24,
      },
      {
        amount: 45,
        asset_id: 6957420,
        owner: charliePosAddress.toString(),
        external_amount: 0,
      },
    ],
  };

  const { witness: withdrawalWitness } = await noir.execute(withdrawalInput);
  const withdrawalZKProof = await backend.generateProof(withdrawalWitness);

  const withdrawalOutputNotes = [
    {
      amount: 24,
      asset_id: 6957420,
      owner: "0x84cf1c96ee76f15cbfeb1e2eaf55413059e78b501728133facb4664277dead", // DEAD address
      external_amount: 24,
    },
    {
      amount: 45,
      asset_id: 6957420,
      owner: charliePosAddress.toString(),
      external_amount: 0,
    },
  ];

  const withdrawalOutputNoteHashes = withdrawalOutputNotes.map((note) =>
    poseidon2Hash([BigInt(note.owner), note.amount, note.asset_id]).toString(),
  );

  const tx = await PUTBTC.withdraw(
    withdrawalZKProof.proof,
    withdrawalZKProof.publicInputs,
    {
      nullifier: nullifierHash.toString(),
      root: updatedRoot,
    },
    withdrawalOutputNoteHashes.map((hash, i) => ({
      leaf: hash,
      external_amount: i === 0 ? 24 : 0,
    })),
    charlie.address,
  );

  console.log(tx);

  console.log(charlie.address);

  // await tx.wait();

  console.log("done!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
