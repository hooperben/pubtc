use std::{hash::{poseidon2::Poseidon2Hasher, BuildHasherDefault}, collections::map::HashMap};

global MAX_NOTES_AMOUNT = 4;
global TREE_HEIGHT = 5;
global ASSET_LENGTH = 20; // eth address representation (20 bytes)
global AMOUNT_LENGTH = 32;
global FIELD_LENGTH = 32;
global ADDRESS_LENGTH = 32;
global LEAF_INDEX_LENGTH = 8;

global SUM_OF_INPUT_LEN = ADDRESS_LENGTH + AMOUNT_LENGTH + ASSET_LENGTH;
global NULLIFIER_PREIMAGE_LEN = LEAF_INDEX_LENGTH + ADDRESS_LENGTH + AMOUNT_LENGTH + ASSET_LENGTH;
global DEAD_OWNER = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
];

pub fn concatenate_bytes32_arrays(
    arr1: [u8; FIELD_LENGTH],
    arr2: [u8; FIELD_LENGTH],
) -> [u8; FIELD_LENGTH + FIELD_LENGTH] {
    let mut result = [0; FIELD_LENGTH + FIELD_LENGTH];
    for i in 0..FIELD_LENGTH {
        result[i] = arr1[i];
    }
    for i in 0..FIELD_LENGTH {
        result[i + FIELD_LENGTH] = arr2[i];
    }
    result
}

// N == number of layers in the tree
pub fn compute_keccak_merkle_hash<let N: u32>(
    leaf: [u8; FIELD_LENGTH],
    path: [Field; N],
    path_data: [[u8; FIELD_LENGTH]; N],
) -> [u8; FIELD_LENGTH] {
    let mut current = leaf;
    for i in 0..N {
        let path_bit = path[i];
        let (hash_left, hash_right) = if path_bit == 0 {
            (path_data[i], current)
        } else {
            (current, path_data[i])
        };
        let concat = concatenate_bytes32_arrays(hash_left, hash_right);
        current = std::hash::keccak256(concat, FIELD_LENGTH + FIELD_LENGTH);
    }
    current
}

pub fn calculate_leaf(
    address: [u8; ADDRESS_LENGTH],
    amount: [u8; AMOUNT_LENGTH],
    asset_id: [u8; ASSET_LENGTH],
) -> [u8; 32] {
    // need to combine into one giga array
    let mut concat_values = [0; SUM_OF_INPUT_LEN];

    for i in 0..ADDRESS_LENGTH {
        concat_values[i] = address[i];
    }
    for i in 0..AMOUNT_LENGTH {
        concat_values[i + ADDRESS_LENGTH] = amount[i];
    }
    for i in 0..ASSET_LENGTH {
        concat_values[i + ADDRESS_LENGTH + AMOUNT_LENGTH] = asset_id[i];
    }

    let current = std::hash::keccak256(concat_values, SUM_OF_INPUT_LEN);

    current
}

pub fn calculate_nullifier(
    leaf_index: [u8; LEAF_INDEX_LENGTH], // TODO investigate length
    address: [u8; ADDRESS_LENGTH],
    amount: [u8; AMOUNT_LENGTH],
    asset_id: [u8; ASSET_LENGTH],
) -> [u8; 32] {
    let mut concat_values = [0; NULLIFIER_PREIMAGE_LEN];
    for i in 0..LEAF_INDEX_LENGTH {
        concat_values[i] = leaf_index[i];
    }
    for i in 0..ADDRESS_LENGTH {
        concat_values[i + LEAF_INDEX_LENGTH] = address[i];
    }
    for i in 0..AMOUNT_LENGTH {
        concat_values[i + LEAF_INDEX_LENGTH + ADDRESS_LENGTH] = amount[i];
    }
    for i in 0..ASSET_LENGTH {
        concat_values[i + LEAF_INDEX_LENGTH + ADDRESS_LENGTH + AMOUNT_LENGTH] = asset_id[i];
    }
    std::hash::keccak256(
        concat_values,
        NULLIFIER_PREIMAGE_LEN,
    )
}

fn u8_array_to_u32<let N: u32>(array: [u8; N]) -> u32 {
    let mut value: u32 = 0;
    // TODO make this use a global
    for i in 0..4 {
        value |= (array[i] as u32) << (i * 8);
    }
    value
}

struct InputNoteSpend {
    address: [u8; FIELD_LENGTH],
    private_key: [u8; FIELD_LENGTH],
    leaf_index: [u8; 8], // TODO investigate
    path: [Field; TREE_HEIGHT],
    path_data: [[u8; 32]; TREE_HEIGHT],
    amount: [u8; AMOUNT_LENGTH],
    asset_id: [u8; ASSET_LENGTH],
}

