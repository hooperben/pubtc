import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

describe("Merkle Tree Test", function () {
  // values should be an array of notes, containing:
  // owner_pk, amount, assetId
  const values = [
    [
      "0x1111111111111111111111111111111111111111",
      "5000000000000000000",
      "USDC",
    ],
    [
      "0x2222222222222222222222222222222222222222",
      "2500000000000000000",
      "USDC",
    ],
    ["0xAlice", "2500000000000000000", "USDC"],
    ["0xAlice", "2500000000000000000", "USDC"],
  ];

  // (2)
  const tree = StandardMerkleTree.of(values, ["string", "uint256", "string"]);

  before(() => {});

  it.only("should run", async () => {
    console.log("running");
    // (3)
    console.log("Merkle Root:", tree.root);

    console.log(tree.render());
  });
});
