fn spending_key(x: Field, y: pub Field) {
    assert(x != y);
}

#[test]
fn test_main() {
    spending_key(1, 2);
}
