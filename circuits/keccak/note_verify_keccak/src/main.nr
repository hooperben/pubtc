use std::{hash::{poseidon2::Poseidon2Hasher, BuildHasherDefault}, collections::map::HashMap};

global MAX_NOTES_AMOUNT = 3;
global AMOUNT_LENGTH = 5;

pub fn concatenate_bytes32_arrays(arr1: [u8; 32], arr2: [u8; 32]) -> [u8; 64] {
    let mut result = [08; 64];
    for i in 0..32 {
        result[i] = arr1[i];
    }
    for i in 0..32 {
        result[i + 32] = arr2[i];
    }
    result
}

pub fn compute_keccak_merkle_hash<let N: u32>(
    leaf: [u8; 32],
    path: [Field; N],
    path_data: [[u8; 32]; N],
) -> [u8; 32] {
    let mut current = leaf;
    for i in 0..N {
        let path_bit = path[i];
        let (hash_left, hash_right) = if path_bit == 0 {
            (path_data[i], current)
        } else {
            (current, path_data[i])
        };
        let concat = concatenate_bytes32_arrays(hash_left, hash_right);
        current = std::hash::keccak256(concat, concat.len());
    }
    current
}

pub fn calculate_leaf(
    address: [u8; 32],
    amount: [u8; AMOUNT_LENGTH],
    asset_id: [u8; 8],
) -> [u8; 32] {
    // need to combine into one giga array
    let mut concat_values = [0; 72];
    for i in 0..32 {
        concat_values[i] = address[i];
    }
    for i in 0..5 {
        concat_values[i + 32] = amount[i];
    }
    for i in 0..8 {
        concat_values[i + 37] = asset_id[i];
    }

    let current = std::hash::keccak256(concat_values, 45);

    current
}

pub fn calculate_nullifier(
    leaf_index: [u8; 8], // TODO investigate length
    address: [u8; 32],
    amount: [u8; AMOUNT_LENGTH],
    asset_id: [u8; 8],
) -> [u8; 32] {
    let mut concat_values = [0; 80];
    for i in 0..8 {
        concat_values[i] = leaf_index[i];
    }
    for i in 0..32 {
        concat_values[i + 8] = address[i];
    }
    for i in 0..5 {
        concat_values[i + 40] = amount[i];
    }
    for i in 0..8 {
        concat_values[i + 45] = asset_id[i];
    }

    std::hash::keccak256(concat_values, 53)
}

// pub fn to_le_bits<let N: u32>
fn u8_array_to_u32<let N: u32>(array: [u8; N]) -> u32 {
    let mut value: u32 = 0;
    for i in 0..4 {
        value |= (array[i] as u32) << (i * 8);
    }
    value
}

struct InputNoteSpend {
    address: [u8; 32],
    private_key: [u8; 32],
    leaf_index: [u8; 8],
    path: [Field; 5],
    path_data: [[u8; 32]; 5],
    amount: [u8; AMOUNT_LENGTH], // largest value is 2^(8*5) - 1 = 1,099,511,627,775
    asset_id: [u8; 8],
}

struct OutputNoteAmount {
    amount: [u8; AMOUNT_LENGTH],
    asset_id: [u8; 8],
    owner: [u8; 32],
}

