# citrea-hackerhouse

This repository contains my project for the Citrea Origins Hacker House, PUBTC (Private, Unstoppable Bitcoin).

This was a research experiment to investigate the complexity of a system that would enable private transfers of a token balance on a public computer.

Projects like this already exist, like railgun, but I wanted to see if I could build it in Noir (railgun has its circuits written in circom).

TLDR I thought it'd be easier than it was lol, and originally wanted to ship this with a report on how a protocol like this could implement compliance checks with differing levels of decentralisation, but that'll come later.

# project structure

### `circuits/`

Contains the note_verify circuit that powers this sorcery. This is a noir circuit, that complies to a solidity verifier contract.

### `contracts`

Contains `PUBTC.sol` - a private, wrapped bitcoin token implementation.

### Getting things working

To build our solidity verifier contract:

```bash
nargo compile
bb write_vk -b ./target/note_verify.json
bb contract
```

To run tests:

```
bun install
bun hardhat test
```

### Citrea Testnet Deployment

On Citrea testnet, I was able to deposit 69,420 satoshis to the pool as alice:

0x1e0b2ce6c51719da77d7de0ac3affe1f7aa6c6965d3649482e2780b4ed3f7354

Then, as Alice, I was able to privately send bob 420 satoshis:

0xa2be50896b04796c399afa5c7f81add235a71efa6fd380f8888993263fda3199

Then, Bob was able to privately send Charlie 69 satoshis:

0x07eb03003c27e75c54ca9683fa7e618f0a5612f1fb5a49498482a0d338627128

Then, Charlie was able to withdraw 24 satoshis to their address:

0xa94dcd2895814982761142f46c55fcad12098bbc75c7c1de009858855248008d

### Problems / Optimisations

- I am pretty sure there's a critical vulnerability in the withdrawal function lol
- If I can migrate the zk from using a poseidon hash to using a keccak hash, it will make transfers/withdraws 75% cheaper
- I need to bake the withdrawal address into the proof to avoid front running
- Need to make it so transfer/withdrawal can take multiple input notes

# Disclaimers

All code is unaudited, do not deploy in production.
