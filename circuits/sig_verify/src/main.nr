use dep::pum::sig_verify::sig_verify;

fn main(
    s: Field,
    r_point_x: Field,
    r_point_y: Field,
    a_point_x: Field,
    a_point_y: Field,
    hashed_data_mod: Field,
) {
    sig_verify(
        s,
        r_point_x,
        r_point_y,
        a_point_x,
        a_point_y,
        hashed_data_mod,
    );
}

#[test]
fn test_main() {
    let s = 9433542191966121595038338481692622117969362708974223872381781757230788478257;
    let r_point_x = 12143819321338719521185626133028502939234064632296556775138324697915221654651;
    let r_point_y = 20074131356615822208770545599252946769984593165978497001274779973332169773999;
    let a_point_x = 414307288439776939451207388462826342822364268833363196167587225599630913764;
    let a_point_y = 16298014798848247278504574911734719567503069246519009660794850501628037273246;
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