struct OutputNoteAmount {
    amount: [u8; AMOUNT_LENGTH],
    asset_id: [u8; ASSET_LENGTH],
    owner: [u8; FIELD_LENGTH],
}

type ASSET_ID_TYPE = [u8; ASSET_LENGTH];

fn main(
    root: pub [u8; FIELD_LENGTH],
    input_notes: [InputNoteSpend; MAX_NOTES_AMOUNT],
    output_notes: [OutputNoteAmount; MAX_NOTES_AMOUNT],
    // external_amounts and nullifiers are used as part of input_notes, but they need to be public
    external_amounts: pub [[u8; AMOUNT_LENGTH]; MAX_NOTES_AMOUNT],
    nullifiers: pub [[u8; FIELD_LENGTH]; MAX_NOTES_AMOUNT],
    output_hashes: pub [[u8; FIELD_LENGTH]; MAX_NOTES_AMOUNT],
) {
    // create 2 hashmaps - tracks Asset Id => BigNum sum representation (uses poseidon as is cheaper)
    let mut inputs_map: HashMap<ASSET_ID_TYPE, u32, MAX_NOTES_AMOUNT, BuildHasherDefault<Poseidon2Hasher>> =
        HashMap::default();

    let mut outputs_map: HashMap<ASSET_ID_TYPE, u32, MAX_NOTES_AMOUNT, BuildHasherDefault<Poseidon2Hasher>> =
        HashMap::default();

    for i in 0..MAX_NOTES_AMOUNT {
        if input_notes[i].amount != [0; 32] {
            let senderPubKey = std::hash::keccak256(input_notes[i].private_key, FIELD_LENGTH);

            assert(senderPubKey == input_notes[i].address, "invalid spender");

            let reconstructed_nullifier = calculate_nullifier(
                input_notes[i].leaf_index,
                input_notes[i].private_key,
                input_notes[i].amount,
                input_notes[i].asset_id,
            );

            assert(nullifiers[i] == reconstructed_nullifier, "Invalid nullifier");

            let note_leaf = calculate_leaf(
                input_notes[i].address,
                input_notes[i].amount,
                input_notes[i].asset_id,
            );

            let merkle_root = compute_keccak_merkle_hash(
                note_leaf,
                input_notes[i].path,
                input_notes[i].path_data,
            );

            assert(root == merkle_root, "Invalid merkle proof");

            let note_amount: u32 = u8_array_to_u32::<FIELD_LENGTH>(input_notes[i].amount);

            inputs_map.insert(
                input_notes[i].asset_id,
                inputs_map.get(input_notes[i].asset_id).unwrap_unchecked() + note_amount,
            );
        }
    }

    for i in 0..MAX_NOTES_AMOUNT {
        if output_notes[i].amount != [0; 32] {
            let converted_output_note: u32 =
                u8_array_to_u32::<FIELD_LENGTH>(output_notes[i].amount);
            let converted_external_amount: u32 =
                u8_array_to_u32::<FIELD_LENGTH>(external_amounts[i]);

            if (converted_external_amount > 0) {
                assert(output_notes[i].owner == DEAD_OWNER, "Invalid burn note");
                assert(
                    converted_output_note == converted_external_amount,
                    "Ahh the sneaky edge case eh",
                );
            }

            let output_leaf_note = calculate_leaf(
                output_notes[i].owner,
                output_notes[i].amount,
                output_notes[i].asset_id,
            );

            assert(output_leaf_note == output_hashes[i], "invalid hash");

            outputs_map.insert(
                output_notes[i].asset_id,
                outputs_map.get(output_notes[i].asset_id).unwrap_unchecked()
                    + converted_output_note,
            );
        }
    }

    // check that tracked summed inputs == tracked summed outputs
    assert(inputs_map.len() == outputs_map.len());

    // // check that sum of inputs == outputs
    for i in 0..MAX_NOTES_AMOUNT {
        if (inputs_map.get(input_notes[i].asset_id).unwrap_unchecked() != 0) {
            assert(
                inputs_map.get(input_notes[i].asset_id).unwrap_unchecked()
                    == outputs_map.get(output_notes[i].asset_id).unwrap_unchecked(),
            );
        }
    }
}

