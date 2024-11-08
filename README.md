# citrea-hackerhouse

This repository contains my project for the Citrea Origins Hacker House, PUBTC (Private, Unstoppable Bitcoin).

This was a research experiment to investigate the complexity of a system that would enable private transfers of a token.

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
