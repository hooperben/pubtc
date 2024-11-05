use std::ec::tecurve::affine::{Curve, Point};
use std::hash::poseidon2;

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
    let asset_hash = poseidon2::Poseidon2::hash([assetId], 1);
    assert(asset_hash == assetIdHash, "invalid asset hash");

    // let commitment_hash = poseidon2::Poseidon2::hash([amount, publicKey, binding, assetIdHash], 4);

    // TODO document this value
    let base = Point::new(
        995203441582195749578291179787384436505546430278305826713579947235728471134,
        5472060717959818805561601436314318772137091100104008585924551046643952123905,
    );

    let r_point = Point::new(r_point_x, r_point_y);
    let v_point = Point::new(v_point_x, v_point_y);
    let c_point = Point::new(c_point_x, c_point_y);

    let bjj = Curve::new(168700, 168696, base);

    let r_r_point = bjj.msm([r_amount], [r_point]);
    let v_v_point = bjj.msm([amount], [v_point]);

    let sum = bjj.add(r_r_point, v_v_point);

    assert(sum == c_point, "Incorrect output");
}

#[test]
fn test_main() {}
