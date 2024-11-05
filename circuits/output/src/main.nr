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

// amount: '0x64',
// blinding: '0x188a028476aa72c380dde7f75b60f7b97877cacea991d40dba6e25710092ca2b',
// assetId: 1431520323n,
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
//   '11982678878669839261354965074805131518820444735643011213332767527373884462794',
//   '0x1be0ac61fa1bcb0d7e9cbda02d39686ce703933f9cbc4b5e811b592bc17dc944',
//   '0x016b5db4ec8a1a66c6b3582a7e87b62aec6bfeb8faf0d516656c5f2eb5d68f50'
// ]

#[test]
fn test_main() {
    let amount = 0x64;
    let binding = 0x188a028476aa72c380dde7f75b60f7b97877cacea991d40dba6e25710092ca2b;
    let asset_id = 1431520323;
    let asset_id_hash = 0x17b2958f80c71455d15b2d1fd342a7d6e3c8109cf2db93e1305504f5ce2f715c;
    let public_key = 19980907986724994705911215763367534624782247508285043265576239390007375044755;
    let v_point_x = 0x0ce746b038f3f71167d459af646cacde7124a5f81b67ee3c7d804cdcbc17a60a;
    let v_point_y = 0x040ffd37a1d3cf4d2c842874d7122f83aa057c115b419e284c168ea0cc43fad8;
    let r_point_x = 0x0f157aac3718c993ce6137d3c6ac9587bd11c47182cea2312d705dbc0093139d;
    let r_point_y = 0x143e7b940a7846293635d558bb3e76613ea5c1ddb57128d155fd48ba8d404cf7;
    let c_point_x = 0x1be0ac61fa1bcb0d7e9cbda02d39686ce703933f9cbc4b5e811b592bc17dc944;
    let c_point_y = 0x016b5db4ec8a1a66c6b3582a7e87b62aec6bfeb8faf0d516656c5f2eb5d68f50;
    let r_amount = 11982678878669839261354965074805131518820444735643011213332767527373884462794;

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
