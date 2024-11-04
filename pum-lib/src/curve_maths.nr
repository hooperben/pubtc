
fn curve_maths(x: Field, y: pub Field) {
  assert(x != y);
}

#[test]
fn test_main() {
  curve_maths(1, 2);

  // Uncomment to make test fail
  // main(1, 1);
}
