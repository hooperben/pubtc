async function main() {
  const { ethers } = require("hardhat");

  // Get the first signer
  const [signer] = await ethers.getSigners();

  // Get balance
  const balance = await ethers.provider.getBalance(signer.address);

  console.log("Signer address:", signer.address);
  console.log("Balance:", ethers.formatEther(balance), "cBTC");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
