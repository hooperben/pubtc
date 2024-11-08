// 0x5FbDB2315678afecb367f032d93F642f64180aa3

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// npx hardhat ignition deploy ignition/modules/PUBTC.ts --network localhost

const PUBTCModule = buildModule("PUBTCModule", (m) => {
  const _levels = m.getParameter("_levels", 5);
  const verifier = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const _noteVerifier = m.getParameter("_noteVerifier", verifier);

  const UltraPUBTC = m.contract("PUBTC", [_levels, _noteVerifier]);
  return { UltraPUBTC };
});

export default PUBTCModule;
