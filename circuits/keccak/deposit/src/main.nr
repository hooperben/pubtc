global ASSET_LENGTH = 20; // eth address representation (20 bytes)
global AMOUNT_LENGTH = 32;
global ADDRESS_LENGTH = 32;

global SUM_OF_INPUT_LEN = ADDRESS_LENGTH + AMOUNT_LENGTH + ASSET_LENGTH;

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

fn main(
    hash: pub [u8; ADDRESS_LENGTH],
    amount: pub [u8; AMOUNT_LENGTH],
    pub_key: [u8; ADDRESS_LENGTH],
    asset_id: [u8; ASSET_LENGTH],
) {
    // reconstruct the hash
    let note_leaf = calculate_leaf(pub_key, amount, asset_id);
    // check it matches
    assert(note_leaf == hash, "Invalid Deposit Hash");
    // IMPORTANT - the hash and amount are public, we need to check these fields in solidity too
}

#[test]
fn test_main() {
    let alice_pub_key = [
        21, 224, 205, 149, 237, 0, 205, 99, 38, 172, 38, 165, 191, 145, 144, 38, 70, 82, 182, 85,
        249, 156, 90, 212, 128, 198, 159, 121, 167, 52, 30, 202,
    ];
    let amount = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 39, 0, 0, 0, 0, 0, 0,
        0, 0,
    ];
    let asset_id =
        [192, 42, 170, 57, 178, 35, 254, 141, 10, 14, 92, 79, 39, 234, 217, 8, 60, 117, 108, 194];

    let note_hash = [
        248, 235, 0, 140, 179, 142, 141, 180, 70, 193, 118, 68, 106, 183, 233, 191, 111, 9, 78, 250,
        23, 96, 171, 113, 17, 100, 75, 241, 145, 97, 201, 55,
    ];

    main(note_hash, amount, alice_pub_key, asset_id);
}
