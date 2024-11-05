use std::embedded_curve_ops::multi_scalar_mul;
use std::embedded_curve_ops::EmbeddedCurvePoint;
use std::embedded_curve_ops::EmbeddedCurveScalar;
use std::field::bn254;

use std::ec::tecurve::affine::{Curve, Point};


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
  let bjj = Curve::new(
    168700,
    168696,
    Point::new(
      995203441582195749578291179787384436505546430278305826713579947235728471134,
      5472060717959818805561601436314318772137091100104008585924551046643952123905
    )
  );

  let base_point = Point::new(
    6822643173076850086669063981200675861034234425876310494228829770726075732893,
    9156654395656950371299901424185770236726741503478930161752204964343448620279
  );

  let r_point = Point::new(
    r_point_x,
    r_point_y
  );
  let a_point =  Point::new(
    a_point_x,
    a_point_y
  );


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