import { ethers } from "hardhat";
import { scriptHelper } from "../helpers/script-helper";

// This script is to be ran after alice transfers bob, and lets
// bob transfer charlie privately
async function main() {
  const [signer] = await ethers.getSigners();

  const {
    PUTBTC,
    poseidon2Hash,
    btcAssetId,
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
    tree,
    noir,
    backend,
  } = await scriptHelper();

  const depositInputNotes = [[alicePosAddress, 69420n, btcAssetId]];
  const depositInputNoteHashes = depositInputNotes.map((note) =>
    poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
  );

  // update our tree rep of the deposit
  tree.updateLeaf(0, depositInputNoteHashes[0]);
  const a2bOutputNotes = [
    [alicePosAddress, 69000n, btcAssetId],
    [bobPosAddress, 420n, btcAssetId],
  ];
  const a2bOutputNoteHashes = a2bOutputNotes.map((note) =>
    poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
  );

  // update our tree after first transfer
  tree.updateLeaf(1, a2bOutputNoteHashes[0]);

  const bobInputNote = a2bOutputNoteHashes[1];
  tree.updateLeaf(2, bobInputNote);

  const updatedRoot = "0x" + tree.getRoot().toString("hex");

  // bob is sending charlie 69 satoshis (he keeps 351)
  const outputNotes = [
    [bobPosAddress, 351n, btcAssetId],
    [charliePosAddress, 69n, btcAssetId],
  ];
  const outputNoteHashes = outputNotes.map((note) =>
    poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
  );

  const nullifierHash = poseidon2Hash([3, bobPrivateKey, 420n, btcAssetId]);
  // generate the merkle proof with the updated tree
  const proof = tree.getProof(bobInputNote).map((step) => {
    return {
      path: step.position === "right" ? 1 : 0,
      value: step.data.toString("hex"),
    };
  });
  const paths = proof.map((x) => x.path);
  const values = proof.map((x) => "0x" + x.value);

  const input = {
    privateKey: "0x" + bobPrivateKey.toString(16), // Changed privateKey to private_key
    root: updatedRoot,
    nullifier: nullifierHash.toString(16),
    inputNote: {
      address: bobPosAddress.toString(16),
      amount: 420n,
      asset_id: 6957420,
      leafIndex: 3,
      path: paths,
      path_data: values,
    },
    outputNotes: [
      {
        amount: 351n,
        asset_id: 69_57_420n,
        owner: bobPosAddress.toString(16),
        external_amount: 0,
      },
      {
        amount: 69n,
        asset_id: 69_57_420n,
        owner: charliePosAddress.toString(16),
        external_amount: 0,
      },
    ],
  };

  // generate our zk proof
  const { witness } = await noir.execute({
    privateKey: input.privateKey,
    root: input.root,
    nullifier: input.nullifier,
    inputNote: {
      address: input.inputNote.address,
      amount: Number(input.inputNote.amount),
      asset_id: input.inputNote.asset_id,
      leafIndex: input.inputNote.leafIndex,
      path: input.inputNote.path,
      path_data: input.inputNote.path_data,
    },
    outputNotes: input.outputNotes.map((note) => ({
      amount: Number(note.amount),
      asset_id: Number(note.asset_id),
      owner: note.owner,
      external_amount: note.external_amount,
    })),
  });
  const zkProof = await backend.generateProof(witness);

  // submit our transaction
  const tx = await PUTBTC.transfer(
    zkProof.proof,
    zkProof.publicInputs,
    {
      nullifier: nullifierHash.toString(),
      root: updatedRoot,
    },
    outputNoteHashes.map((hash, i) => ({
      leaf: hash,
      external_amount: 0,
    })),
  );

  console.log(tx);

  await tx.wait();

  console.log("done!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
