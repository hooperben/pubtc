import { Wallet } from "ethers";
import { PUBTC, SimpleMerkleTree } from "../typechain-types";
import hre, { ethers } from "hardhat";
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import { Noir } from "@noir-lang/noir_js";
import { CompiledCircuit } from "@noir-lang/types";
import { readFileSync } from "fs";
import { resolve } from "path";

export const getTestingAPI = async () => {
  // note circuit
  const keccakNoteCircuitFile = readFileSync(
    resolve("../circuits/keccak/note_verify/target/note_verify.json"),
    "utf-8",
  );
  const keccakNoteCircuit = JSON.parse(keccakNoteCircuitFile);
  const keccakNoteBackend = new BarretenbergBackend(keccakNoteCircuit);
  const keccakNoteNoir = new Noir(keccakNoteCircuit);

  // deposit circuit
  const keccakDepositCircuitFile = readFileSync(
    resolve("../circuits/keccak/deposit/target/deposit_keccak.json"),
    "utf-8",
  );
  const keccakDepositCircuit = JSON.parse(keccakDepositCircuitFile);
  const keccakDepositBackend = new BarretenbergBackend(keccakDepositCircuit);
  const keccakDepositNoir = new Noir(keccakDepositCircuit);

  const [funder] = await hre.ethers.getSigners();

  const alice_private_key =
    "0x91b1ba753a83576e85b0bc41b3335e58a8f5a064bd4379c70b5295221277aa8e";
  const bob_private_key =
    "0x04b84dc399d3384bc4b7d5e88567160a897e0cd1bb382713c4db0f4a95d1825f";
  const charlie_private_key =
    "0x58409f99febb8326dff7fd504d8dd1978a26c00af8029754d83948b0e88b8362";

  const alice = new ethers.Wallet(alice_private_key, hre.ethers.provider);
  const bob = new ethers.Wallet(bob_private_key, hre.ethers.provider);
  const charlie = new ethers.Wallet(charlie_private_key, hre.ethers.provider);

  // Fund alice and bob with 10 ETH each
  await funder.sendTransaction({
    to: alice.address,
    value: ethers.parseEther("10.0"),
  });

  await funder.sendTransaction({
    to: bob.address,
    value: ethers.parseEther("10.0"),
  });

  await funder.sendTransaction({
    to: charlie.address,
    value: ethers.parseEther("10.0"),
  });

  const NoteVerifier = await hre.ethers.getContractFactory("NotesVerifier");
  const noteVerifier = await NoteVerifier.deploy();

  const DepositVerifier = await hre.ethers.getContractFactory(
    "DepositVerifier",
  );
  const depositVerifier = await DepositVerifier.deploy();

  const PUBTC = await hre.ethers.getContractFactory("PUBTC");
  const puBTC = await PUBTC.deploy(
    5, // height of merkle tree
    noteVerifier.target,
    depositVerifier.target,
  );

  return {
    puBTC,
    alice,
    bob,
    charlie,
    keccakNoteBackend,
    keccakNoteNoir,
    keccakDepositBackend,
    keccakDepositNoir,
  };
};
