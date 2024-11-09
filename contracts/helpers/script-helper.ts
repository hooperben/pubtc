import { ethers } from "hardhat";
import { loadPoseidon } from "../helpers";
import { PUBTC, PUBTCK__factory } from "../typechain-types";
import MerkleTree from "merkletreejs";
import { readFileSync } from "fs";
import { resolve } from "path";
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import { Noir } from "@noir-lang/noir_js";

export const scriptHelper = async () => {
  const [signer] = await ethers.getSigners();
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

  const PUBTCAddress = "0x3a44ad44Ba684316041209a83abe1470ddfB3032";

  const PUTBTC = new ethers.Contract(
    PUBTCAddress,
    PUBTCK__factory.abi,
    signer,
  ) as unknown as PUBTC;

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

  // create our empty tree
  const emptyNote = poseidon2Hash([BigInt(57_69_240)]).toString();
  const emptyNotes = Array(32).fill(emptyNote);
  const noteHashes = emptyNotes;

  const tree = new MerkleTree(noteHashes, hasherFn, {
    sort: false,
    complete: true,
  });

  const btcAssetId = 69_57_420n;

  // next we initialise our Noir libraries to generate proofs
  const circuitFile = readFileSync(
    resolve("../circuits/note_verify/target/note_verify.json"),
    "utf-8",
  );
  const circuit = JSON.parse(circuitFile);

  const backend = new BarretenbergBackend(circuit);
  const noir = new Noir(circuit);

  return {
    backend,
    noir,
    tree,
    btcAssetId,
    PUTBTC,
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
