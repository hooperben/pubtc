// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

// npx hardhat ignition deploy ignition/modules/Verifier.ts --network localhost
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const VerifierModule = buildModule("VerifierModule", (m) => {
  const UltraVerifier = m.contract("UltraVerifier");
  return { UltraVerifier };
});

export default VerifierModule;
