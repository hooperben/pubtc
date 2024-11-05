fn main(
    amount: Field,
    binding: Field,
    assetId: Field,
    assetIdHash: Field,
    publicKey: Field,
    // points
    v_point_x: Field,
    v_point_y: Field,
    r_point_x: Field,
    r_point_y: Field,
    c_point_x: Field,
    c_point_y: Field,
    r_amount: Field,
) {
    let commmitment = poseidon2::Poseidon2::hash([
        amount,
        publicKey,
        binding,
        assetIdHash,
    ], 4);

    let asset_hash = poseidon2::Poseidon2::hash([
        amount,
        publicKey,
        binding,
        assetIdHash,
    ], 4);

    assert(asset_hash == assetIdHash, "");
}

#[test]
fn test_main() {
}
