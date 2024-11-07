import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { expect } from "chai";

// Create a wrapper function that uses dynamic import
const loadPoseidon = async () => {
  // Use Function constructor to avoid CommonJS static analysis
  const importModule = new Function(
    'return import("@aztec/foundation/crypto")',
  );
  const module = await importModule();
  return module.poseidon2Hash;
};

describe("Merkle Tree Test", function () {
  // values should be an array of notes, containing:
  // owner_pk, amount, assetId
  const values = [
    ["0x1111111111111111111111111111111111111111", "5000", "USDC"],
    ["0x2222222222222222222222222222222222222222", "69", "USDC"],
    ["0xAlice", "100", "USDC"],
    ["0xCharlie", "200", "USDC"],
  ];

  // (2)
  const tree = StandardMerkleTree.of(values, ["string", "uint256", "string"]);

  before(() => {});

  it("should run", async () => {
    console.log("running");
    // (3)
    console.log("Merkle Root:", tree.root);

    console.log("Initial State:");
    console.log(tree.render());

    // we want to spent note 3 (alices $100 USDC) and create these 2
    const outputNotes = [
      ["0xAlice", "50", "USDC"],
      ["0xBob", "50", "USDC"],
    ];

    const newTree = StandardMerkleTree.of(
      [...values, ...outputNotes],
      ["string", "uint256", "string"],
    );

    console.log("New UTXOs added:");
    console.log(newTree.render());
  });

  it("poseidon test", async () => {
    const poseidon2Hash = await loadPoseidon();
    // // in noir:
    // println(poseidon2::Poseidon2::hash([12341241, 12341241], 2));
    const test = await poseidon2Hash([12341241n, 12341241n]).toString();

    expect(test).eql(
      "0x0dd8218a93222c13ac6228d4190bc19d01234b5f99e33cc43a16cc0db0759e57",
    );
  });
});