#[test]
fn test_end_to_end() {
    let alice_private_key = [
        145, 177, 186, 117, 58, 131, 87, 110, 133, 176, 188, 65, 179, 51, 94, 88, 168, 245, 160,
        100, 189, 67, 121, 199, 11, 82, 149, 34, 18, 119, 170, 142,
    ];
    let alice_pub_key = [
        21, 224, 205, 149, 237, 0, 205, 99, 38, 172, 38, 165, 191, 145, 144, 38, 70, 82, 182, 85,
        249, 156, 90, 212, 128, 198, 159, 121, 167, 52, 30, 202,
    ];
    // bob_private_key
    let _ = [
        4, 184, 77, 195, 153, 211, 56, 75, 196, 183, 213, 232, 133, 103, 22, 10, 137, 126, 12, 209,
        187, 56, 39, 19, 196, 219, 15, 74, 149, 209, 130, 95,
    ];
    let bob_pub_key = [
        105, 255, 33, 97, 120, 18, 111, 154, 254, 68, 203, 82, 17, 200, 107, 125, 230, 75, 26, 117,
        145, 48, 60, 55, 253, 154, 157, 71, 223, 211, 50, 242,
    ];

    let leaf_index = [0, 0, 0, 0, 0, 0, 0, 0];
    let path_data = [
        [
            225, 188, 32, 84, 1, 218, 94, 142, 142, 39, 30, 57, 108, 223, 235, 83, 229, 116, 193,
            154, 246, 111, 250, 101, 228, 127, 173, 24, 166, 30, 143, 183,
        ],
        [
            7, 248, 95, 149, 4, 109, 100, 127, 143, 202, 71, 4, 107, 128, 239, 148, 72, 84, 140,
            151, 151, 137, 119, 43, 203, 225, 212, 34, 105, 82, 110, 121,
        ],
        [
            58, 231, 119, 93, 38, 190, 124, 252, 251, 108, 12, 165, 203, 174, 196, 195, 188, 90,
            234, 110, 163, 104, 222, 137, 207, 142, 239, 207, 31, 166, 186, 228,
        ],
        [
            29, 202, 13, 73, 141, 3, 146, 152, 95, 18, 226, 34, 50, 72, 6, 83, 23, 139, 177, 55,
            145, 135, 134, 33, 215, 38, 19, 47, 88, 131, 44, 198,
        ],
        [
            182, 185, 182, 183, 17, 17, 184, 185, 53, 1, 120, 226, 10, 143, 166, 41, 218, 118, 249,
            158, 254, 20, 184, 81, 28, 63, 110, 140, 0, 101, 98, 18,
        ],
    ];
    let root = [
        185, 135, 16, 52, 48, 96, 222, 148, 48, 194, 118, 248, 158, 210, 212, 31, 35, 147, 40, 145,
        2, 175, 229, 172, 12, 165, 56, 149, 231, 108, 139, 178,
    ];
    let path = [1, 1, 1, 1, 1];
    let amount = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 39, 0, 0, 0, 0, 0, 0,
        0, 0,
    ];
    let asset_id =
        [192, 42, 170, 57, 178, 35, 254, 141, 10, 14, 92, 79, 39, 234, 217, 8, 60, 117, 108, 194];
    let nullifier = [
        88, 136, 143, 223, 14, 214, 202, 215, 213, 232, 164, 136, 210, 151, 251, 58, 104, 138, 123,
        229, 24, 183, 11, 37, 99, 90, 197, 19, 138, 159, 238, 234,
    ];

    let input_note = InputNoteSpend {
        address: alice_pub_key,
        private_key: alice_private_key,
        leaf_index: leaf_index,
        path: path,
        path_data: path_data,
        amount: amount,
        asset_id: asset_id,
    };

    let output_note = OutputNoteAmount { amount: amount, asset_id: asset_id, owner: bob_pub_key };


    let empty_field = [0; 32];
    let external_amount = [0; 32];
    let empty_asset_id = [0; 20];

    let empty_input_note = InputNoteSpend {
        address: empty_field,
        private_key: empty_field,
        leaf_index: [0, 0, 0, 0, 0, 0, 0, 0],
        path: path,
        path_data: path_data,
        amount: external_amount,
        asset_id: empty_asset_id,
    };

    let external_amounts = [external_amount, external_amount, external_amount, external_amount];

    let empty_output_note =
        OutputNoteAmount { amount: external_amount, asset_id: empty_asset_id, owner: empty_field };

    let output_hash = [
        248, 62, 191, 121, 102, 122, 151, 234, 79, 205, 74, 235, 215, 70, 167, 174, 29, 151, 85, 18,
        142, 144, 62, 225, 246, 123, 3, 70, 88, 209, 27, 146,
    ];

    main(
        root,
        [input_note, empty_input_note, empty_input_note, empty_input_note],
        [output_note, empty_output_note, empty_output_note, empty_output_note],
        external_amounts,
        [nullifier, [0; 32], [0; 32], [0; 32]],
        [output_hash, [0; 32], [0; 32], [0; 32]],
    );
}
