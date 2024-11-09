import { ethers } from "hardhat";
import { loadPoseidon } from "../helpers";
import MerkleTree from "merkletreejs";
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
  } = await scriptHelper();

  const depositValue = 69420n;

  const inputNotes = [[alicePosAddress, depositValue, btcAssetId]];
  const inputNoteHashes = inputNotes.map((note) =>
    poseidon2Hash([BigInt(note[0]), note[1], note[2]]).toString(),
  );

  // submit our deposit
  const tx = await PUTBTC.deposit(inputNoteHashes[0], { value: depositValue });
  console.log(tx);

  await tx.wait();

  console.log("done!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
