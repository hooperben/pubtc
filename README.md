# citrea-hackerhouse

Current plan is:

- `circuits/` core circuits to generate private transfers
- `pum-lib/` contains all helper functions used in this library

### `circuits`

circuits contains the core circuits required for the roman kyoto MASP.

- `sig_verify` is the signature verification circuit

### `pum-lib`

Pum lib is ideally meant to be a component library that contains all core logic

```

bb write_vk -b ./target/<noir_artifact_name>.json

bb write_vk -b ./target/note_verify.json


```
