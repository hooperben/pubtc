global AMOUNT_LENGTH = 5;

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

fn main(hash: pub [u8; 32], pubKey: [u8; 32], amount: pub [u8; AMOUNT_LENGTH], asset_id: [u8; 8]) {
    let note_leaf = calculate_leaf(pubKey, amount, asset_id);
    assert(note_leaf == hash);
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
    // main(1, 2);
    // Uncomment to make test fail
    // main(1, 1);
    let alice_pub_key = [
        21, 224, 205, 149, 237, 0, 205, 99, 38, 172, 38, 165, 191, 145, 144, 38, 70, 82, 182, 85,
        249, 156, 90, 212, 128, 198, 159, 121, 167, 52, 30, 202,
    ];
    let amount = [69, 0, 0, 0, 0];
    let asset_id = [0, 0, 0, 0, 0, 0, 0, 1];

    
}
