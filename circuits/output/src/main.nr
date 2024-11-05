use dep::pum::output_verify::output_verify;

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
    output_verify(
        amount,
        binding,
        assetId,
        assetIdHash,
        publicKey,
        v_point_x,
        v_point_y,
        r_point_x,
        r_point_y,
        c_point_x,
        c_point_y,
        r_amount,
    );
}

// amount: '0x0',
// blinding: '0x1139d5d6ead9efecdef807c90dc09ad4c9afe28ccc498f56df2454fa9e0307a4',
// assetId: '0x55534443',
// assetIdHash: '0x2c7f9621cfba77d9083954bdd3447d0e1935f41aa44b3ab9ae89048ed8d8b09f',
// spender: '19980907986724994705911215763367534624782247508285043265576239390007375044755',
// v: [
//   '0x0ce746b038f3f71167d459af646cacde7124a5f81b67ee3c7d804cdcbc17a60a',
//   '0x040ffd37a1d3cf4d2c842874d7122f83aa057c115b419e284c168ea0cc43fad8'
// ],
// r: [
//   '0x0f157aac3718c993ce6137d3c6ac9587bd11c47182cea2312d705dbc0093139d',
//   '0x143e7b940a7846293635d558bb3e76613ea5c1ddb57128d155fd48ba8d404cf7'
// ],
// rc: [
//   '5531182836578735961418047311924719807323325453517202061834912334217344742604',
//   '0x2d1b862f0b1765ef0ddfce07902a2a41176c3297452f9db91dd7153990fb8286',
//   '0x19cd73696ab235c0e5d01d5a2bb535f8c52654f6f9d026a0e2cb115c98f99154'
// ]

#[test]
fn test_main() {
    let amount = 0x28;
    let binding = 0x8039a5c6d743513f8e6d5164c6abed86eea56e8821a3dd97f3f0873cfcdfe6d;
    let asset_id = 0x55533643;
    let asset_id_hash =0x2c7f9621cfba77d9083954bdd3447d0e1935f41aa44b3ab9ae89048ed8d8b09f;
    let public_key = 4242624232892793970061236806713091417341636279779913040477865471258893154534;
    let v_point_x = 0x0ce746b038f3f71167d459af646cacde7124a5f81b67ee3c7d804cdcbc17a60a;
    let v_point_y = 0x040ffd37a1d3cf4d2c842874d7122f83aa057c115b419e284c168ea0cc43fad8;
    let r_point_x = 0x0f157aac3718c993ce6137d3c6ac9587bd11c47182cea2312d705dbc0093139d;
    let r_point_y =0x143e7b940a7846293635d558bb3e76613ea5c1ddb57128d155fd48ba8d404cf7;
    let c_point_x = 0x01e2b75934b61ceac6aef1097fd79c064712d1107aea04c5f1cf81884830f050;
    let c_point_y = 0x02176f5707f0e8d958def8cd57942479e05fc18d5658c22be46de4c57804c89a;
    let r_amount = 6311667553853621217640224099899233941980549243390918545380543109229435564784;

    output_verify(
        amount,
        binding,
        asset_id,
        asset_id_hash,
        public_key,
        v_point_x,
        v_point_y,
        r_point_x,
        r_point_y,
        c_point_x,
        c_point_y,
        r_amount,
    );
}
