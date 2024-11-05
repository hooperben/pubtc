use std::embedded_curve_ops::multi_scalar_mul;
use std::embedded_curve_ops::EmbeddedCurvePoint;
use std::embedded_curve_ops::EmbeddedCurveScalar;
use std::field::bn254;

/**
* The signature verify function 
*

Our Base point is defined as the following:
x: 6822643173076850086669063981200675861034234425876310494228829770726075732893
y: 9156654395656950371299901424185770236726741503478930161752204964343448620279

TODO investigate where these figures came from
*/
fn sig_verify(
  s: Field,
  r_point_x: Field,
  r_point_y: Field,
  a_point_x: Field,
  a_point_y: Field,
  message: Field
) {
  // TODO this is a different N value to what is in jubjub
  let edbn254_n = bn254::decompose(21888242871839275222246405745257275088548364400416034343698204186575808495616);

  let base_point = EmbeddedCurvePoint {
    x: 6822643173076850086669063981200675861034234425876310494228829770726075732893,
    y: 9156654395656950371299901424185770236726741503478930161752204964343448620279,
    is_infinite: false,
  };

  let r_point = EmbeddedCurvePoint {
    x: r_point_x,
    y: r_point_y,
    is_infinite: false,
  };

  let a_point = EmbeddedCurvePoint {
    x: a_point_x,
    y: a_point_y,
    is_infinite: false,
  };


  // let point = multi_scalar_mul([points], [scalars]);

  // let neg = point.neg();
}

#[test]
fn test_main() {
  // sig_verify(1, 2);
  let base_point = EmbeddedCurvePoint {
    x: 6822643173076850086669063981200675861034234425876310494228829770726075732893,
    y: 9156654395656950371299901424185770236726741503478930161752204964343448620279,
    is_infinite: false,
  };
  
  let neg_base_point = base_point.neg();

  println(base_point);
  println(neg_base_point);

  // let sums = base_point.add(neg_base_point);

  // println(sums);
} 