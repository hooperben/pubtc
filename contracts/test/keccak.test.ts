import { expect } from "chai";
import { PUBTC } from "../typechain-types";
import { keccak256, parseEther, toUtf8Bytes, Wallet } from "ethers";
import { MerkleTree } from "merkletreejs";
import { getTestingAPI } from "../helpers";
import { BarretenbergBackend } from "@noir-lang/backend_barretenberg";
import { abi, InputMap, Noir } from "@noir-lang/noir_js";

const convertFromHexToArray = (rawInput: string): Uint8Array => {
  const formmatedInput = rawInput.startsWith("0x")
    ? rawInput.slice(2)
    : rawInput;
  return Uint8Array.from(Buffer.from(formmatedInput, "hex"));
};

describe("Keccak Merkle Tree Test", function () {
  let puBTC: PUBTC;

  let alice: Wallet;
  let bob: Wallet;
  let charlie: Wallet;

  let poseidon2Hash: any;

  let keccakNoteNoir: Noir;
  let keccakNoteBackend: BarretenbergBackend;

  let keccakDepositNoir: Noir;
  let keccakDepositBackend: BarretenbergBackend;

  let tree: MerkleTree;

  const emptyNote = keccak256(toUtf8Bytes("PRIVATE_UNSTOPPABLE_BITCOIN"));
  const emptyNotes = Array(32).fill(emptyNote); // 2^5 == 32 (our tree has 5 layers)

  before(async () => {
    ({
      alice,
      bob,
      charlie,
      puBTC,
      keccakNoteNoir,
      keccakNoteBackend,
      keccakDepositNoir,
      keccakDepositBackend,
    } = await getTestingAPI());

    tree = new MerkleTree(emptyNotes, keccak256, {
      sort: false,
      complete: true,
    });
  });

  it.only("should let me deposit", async () => {
    const alicePubKey = keccak256(alice.privateKey);

    const rawAmount = convertFromHexToArray(parseEther("1.121121").toString());
    const emptyZeros = new Array(32 - rawAmount.length).fill(0);
    const amount = Uint8Array.from([...emptyZeros, ...rawAmount]);

    const depositAddress = "0x0000000000000000000000000000000000000000";
    const assetId = convertFromHexToArray(depositAddress);

    // calculate the note hash
    const noteHash = keccak256(
      Uint8Array.from([
        ...convertFromHexToArray(alicePubKey),
        ...amount,
        ...assetId,
      ]),
    );

    const formattedHash = Array.from(convertFromHexToArray(noteHash), (item) =>
      item.toString(),
    );
    const formattedAmount = Array.from(amount, (item) => item.toString());
    const formattedPubKey = Array.from(
      convertFromHexToArray(alicePubKey),
      (item) => item.toString(),
    );
    const formattedAssetId = Array.from(assetId, (item) => item.toString());

    const input = {
      hash: formattedHash, // Convert to hex string
      amount: formattedAmount, // Convert to hex string
      pub_key: formattedPubKey, // Convert to hex string
      asset_id: formattedAssetId, // Convert to hex string
    };

    // generate our zk proof
    const { witness } = await keccakDepositNoir.execute(
      input as unknown as InputMap,
    );
    const zkProof = await keccakDepositBackend.generateProof(witness);

    console.log(zkProof);

    await puBTC.deposit(zkProof.proof, zkProof.publicInputs, noteHash, {
      value: parseEther("1.121121"),
    });
  });

  it("deposit proof data testing", async () => {
    const alicePubKey = keccak256(alice.privateKey);
    const wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const assetId = convertFromHexToArray(wethAddress);

    const rawAmount = convertFromHexToArray(parseEther("2.7").toString());

    // we need to pad our array with 0s to match the length of 32
    const emptyZeros = new Array(32 - rawAmount.length).fill(0);

    const amount = [...emptyZeros, ...rawAmount];

    // calculate the note hash
    const noteHash = keccak256(
      Uint8Array.from([
        ...convertFromHexToArray(alicePubKey),
        ...amount,
        ...assetId,
      ]),
    );

    console.log("hex hash:");
    console.log(noteHash);
    console.log("uint8array hash rep:");
    console.log(convertFromHexToArray(noteHash));

    console.log("----inputs------");
    console.log("alice pub key: ", convertFromHexToArray(alicePubKey));
    console.log("amount: ", amount);
    console.log("assetId: ", assetId);
  });

  it("should print the correct tree", async () => {
    const alicePubKey = keccak256(alice.privateKey);
    const bobPubKey = keccak256(bob.privateKey);

    const wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    const assetId = convertFromHexToArray(wethAddress);

    const rawAmount = convertFromHexToArray(parseEther("2.7").toString());

    // we need to pad our array with 0s to match the length of 32
    const emptyZeros = new Array(32 - rawAmount.length).fill(0);

    const amount = [...emptyZeros, ...rawAmount];

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
        ...convertFromHexToArray(alice.privateKey),
        ...amount,
        ...assetId,
      ]),
    );

    console.log("nullifier");
    console.log(convertFromHexToArray(nullifier));

    // // console.log(proof);

    proof.map((item) => console.log(item.value));
    proof.map((item) => console.log(item.path));

    const outputNote = convertFromHexToArray(
      keccak256(
        Uint8Array.from([
          ...convertFromHexToArray(bobPubKey),
          ...amount,
          ...assetId,
        ]),
      ),
    );

    // console.log(tree.toString());
    // console.log(tree.getHexRoot());

    console.log("tree root: ", convertFromHexToArray(tree.getHexRoot()));

    // console.log(proof);

    console.log("out note hash: ", outputNote);
  });
});
