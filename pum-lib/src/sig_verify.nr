use std::field::bn254;
use std::ec::tecurve::affine::{Curve, Point};

/**
* The signature verification function currently used in Roman Kyoto 
*/
fn sig_verify(
    s: Field,
    r_point_x: Field,
    r_point_y: Field,
    a_point_x: Field,
    a_point_y: Field,
    hashed_data_mod: Field,
) {
    let bjj = Curve::new(
        168700,
        168696,
        // TODO document this value
        Point::new(
            995203441582195749578291179787384436505546430278305826713579947235728471134,
            5472060717959818805561601436314318772137091100104008585924551046643952123905,
        ),
    );

    // TODO document this value
    let base_point = Point::new(
        6822643173076850086669063981200675861034234425876310494228829770726075732893,
        9156654395656950371299901424185770236726741503478930161752204964343448620279,
    );

    let r_point = Point::new(r_point_x, r_point_y);
    let a_point = Point::new(a_point_x, a_point_y);

    let negged_base_point = base_point.negate();
    let mul_by_s = bjj.msm([s], [negged_base_point]);
    let add_rp = bjj.add(mul_by_s, r_point);
    let ap_mul_c = bjj.msm([hashed_data_mod], [a_point]);

    let z = bjj.add(add_rp, ap_mul_c);

    assert(z.x == 0, "Not a valid signature");
}

#[test]
fn test_main() {
    let s = 9433542191966121595038338481692622117969362708974223872381781757230788478257;
    let r_point_x = 12143819321338719521185626133028502939234064632296556775138324697915221654651;
    let r_point_y = 20074131356615822208770545599252946769984593165978497001274779973332169773999;
    let a_point_x = 414307288439776939451207388462826342822364268833363196167587225599630913764;
    let a_point_y = 16298014798848247278504574911734719567503069246519009660794850501628037273246;

    // this is uint256 _c = uint256(keccak256(data)) % EdOnBN254.N; in solidity
    let hashed_data_mod =
        19723751451262953313713137900621821180413630117769391257529298277378406357992;

    sig_verify(
        s,
        r_point_x,
        r_point_y,
        a_point_x,
        a_point_y,
        hashed_data_mod,
    );
}