fn main(
    root: pub [u8; 32],
    input_notes: [InputNoteSpend; MAX_NOTES_AMOUNT],
    output_notes: [OutputNoteAmount; MAX_NOTES_AMOUNT],
    // external_amounts and nullifiers are part of input_notes, but they need to be public
    external_amounts: pub [[u8; AMOUNT_LENGTH]; MAX_NOTES_AMOUNT],
    nullifiers: pub [[u8; 32]; MAX_NOTES_AMOUNT],
) {
    let DEAD_OWNER = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0,
    ];

    let mut inputs_map: HashMap<[u8; 8], u32, 10, BuildHasherDefault<Poseidon2Hasher>> =
        HashMap::default();

    let mut outputs_map: HashMap<[u8; 8], u32, 10, BuildHasherDefault<Poseidon2Hasher>> =
        HashMap::default();

    for i in 0..input_notes.len() {
        // given that we have 10 inputs, some can be empty
        if input_notes[i].amount != [0, 0, 0, 0, 0] {
            let senderPubKey = std::hash::keccak256(input_notes[i].private_key, 32);

            assert(senderPubKey == input_notes[i].address, "invalid spender");

            let reconstructed_nullifier = calculate_nullifier(
                input_notes[i].leaf_index,
                input_notes[i].address,
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

            let converted_note_amount: u32 = u8_array_to_u32::<5>(input_notes[i].amount);

            inputs_map.insert(
                input_notes[i].asset_id,
                inputs_map.get(input_notes[i].asset_id).unwrap_unchecked() + converted_note_amount,
            );
        }
    }

    for i in 0..output_notes.len() {
        if output_notes[i].amount != [0, 0, 0, 0, 0] {
            let converted_output_note: u32 = u8_array_to_u32::<5>(output_notes[i].amount);
            let converted_external_amount: u32 = u8_array_to_u32::<5>(external_amounts[i]);

            if (converted_external_amount > 0) {
                assert(output_notes[i].owner == DEAD_OWNER, "Invalid burn note");
                assert(
                    converted_output_note == converted_external_amount,
                    "Ahh the sneaky edge case eh",
                );
            }
            println("output insert");
            println(converted_output_note);

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
    for i in 0..input_notes.len() {
        if (inputs_map.get(input_notes[i].asset_id).unwrap_unchecked() != 0) {
            assert(
                inputs_map.get(input_notes[i].asset_id).unwrap_unchecked()
                    == outputs_map.get(output_notes[i].asset_id).unwrap_unchecked(),
            );
            inputs_map.remove(input_notes[i].asset_id);
        }
    }
}

#[test]
fn test_end_to_end() {
    let root = [
        191, 221, 88, 55, 58, 219, 60, 136, 3, 251, 231, 208, 162, 133, 123, 74, 207, 213, 253, 228,
        170, 68, 149, 97, 102, 150, 28, 226, 202, 1, 95, 105,
    ];
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
        191, 221, 88, 55, 58, 219, 60, 136, 3, 251, 231, 208, 162, 133, 123, 74, 207, 213, 253, 228,
        170, 68, 149, 97, 102, 150, 28, 226, 202, 1, 95, 105,
    ];
    let path = [1, 1, 1, 1, 1];
    let amount = [69, 0, 0, 0, 0];
    let asset_id = [0, 0, 0, 0, 0, 0, 0, 1];
    let nullifier = [
        161, 230, 197, 214, 250, 203, 183, 75, 241, 141, 99, 90, 128, 10, 228, 242, 53, 196, 36,
        169, 221, 224, 173, 149, 250, 167, 70, 27, 171, 252, 133, 181,
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

    let external_amount = [0, 0, 0, 0, 0];

    let empty_input_note = InputNoteSpend {
        address: [0; 32],
        private_key: [0; 32],
        leaf_index: [0, 0, 0, 0, 0, 0, 0, 0],
        path: path,
        path_data: path_data,
        amount: external_amount,
        asset_id: [0, 0, 0, 0, 0, 0, 0, 0],
    };

    let external_amounts = [external_amount, external_amount, external_amount];

    let output_note = OutputNoteAmount { amount: amount, asset_id: asset_id, owner: bob_pub_key };
    let empty_output_note = OutputNoteAmount {
        amount: external_amount,
        asset_id: [0, 0, 0, 0, 0, 0, 0, 0],
        owner: [0; 32],
    };

    main(
        root,
        [input_note, empty_input_note, empty_input_note],
        [output_note, empty_output_note, empty_output_note],
        external_amounts,
        [nullifier, nullifier, nullifier],
    );
}

#[test]
fn test_note_hash() {
    let pub_key = [
        21, 224, 205, 149, 237, 0, 205, 99, 38, 172, 38, 165, 191, 145, 144, 38, 70, 82, 182, 85,
        249, 156, 90, 212, 128, 198, 159, 121, 167, 52, 30, 202,
    ];
    // let amount = u8_array_to_u32::<5>();
    let asset_id = [0, 0, 0, 0, 0, 0, 0, 1];

    let expected_output = [
        245, 153, 202, 209, 68, 145, 239, 140, 170, 236, 80, 57, 178, 196, 184, 54, 42, 217, 132,
        239, 81, 172, 184, 253, 221, 80, 114, 24, 202, 62, 247, 126,
    ];

    let recreated_output = calculate_leaf(pub_key, [69, 0, 0, 0, 0], asset_id);

    assert(expected_output == recreated_output);
}

#[test]
fn test_u8_array_to_u32() {
    // Test case 1
    let array: [u8; 5] = [0x78, 0x56, 0x34, 0x12, 0x00];
    let expected_value: u32 = 0x12345678;
    let result_value = u8_array_to_u32(array);
    assert(
        result_value == expected_value,
        "Value does not match the expected value for [0x78, 0x56, 0x34, 0x12]",
    );

    // Test case 2
    let array: [u8; 5] = [0x21, 0x43, 0x65, 0x87, 0x00];
    let expected_value: u32 = 0x87654321;
    let result_value = u8_array_to_u32(array);
    assert(
        result_value == expected_value,
        "Value does not match the expected value for [0x21, 0x43, 0x65, 0x87]",
    );

    // Test case 3
    let array: [u8; 5] = [0x00, 0x00, 0x00, 0x00, 0x00];
    let expected_value: u32 = 0x00000000;
    let result_value = u8_array_to_u32(array);
    assert(
        result_value == expected_value,
        "Value does not match the expected value for [0x00, 0x00, 0x00, 0x00]",
    );

    // Test case 4
    let array: [u8; 5] = [0xFF, 0xFF, 0xFF, 0xFF, 0x00];
    let expected_value: u32 = 0xFFFFFFFF;
    let result_value = u8_array_to_u32(array);
    assert(
        result_value == expected_value,
        "Value does not match the expected value for [0xFF, 0xFF, 0xFF, 0xFF]",
    );

    // Test case 5
    let array: [u8; 5] = [0xDD, 0xCC, 0xBB, 0xAA, 0x00];
    let expected_value: u32 = 0xAABBCCDD;
    let result_value = u8_array_to_u32(array);
    assert(
        result_value == expected_value,
        "Value does not match the expected value for [0xDD, 0xCC, 0xBB, 0xAA]",
    );
}

#[test]
fn test_merkle_root() {
    let root = [
        75, 174, 36, 175, 3, 163, 133, 8, 242, 124, 157, 91, 28, 166, 85, 165, 116, 8, 192, 71, 248,
        173, 14, 37, 11, 97, 234, 230, 138, 210, 30, 72,
    ];

    let path_values = [
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

    let path_indices = [0, 0, 0, 0, 0];

    let leaf = [
        225, 188, 32, 84, 1, 218, 94, 142, 142, 39, 30, 57, 108, 223, 235, 83, 229, 116, 193, 154,
        246, 111, 250, 101, 228, 127, 173, 24, 166, 30, 143, 183,
    ];
    let reconstructed = compute_keccak_merkle_hash(leaf, path_indices, path_values);

    assert(reconstructed == root);
}

#[test]
fn text_concat_and_hash() {
    let input1 = [
        170, 157, 67, 22, 71, 40, 16, 224, 139, 111, 146, 178, 191, 38, 13, 168, 43, 12, 52, 124,
        54, 146, 10, 38, 15, 238, 100, 154, 32, 163, 144, 5,
    ];
    let input2 = [
        170, 157, 67, 22, 71, 40, 16, 224, 139, 111, 146, 178, 191, 38, 13, 168, 43, 12, 52, 124,
        54, 146, 10, 38, 15, 238, 100, 154, 32, 163, 144, 5,
    ];

    let concat = concatenate_bytes32_arrays(input1, input2);

    let concat_digest = std::hash::keccak256(concat, concat.len());
    let expected_output = [
        32, 197, 78, 96, 19, 101, 70, 238, 137, 212, 10, 17, 253, 86, 170, 139, 29, 23, 86, 109,
        201, 102, 178, 10, 54, 173, 41, 139, 211, 143, 193, 170,
    ];

    assert(expected_output == concat_digest);
}

#[test]
fn test_keccak() {
    let input = [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]; //  in TS: ethers.toUtf8Bytes("hello world");
    let input_digest = std::hash::keccak256(input, input.len());

    let output = [
        71, 23, 50, 133, 168, 215, 52, 30, 94, 151, 47, 198, 119, 40, 99, 132, 248, 2, 248, 239, 66,
        165, 236, 95, 3, 187, 250, 37, 76, 176, 31, 173,
    ]; // see scripts/keccak.ts on how we got this value
    assert(input_digest == output);
}
