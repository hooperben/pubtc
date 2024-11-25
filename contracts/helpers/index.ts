import { Wallet } from "ethers";
import { PUBTC, SimpleMerkleTree } from "../typechain-types";
import hre, { ethers } from "hardhat";
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import { Noir } from "@noir-lang/noir_js";
import { CompiledCircuit } from "@noir-lang/types";
import { readFileSync } from "fs";
import { resolve } from "path";

export const getTestingAPI = async () => {
  let simpleMerkleTree: PUBTC;

  let alice: Wallet;
  let bob: Wallet;
  let charlie: Wallet;

  let poseidonBackend: BarretenbergBackend;
  let poseidonNoir: Noir;

  let keccakBackend: BarretenbergBackend;
  let keccakNoir: Noir;

  // next we initialise our Noir libraries to generate proofs
  const poseidonCircuitFile = readFileSync(
    resolve("../circuits/poseidon/note_verify/target/note_verify.json"),
    "utf-8",
  );
  const poseidonCircuit = JSON.parse(poseidonCircuitFile);

  poseidonBackend = new BarretenbergBackend(poseidonCircuit);
  poseidonNoir = new Noir(poseidonCircuit);

  const keccak256CircuitFile = readFileSync(
    resolve("../circuits/keccak/note_verify/target/note_verify.json"),
    "utf-8",
  );

  const keccakCircuit = JSON.parse(keccak256CircuitFile);

  keccakBackend = new BarretenbergBackend(keccakCircuit);
  keccakNoir = new Noir(keccakCircuit);

  const [funder] = await hre.ethers.getSigners();

  const alice_private_key =
    "0x91b1ba753a83576e85b0bc41b3335e58a8f5a064bd4379c70b5295221277aa8e";
  const bob_private_key =
    "0x04b84dc399d3384bc4b7d5e88567160a897e0cd1bb382713c4db0f4a95d1825f";
  const charlie_private_key =
    "0x58409f99febb8326dff7fd504d8dd1978a26c00af8029754d83948b0e88b8362";

  alice = new ethers.Wallet(alice_private_key, hre.ethers.provider);
  bob = new ethers.Wallet(bob_private_key, hre.ethers.provider);
  charlie = new ethers.Wallet(charlie_private_key, hre.ethers.provider);

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

  const NoteVerifier = await hre.ethers.getContractFactory("UltraVerifier");
  let verifier = await NoteVerifier.deploy();

  const SimpleMerkleTree = await hre.ethers.getContractFactory("PUBTC");

  simpleMerkleTree = await SimpleMerkleTree.deploy(5, verifier.target);

  const PUBTCKFactory = await hre.ethers.getContractFactory("PUBTCK");

  const PUBTCK = await PUBTCKFactory.deploy(5, verifier.target);

  return {
    simpleMerkleTree,
    PUBTCK,
    alice,
    bob,
    charlie,
    poseidonBackend,
    poseidonNoir,
    keccakBackend,
    keccakNoir,
  };
};

export const loadPoseidon = async () => {
  // Use Function constructor to avoid CommonJS static analysis
  const importModule = new Function(
    'return import("@aztec/foundation/crypto")',
  );
  const module = await importModule();
  return module.poseidon2Hash;
};
