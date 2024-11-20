fn main(x: Field, y: pub Field) {
    let digest = std::hash::keccak256([1], 1);
    println(digest);

    let input = [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100];

    let input_digest = std::hash::keccak256(input, input.len());
    println(input_digest);

    assert(x != y);
}

#[test]
fn test_keccak() {
    let input = [104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]; //  in TS: ethers.toUtf8Bytes("hello world");
    let input_digest = std::hash::keccak256(input, input.len());

    let output = [
        71, 23, 50, 133, 168, 215, 52, 30, 94, 151, 47, 198, 119, 40, 99, 132, 248, 2, 248, 239, 66,
        165, 236, 95, 3, 187, 250, 37, 76, 176, 31, 173,
    ]; // see scripts/keccak.ts on how we got this value

    assert(input_digest == output);
}

#[test]
fn test_main() {
    main(1, 2);
    // Uncomment to make test fail
    // main(1, 1);
}
