import { ethers } from "hardhat";
import { scriptHelper } from "../helpers/script-helper";

// This script is to be ran after alice deposits, and lets
// alice transfer bob privately
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

  tree.updateLeaf(0, depositInputNoteHashes[0]);

  const updatedRoot = "0x" + tree.getRoot().toString("hex");

  // generate the merkle proof with the updated tree
  const proof = tree.getProof(depositInputNoteHashes[0]).map((step) => {
    return {
      path: step.position === "right" ? 1 : 0,
      value: step.data.toString("hex"),
    };
  });

  const nullifierHash = poseidon2Hash([0, alicePrivateKey, 69420n, btcAssetId]);
  const paths = proof.map((x) => x.path);
  const values = proof.map((x) => "0x" + x.value);

  const input = {
    privateKey: "0x" + alicePrivateKey.toString(16), // Changed privateKey to private_key
    root: updatedRoot,
    nullifier: nullifierHash.toString(16),
    inputNote: {
      address: alicePosAddress.toString(16),
      amount: 69420n,
      asset_id: 6957420,
      leafIndex: 0,
      path: paths,
      path_data: values,
    },
    outputNotes: [
      {
        amount: 69000n,
        asset_id: 69_57_420n,
        owner: alicePosAddress.toString(16),
        external_amount: 0,
      },
      {
        amount: 420n,
        asset_id: 69_57_420n,
        owner: bobPosAddress.toString(16),
        external_amount: 0,
      },
    ],
  };

  const outputNotes = [
    [alicePosAddress, 69000n, btcAssetId],
    [bobPosAddress, 420n, btcAssetId],
  ];
  const outputNoteHashes = outputNotes.map((note) =>
    poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
  );
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
