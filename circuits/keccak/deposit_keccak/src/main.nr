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
        let concat = concatenate_bytes32_arrays(input1, input2);
        current = std::hash::keccak256(concat, concat.len());
    }
    current
}

fn main(x: Field, y: pub Field) {
    assert(x != y);
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

#[test]
fn test_main() {
    main(1, 2);
    // Uncomment to make test fail
    // main(1, 1);
}
