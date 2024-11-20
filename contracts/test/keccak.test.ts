import { expect } from "chai";
import { PUBTC, SimpleMerkleTree, PUBTCK } from "../typechain-types";
import { keccak256, toUtf8Bytes, Wallet } from "ethers";
import { MerkleTree } from "merkletreejs";
import { getTestingAPI, loadPoseidon } from "../helpers";
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import { Noir } from "@noir-lang/noir_js";

describe("Merkle Tree Test", function () {
  let PUBTCK: PUBTCK;

  let alice: Wallet;
  let bob: Wallet;
  let charlie: Wallet;

  let poseidon2Hash: any;

  let noir: Noir;
  let backend: BarretenbergBackend;

  before(async () => {
    ({ alice, bob, charlie, PUBTCK, noir, backend } = await getTestingAPI());

    const emptyNote = keccak256(toUtf8Bytes("PRIVATE_UNSTOPPABLE_BITCOIN"));
    const emptyNotes = Array(32).fill(emptyNote); // 2^5 == 32 (our tree has 5 layers)

    const tree = new MerkleTree(emptyNotes, keccak256, {
      sort: false,
      complete: true,
    });

    const proof = tree.getProof(emptyNote).map((step) => {
      return {
        path: step.position === "right" ? 1 : 0,
        value: Uint8Array.from(Buffer.from(step.data.toString("hex"), "hex")),
      };
    });
  });

  it.only("should print the correct tree", async () => {});
});
