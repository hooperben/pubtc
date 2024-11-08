import MerkleTree from "merkletreejs";
import { loadPoseidon } from "../helpers";
import { keccak256 } from "ethers";

describe("Generating empty merkle tree", async () => {
  it.only("merkle tree changes should track", async () => {
    const poseidon2Hash = await loadPoseidon();

    const emptyNote = poseidon2Hash([BigInt(57_69_240)]).toString();
    const emptyNotes = Array(32).fill(emptyNote);

    // console.log(emptyNote); // 0x0124e2a36fa18ec18993d7a281e8270ac93340ccf0785ab75e18cc3f4f74296c

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

    const tree = new MerkleTree(emptyNotes, hasherFn, {
      sort: false,
      complete: true,
    });
  });

  it.only("should assemble a keccak tree", async () => {
    const emptyNote = keccak256(
      new Uint8Array([
        0xde, 0xad, 0x9e, 0x51, 0x39, 0x04, 0x97, 0xe4, 0xef, 0xf2, 0xa5, 0x97,
        0x68, 0xb3, 0xb8, 0x96, 0x9d, 0xf7, 0x2b, 0x3d, 0xe6, 0x44, 0x2d, 0xef,
        0x89, 0xfc, 0x4b, 0x70, 0xf9, 0xd4, 0xde, 0xad,
      ]),
    );
    console.log(
      "0xdead9e513904097e4eff2a59768b3b8969df72b3de6442def89fc4b70f9d4dead",
    );
    console.log("keccak hash");
    console.log(emptyNote);

    const emptyNotes = Array(32).fill(emptyNote);

    const hasherFn = (input: string) => {
      const [left, right] = [
        input.slice(0, input.length / 2) as unknown as Buffer,
        input.slice(input.length / 2) as unknown as Buffer,
      ];

      const concatenated = Buffer.concat([left, right]);
      const hash = keccak256(concatenated);
      return hash;
    };

    const tree = new MerkleTree(emptyNotes, hasherFn, {
      sort: false,
      complete: true,
    });

    console.log(tree.toString());
    console.log("root: ", tree.getRoot().toString("hex"));
  });
});
