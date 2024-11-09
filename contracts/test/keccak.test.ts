import { expect } from "chai";
import { PUBTC, SimpleMerkleTree, PUBTCK } from "../typechain-types";
import { keccak256, Wallet } from "ethers";
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

    const aliceBal = await alice.provider?.getBalance(alice.address);
    expect(aliceBal).equal(10000000000000000000n);
  });
});
