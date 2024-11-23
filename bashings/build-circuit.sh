#!/bin/bash

circuit=$1

if [ "$circuit" == "poseidon" ] || [ "$circuit" == "keccak" ]; then
    echo "building note verify"
    cd circuits/$circuit/note_verify_keccak/
    nargo compile
    bb write_vk -b ./target/note_verify.json
    bb contract
else
    echo "Invalid argument. Please provide either 'poseidon' or 'keccak'."
fi
