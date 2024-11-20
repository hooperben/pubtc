import { keccak256, toUtf8Bytes } from "ethers";

async function main() {
  const value1 = "tester_hash1";
  const value2 = "tester_hash2";

  const hash1Bytes = keccak256(toUtf8Bytes(value1));
  const hash1Array = Uint8Array.from(Buffer.from(hash1Bytes.slice(2), "hex"));
  console.log(hash1Array);

  const hash2Bytes = keccak256(toUtf8Bytes(value1));
  const hash2Array = Uint8Array.from(Buffer.from(hash1Bytes.slice(2), "hex"));
  console.log(hash2Array);

  const hash = keccak256(Uint8Array.from([...hash1Array, ...hash2Array]));

  console.log(hash);
  console.log(Uint8Array.from(Buffer.from(hash.slice(2), "hex")));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
