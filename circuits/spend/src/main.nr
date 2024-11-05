use std::hash::poseidon2;
use std::ec::tecurve::affine::{Curve, Point};

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
    assert(commitment == commitment_hash, "incorrect commitment hash");

    let sig_hash = poseidon2::Poseidon2::hash([privateKey, commitment_hash, pathIndex], 3);
    let nullifier_hash = poseidon2::Poseidon2::hash([commitment_hash, pathIndex, sig_hash], 3);
    assert(nullifier == nullifier_hash, "incorrect nullifier hash");

    let reconstructed_root = compute_poseidon_merkle_root(commitment_hash, pathIndex, pathElements);
    assert(reconstructed_root == root, "invalid merkle proof");

    let bjj = Curve::new(
        168700,
        168696,
        // TODO document this value
        Point::new(
            995203441582195749578291179787384436505546430278305826713579947235728471134,
            5472060717959818805561601436314318772137091100104008585924551046643952123905,
        ),
    );

    let v_point = Point::new(v_point_x, v_point_y);
    let r_point = Point::new(r_point_x, r_point_y);

    let reconstructed_c_point = bjj.add(v_point, r_point);
    let c_point = Point::new(c_point_x, c_point_y);

    assert(c_point == reconstructed_c_point, "incorrect value commitment");
}

#[test]
fn test_main() {}
