use std::embedded_curve_ops::multi_scalar_mul;
use std::embedded_curve_ops::EmbeddedCurvePoint;
use std::embedded_curve_ops::EmbeddedCurveScalar;

/**
* The signature verify function 
*
*/
fn sig_verify(point_x: Field, point_y: Field, scalar_low: Field, scalar_high: Field) {
  let points = EmbeddedCurvePoint {
    x: point_x,
    y: point_y,
    is_infinite: false,
  };

  let scalars = EmbeddedCurveScalar {
    lo: scalar_low,
    hi: scalar_high
  };

  let point = multi_scalar_mul([points], [scalars]);

  let neg = point.neg();
}

#[test]
fn test_main() {
  // sig_verify(1, 2);
} 