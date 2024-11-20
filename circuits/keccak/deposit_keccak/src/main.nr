fn main(x: Field, y: pub Field) {
    let digest = std::hash::keccak256([1], 1);
    println(digest);
    assert(x != y);
}

#[test]
fn test_main() {
    main(1, 2);

    // Uncomment to make test fail
    // main(1, 1);
}
