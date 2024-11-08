use std::hash::poseidon2;

pub fn compute_keccak_merkle_root<let N: u32>(
    leaf: Field,
    path_indices: [Field; N],
    hash_path: [Field; N],
) -> Field {
    let mut current = leaf;
    for i in 0..N {
        let path_bit = path_indices[i];
        let (hash_left, hash_right) = if path_bit == 0 {
            (hash_path[i], current)
        } else {
            (current, hash_path[i])
        };

        println(hash_left);
        println(hash_right);
        // current = std::hash::keccak256([input], 64);
    }
    current
}

struct InputNoteSpend {
    leafIndex: Field,
    path: [Field; 5],
    path_data: [Field; 5],
    address: Field,
    amount: Field,
    asset_id: Field,
}

struct OutputNoteAmount {
    amount: Field,
    asset_id: Field,
    owner: Field,
    pub external_amount: Field,
}

fn main(
    privateKey: Field,
    root: pub Field,
    nullifier: pub Field,
    inputNote: InputNoteSpend,
    outputNotes: [OutputNoteAmount; 2],
) {
    // check the sender owns the note
    let senderPubKey = poseidon2::Poseidon2::hash([privateKey], 1);
    assert(senderPubKey == inputNote.address, "invalid spender");

    // regenerate leaf
    let leaf =
        poseidon2::Poseidon2::hash([inputNote.address, inputNote.amount, inputNote.asset_id], 3);

    // reconstruct the nullifier
    let reconstructed_nullifier = poseidon2::Poseidon2::hash(
        [inputNote.leafIndex, privateKey, inputNote.amount, inputNote.asset_id],
        4,
    );
    assert(reconstructed_nullifier == nullifier, "invalid nullifier");

    // reconstruct merkle root and check for a match
    let merkle_root = compute_keccak_merkle_root(leaf, inputNote.path, inputNote.path_data);
    assert(root == merkle_root, "invalid merkle proof");

    // this is hacky but it'll do
    let dead_value = 0x84cf1c96ee76f15cbfeb1e2eaf55413059e78b501728133facb4664277dead;

    // check inputs == outputs
    let mut sum = 0;
    for i in 0..outputNotes.len() {
        if (outputNotes[i].external_amount as u64 > 0) {
            assert(outputNotes[i].owner == dead_value, "invalid burn not");
            assert(outputNotes[i].amount == outputNotes[i].external_amount, "sneaky!");
        }
        assert(outputNotes[i].asset_id == inputNote.asset_id, "Invalid asset id");
        sum = sum + outputNotes[i].amount;
    }
    assert(inputNote.amount == sum, "inputs !== outputs");
}

#[test]
fn test_hash() {
    // 0xdead9e513904097e4eff2a59768b3b8969df72b3de6442def89fc4b70f9d4dead
    let expected = [
        0xde, 0xad, 0x9e, 0x51, 0x39, 0x04, 0x97, 0xe4,
        0xef, 0xf2, 0xa5, 0x97, 0x68, 0xb3, 0xb8, 0x96,
        0x9d, 0xf7, 0x2b, 0x3d, 0xe6, 0x44, 0x2d, 0xef,
        0x89, 0xfc, 0x4b, 0x70, 0xf9, 0xd4, 0xde, 0xad
    ];

    let hash_a = std::hash::keccak256(expected, 32);

    let expected_hash = [
        0xff, 0x75, 0xbe, 0xd8, 0x15, 0x78, 0x75, 0xf8,
        0x47, 0x31, 0x57, 0x74, 0x2d, 0xc4, 0x63, 0x6c,
        0x47, 0xc3, 0xdb, 0x82, 0xbe, 0x9a, 0xb8, 0x86,
        0xa2, 0x7c, 0x64, 0xff, 0x04, 0xe7, 0x60, 0x6d
    ];

    assert(expected_hash == hash_a, "doesnt match ts");
}
