import { keccak256, toUtf8Bytes } from "ethers";

async function main() {
  const bytes = new Uint8Array([1]);
  console.log(bytes);

  const hash = keccak256(bytes);
  const hashArray = Uint8Array.from(Buffer.from(hash.slice(2), "hex"));
  console.log(hash);
  console.log(hashArray);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
