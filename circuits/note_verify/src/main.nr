use std::hash::poseidon2;

fn main(
    address: Field,
    amount: Field,
    asset_id: Field,
) {
    println(address);

    println(poseidon2::Poseidon2::hash([address, amount, asset_id], 3));
}

#[test]
fn test_main() {
    let address = 0x57a22d2c257f778a2af2ba7a34b42f777c11606d;
    let amount = 50;
    let asset_id = 69_57_420;

    main(address, amount, asset_id);

    // Uncomment to make test fail
    // main(1, 1);
}
