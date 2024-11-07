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

fn main(address: Field, amount: Field, asset_id: Field, path: [Field; 5], path_data: [Field; 5]) {
    println(address);

    let leaf = poseidon2::Poseidon2::hash([address, amount, asset_id], 3);

    println(leaf);

    let rch = compute_poseidon_merkle_root(leaf, path, path_data);

    println(rch);
}

#[test]
fn test_main() {
    let address = 0x57a22d2c257f778a2af2ba7a34b42f777c11606d;
    let amount = 50;
    let asset_id = 69_57_420;

    let path = [1, 1, 1, 1, 1];
    let path_data = [
        0x0124e2a36fa18ec18993d7a281e8270ac93340ccf0785ab75e18cc3f4f74296c,
        0x1c936490f40b64fcb00e7b92a9a3cf68933465ec4d0a2fb7f1442c82810b894d,
        0x0bb7701b39c1ba621c04938017d07e70baeae094fbbf80606b978030ce78453e,
        0x154d4ad9f6ec7b100aa165d72d5068613d2c3129bb19a54fff82850f8cf0a464,
        0x010185aeae0f692bb0c289bed20658067d4cd55800d95b3a2d25d9696dc92d9a,
    ];

    main(address, amount, asset_id, path, path_data);
    // Uncomment to make test fail
    // main(1, 1);
}
