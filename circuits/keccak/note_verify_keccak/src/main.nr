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
    path_indices: [Field; N],
    hash_path: [[u8; 32]; N],
) -> [u8; 32] {
    let mut current = leaf;
    for i in 0..N {
        let path_bit = path_indices[i];
        let (hash_left, hash_right) = if path_bit == 0 {
            (hash_path[i], current)
        } else {
            (current, hash_path[i])
        };
        let concat = concatenate_bytes32_arrays(hash_left, hash_right);
        current = std::hash::keccak256(concat, concat.len());
    }
    current
}

pub fn calculate_leaf(address: [u8; 32], amount: [u8; 32], asset_id: [u8; 8]) -> [u8; 32] {
    // need to combine into one giga array
    let mut concat_values = [0; 72];
    for i in 0..32 {
        concat_values[i] = address[i];
    }
    for i in 0..32 {
        concat_values[i + 32] = amount[i];
    }
    for i in 0..8 {
        concat_values[i + 64] = asset_id[i];
    }

    let current = std::hash::keccak256(concat_values, 72);

    current
}

pub fn calculate_nullifier(
    leaf_index: [u8; 8], // TODO investigate length
    address: [u8; 32],
    amount: [u8; 32],
    asset_id: [u8; 8],
) -> [u8; 32] {
    let mut concat_values = [0; 80];
    for i in 0..8 {
        concat_values[i] = leaf_index[i];
    }
    for i in 0..32 {
        concat_values[i + 8] = address[i];
    }
    for i in 0..32 {
        concat_values[i + 40] = amount[i];
    }
    for i in 0..8 {
        concat_values[i + 72] = asset_id[i];
    }

    std::hash::keccak256(concat_values, 80)
}

struct InputNoteSpend {
    leaf_index: [u8; 8],
    path: [Field; 5],
    path_data: [Field; 5],
    address: [u8; 32],
    amount: [u8; 32],
    asset_id: [u8; 8],
    nullifier: [u8; 32],
}

struct OutputNoteAmount {
    amount: Field,
    asset_id: Field,
    owner: Field,
    external_amount: Field,
}

fn main(
    private_key: [u8; 32],
    root: pub Field,
    input_notes: [InputNoteSpend; 5],
    output_notes: [OutputNoteAmount; 5],
    external_amounts: [Field; 5],
) {
    let senderPubKey = std::hash::keccak256(private_key, 32);

    let mut sum_inputs = 0;
    // loop through all input notes and assure they belong to users pub key
    for i in 0..input_notes.len() {
        assert(senderPubKey == input_notes[i].address, "invalid spender");

        let mut reconstructed_amount: u32 = 0;
        for i in 0..4 {
            reconstructed_amount |= (input_notes[i].amount[i] as u32) << (i * 8);
        }

        sum_inputs = sum_inputs + reconstructed_amount;

        let note_leaf = calculate_leaf(
            input_notes[i].address,
            input_notes[i].amount,
            input_notes[i].asset_id,
        );

        let reconstructed_nullifier = calculate_nullifier(
            input_notes[i].leaf_index,
            input_notes[i].address,
            input_notes[i].amount,
            input_notes[i].asset_id,
        );

        assert(input_notes[i].nullifier == reconstructed_nullifier, "Invalid nullifier");
    }

    let sum_outputs = 0;
}

fn u32_to_u8_array(value: u32) -> [u8; 5] {
    let mut array: [u8; 5] = [0; 5];
    for i in 0..4 {
        array[i] = ((value >> (i * 8)) & 0xFF) as u8;
    }
    array
}

#[test]
fn test_u32_to_u8_array() {
    // Test case 1
    let value: u32 = 0x12345678;
    let expected_array: [u8; 5] = [0x78, 0x56, 0x34, 0x12, 0x00];
    let result_array = u32_to_u8_array(value);
    assert(result_array == expected_array, "Array does not match the expected value for 0x12345678");

    // Test case 2
    let value: u32 = 0x87654321;
    let expected_array: [u8; 5] = [0x21, 0x43, 0x65, 0x87, 0x00];
    let result_array = u32_to_u8_array(value);
    assert(result_array == expected_array, "Array does not match the expected value for 0x87654321");

    // Test case 3
    let value: u32 = 0x00000000;
    let expected_array: [u8; 5] = [0x00, 0x00, 0x00, 0x00, 0x00];
    let result_array = u32_to_u8_array(value);
    assert(result_array == expected_array, "Array does not match the expected value for 0x00000000");

    // Test case 4
    let value: u32 = 0xFFFFFFFF;
    let expected_array: [u8; 5] = [0xFF, 0xFF, 0xFF, 0xFF, 0x00];
    let result_array = u32_to_u8_array(value);
    assert(result_array == expected_array, "Array does not match the expected value for 0xFFFFFFFF");

    // Test case 5
    let value: u32 = 0xAABBCCDD;
    let expected_array: [u8; 5] = [0xDD, 0xCC, 0xBB, 0xAA, 0x00];
    let result_array = u32_to_u8_array(value);
    assert(result_array == expected_array, "Array does not match the expected value for 0xAABBCCDD");
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
