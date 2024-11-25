import { expect } from "chai";
import { PUBTC, SimpleMerkleTree, PUBTCK } from "../typechain-types";
import { keccak256, toUtf8Bytes, Wallet } from "ethers";
import { MerkleTree } from "merkletreejs";
import { getTestingAPI } from "../helpers";
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import { abi, Noir } from "@noir-lang/noir_js";

const convertFromHexToArray = (rawInput: string): Uint8Array => {
  const formmatedInput = rawInput.startsWith("0x")
    ? rawInput.slice(2)
    : rawInput;
  return Uint8Array.from(Buffer.from(formmatedInput, "hex"));
};

describe("Keccak Merkle Tree Test", function () {
  let PUBTCK: PUBTCK;

  let alice: Wallet;
  let bob: Wallet;
  let charlie: Wallet;

  let poseidon2Hash: any;

  let keccakNoir: Noir;
  let keccakBackend: BarretenbergBackend;

  let tree: MerkleTree;

  const emptyNote = keccak256(toUtf8Bytes("PRIVATE_UNSTOPPABLE_BITCOIN"));
  const emptyNotes = Array(32).fill(emptyNote); // 2^5 == 32 (our tree has 5 layers)

  before(async () => {
    ({ alice, bob, charlie, PUBTCK, keccakNoir, keccakBackend } =
      await getTestingAPI());

    tree = new MerkleTree(emptyNotes, keccak256, {
      sort: false,
      complete: true,
    });
  });

  it.only("should verify", async () => {
    console.log("hey");
    const alicePubKey = keccak256(alice.privateKey);
    const amount = Uint8Array.from([69, 0, 0, 0, 0]);
    const assetId = Uint8Array.from([0, 0, 0, 0, 0, 0, 0, 1]);

    const noteHash = keccak256(
      Uint8Array.from([
        ...convertFromHexToArray(alicePubKey),
        ...amount,
        ...assetId,
      ]),
    );
  });

  it("should print the correct tree", async () => {
    const alicePubKey = keccak256(alice.privateKey);
    const bobPubKey = keccak256(bob.privateKey);

    const amount = Uint8Array.from([69, 0, 0, 0, 0]);
    const assetId = Uint8Array.from([0, 0, 0, 0, 0, 0, 0, 1]);

    // console.log(
    //   `let alice_private_key = [${convertFromHexToArray(alice.privateKey)}]`,
    // );
    // console.log(`let alice_pub_key = [${convertFromHexToArray(alicePubKey)}]`);

    const noteHash = keccak256(
      Uint8Array.from([
        ...convertFromHexToArray(alicePubKey),
        ...amount,
        ...assetId,
      ]),
    );

    console.log(noteHash);

    tree.updateLeaf(0, Buffer.from(noteHash.slice(2), "hex"));

    const proof = tree.getProof(noteHash).map((step) => {
      return {
        path: step.position === "right" ? 1 : 0,
        value: convertFromHexToArray(step.data.toString("hex")),
      };
    });

    const leaf_index = Uint8Array.from([0, 0, 0, 0, 0, 0, 0, 0]);

    const nullifier = keccak256(
      Uint8Array.from([
        ...leaf_index,
        ...convertFromHexToArray(alicePubKey),
        ...amount,
        ...assetId,
      ]),
    );

    // console.log("nullifier");
    // console.log(convertFromHexToArray(nullifier));

    // // console.log(proof);

    // // proof.map((item) => console.log(item.value));
    // // proof.map((item) => console.log(item.path));

    const outputNote = convertFromHexToArray(
      keccak256(
        Uint8Array.from([
          ...amount,
          ...assetId,
          ...convertFromHexToArray(bobPubKey),
        ]),
      ),
    );

    // console.log(tree.toString());
    // console.log(tree.getHexRoot());

    console.log(convertFromHexToArray(tree.getHexRoot()));

    console.log(Uint8Array.from([69, 0, 0, 0, 0]));

    // console.log(proof);

    console.log(outputNote);
  });
});
