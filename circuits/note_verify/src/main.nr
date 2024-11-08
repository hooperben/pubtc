use std::hash::poseidon2;

pub fn compute_poseidon_merkle_root<let N: u32>(
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
        current = poseidon2::Poseidon2::hash([hash_left, hash_right], 2);
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
    let merkle_root = compute_poseidon_merkle_root(leaf, inputNote.path, inputNote.path_data);
    assert(root == merkle_root, "invalid merkle proof");

    // check inputs == outputs
    let mut sum = 0;
    for i in 0..outputNotes.len() {
        assert(outputNotes[i].asset_id == inputNote.asset_id, "Invalid asset id");
        sum = sum + outputNotes[i].amount;
    }
    assert(inputNote.amount == sum, "inputs !== outputs");
}

#[test]
fn test_main() {
    let privateKey = 0x84cf1c96ee76f15cbfeb1e2eaf55413059e78b501728133facb4664277aa8b;
    let alice = 0x20df6cb4768e57fd8e2404f04981b18c95fb4000e2288627c1c6594f8973ef6b;
    let bob = 0x2a166d476cc9fb48a531092a850a647f2db1da08981313f16b5461d8091254ed;
    let root = 0x1d7c9a8d7dac872b69f3dc62f019e07d08266cdd415aaf3a13c19f5fdead6c10;

    let inputNote = InputNoteSpend {
        address: alice,
        amount: 50,
        asset_id: 69_57_420,
        leafIndex: 0,
        path: [1, 1, 1, 1, 1],
        path_data: [
            0x0124e2a36fa18ec18993d7a281e8270ac93340ccf0785ab75e18cc3f4f74296c,
            0x1c936490f40b64fcb00e7b92a9a3cf68933465ec4d0a2fb7f1442c82810b894d,
            0x0bb7701b39c1ba621c04938017d07e70baeae094fbbf80606b978030ce78453e,
            0x154d4ad9f6ec7b100aa165d72d5068613d2c3129bb19a54fff82850f8cf0a464,
            0x010185aeae0f692bb0c289bed20658067d4cd55800d95b3a2d25d9696dc92d9a,
        ],
    };

    let nullifier =
        poseidon2::Poseidon2::hash([inputNote.leafIndex, privateKey, 50, inputNote.asset_id], 4);

    let outputNotes = [
        OutputNoteAmount { amount: 10, asset_id: 69_57_420, owner: alice },
        OutputNoteAmount { amount: 40, asset_id: 69_57_420, owner: bob },
    ];

    main(privateKey, root, nullifier, inputNote, outputNotes);
}
