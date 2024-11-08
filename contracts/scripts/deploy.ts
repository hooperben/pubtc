import { ethers } from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();

  // const NoteVerifier = await ethers.getContractFactory("UltraVerifier", signer);
  // const verifier = await NoteVerifier.deploy();

  // console.log(verifier);
  const verifierAddress = "0x93e24E3772a80e4bC0464Aa257E2F2B1245bBb70";
  // deployed to 0x93e24E3772a80e4bC0464Aa257E2F2B1245bBb70

  // // Get the first signer

  const PUBTCKFactory = await ethers.getContractFactory("PUBTC");
  const PUBTC = await PUBTCKFactory.deploy(5, verifierAddress);

  console.log(PUBTC);

  // deployed to 0x3a44ad44Ba684316041209a83abe1470ddfB3032
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
