import MerkleTree from "merkletreejs";
import { loadPoseidon } from "../helpers";

describe("Generating empty merkle tree", async () => {
  it("merkle tree changes should track", async () => {
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

    console.log(tree.toString());
    console.log("root: ", tree.getRoot().toString("hex"));
  });
});
