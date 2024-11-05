use std::hash::poseidon2;

// TODO move to PUM lib
pub fn compute_poseidon_merkle_root<let N: u32>(
    leaf: Field,
    index: Field,
    hash_path: [Field; N],
) -> Field {
    let index_bits: [u1; N] = index.to_le_bits();
    let mut current = leaf;
    for i in 0..N {
        let path_bit = index_bits[i] as bool;
        let (hash_left, hash_right) = if path_bit {
            (hash_path[i], current)
        } else {
            (current, hash_path[i])
        };
        current = poseidon2::Poseidon2::hash([hash_left, hash_right], 2);
    }
    current
}

fn main(
    root: Field,
    privateKey: Field,
    amount: Field,
    binding: Field,
    asset: Field,
    pathIndex: Field,
    nullifier: pub Field,
    pathElements: [Field; 5],
    commitment: Field,
    v_point_x: Field,
    v_point_y: Field,
    r_point_x: Field,
    r_point_y: Field,
    c_point_x: Field,
    c_point_y: Field,
) {
    let public_key = poseidon2::Poseidon2::hash([privateKey], 1);
    let commitment_hash = poseidon2::Poseidon2::hash([amount, public_key, binding, asset], 4);
    let sig_hash = poseidon2::Poseidon2::hash([privateKey, commitment_hash, pathIndex], 3);
    let nullifier_hash = poseidon2::Poseidon2::hash([commitment_hash, pathIndex, sig_hash], 3);

    let reconstructed_root = compute_poseidon_merkle_root(commitment_hash, pathIndex, pathElements);

    assert(reconstructed_root == root, "invalid merkle proof");

    // TODO check value commitment then we are in business
}

#[test]
fn test_main() {}
