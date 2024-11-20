import { keccak256, toUtf8Bytes } from "ethers";

async function main() {
  const testerString = "hello world";
  const bytesRep = toUtf8Bytes(testerString);

  const hash = keccak256(bytesRep);
  const hashArray = Uint8Array.from(Buffer.from(hash.slice(2), "hex"));

  console.log(hash);
  console.log(hashArray);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
