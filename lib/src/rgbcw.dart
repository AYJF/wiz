import 'dart:math';
import 'package:wiz/src/vec.dart';

// ignore_for_file: constant_identifier_names, non_constant_identifier_names
const ANGLE = (pi * 2) / 3;
final BASIS = [vecFromAngle(0), vecFromAngle(ANGLE), vecFromAngle(ANGLE * 2)];
// # the max value we will use for c and w
const CWMAX = 128;

// """This function computes the linear combination of two basis vectors that define a trapezoid.
// hueVec - a normalized vector in the hue color wheel (0..1, 0..1, 0..1)
// saturation - a single value representing the length of the hue vector (0..1)
// brightness - a separate value that may be passed in, and should be used in the Pilot.
// """
Map<String, dynamic> trapezoid(List<double> hueVec, double saturation) {
  List<dynamic> rgb = [];
  double cw = 0.0;
  List<double> rgbList = [];
  if (saturation <= EPSILON) {
    rgb = [0, 0, 0];
  } else {
    // we want to compute the actual RGB color of the saturated point as a linear
    // combination of no more than two of the basis vectors. first we have to figure
    // out which of the basis vectors we will use
    double maxAngle = cos((pi * 2 / 3) - EPSILON);

    List<int> mask = BASIS
        .map((vector) => vecDot(hueVec, vector) > maxAngle ? 1 : 0)
        .toList();

    int count = mask.fold(0, (acc, value) => acc + value);

    if (count == 1) {
      rgb = mask;
    } else {
      List<List<double>> subBasis = [];
      for (int i = 0; i < BASIS.length; i++) {
        if (mask[i] == 1) {
          subBasis.add(BASIS[i]);
        }
      }

      // # define the line from the origin along the second vector, computing its
      // # equation in the form Ax + C = 0, but C is always 0 for this line
      List<double> AB = [subBasis[1][1], subBasis[1][0] * -1];
      // # intersect the ray from the saturation point along the first basis vector
      // # with the line we just computed, these are definitely not co-linear, so there
      // # should always be an intersection point, and the result should always be in
      // # the range [-1 .. 1], this is the first basis coefficient
      double coeff0 = vecDot<double>(hueVec, AB) / vecDot(subBasis[0], AB);
      // # compute the intersection point, and the second basis coefficient, note that
      // # we compute the coefficients to always be positive, but the intersection calculation
      // # needs to be in the opposite direction from the basis vector (hence the negative on
      // # coeff0).
      List<double> intersection = vecAdd(vecMul(subBasis[0], -coeff0), hueVec);
      List<double> coeff = [coeff0, vecDot(intersection, subBasis[1])];

      // # there's a bit of a gamut problem here, as the area outside the hexagon defined by
      //       # the three unit basis vectors is not actually reachable. this manifests as
      //       # coefficients greater than 1, which will always happen unless the target color is
      //       # either one of the basis vectors or a bisector of two basis vectors. we scale both
      //       # coefficients by 1/maxCoefficient to make valid colors
      double maxCoeff = coeff.reduce(max);
      coeff = [coeff[0] / maxCoeff, coeff[1] / maxCoeff];

      //  # now rebuild the rgb vector by putting the coefficients into the correct place
      int j = 0;

      for (var i = 0; i < 3; i++) {
        if (mask[i] == 1) {
          rgbList.add(min(coeff[j], 1));
          j += 1;
        } else {
          rgbList.add(0);
        }
      }

      rgb = rgbList;
    }
  }

  //  # we want a discontinuous behavior. if saturation >= 0.5, we want the color to remain saturated
  // # and we scale the cw value down to 0 as saturation goes from 0.5 to 1. if saturation < 0.5, we
  // # want to saturate cw, and scale the rgb down to (0, 0, 0) as saturation goes from 0.5 - 0
  if (saturation >= 0.5) {
    // # rgb remains saturated
    // # scale the cw value down to 0 as saturation goes from 0.5 to 1

    cw = 1 - ((saturation - 0.5) * 2);
  } else {
    cw = 1;

    rgb = vecMul<double>(
        rgb.map<double>((i) => i.toDouble()).toList(), saturation * 2);
  }

  //  # scale back to the pilot color space
  rgb = vecInt(
      vecMul<double>(rgb.map<double>((i) => i.toDouble()).toList(), 255));
  int out_cw = (max(0, cw * CWMAX)).toInt();

  //     # the wiz light appears to have 5 different LEDs, r, g, b, warm_white, and cold_white
  // # there appears to be a max power supplied across the 5 LEDs, which explains why all-
  // # on full isn't the brightest configuration
  // # warm_white appears to be 2800k, and cold_white appears to be 6200k, somewhat neutral
  // # brightness is achieved by turning both of them on
  return {'rgb': rgb, 'cw': out_cw};
}

Map<String, dynamic> rgb2rgbcw(List<int> rgb) {
  // scale the vector into canonical space ([0-1])

  final List<double> rgbSca = vecMul(rgb, 1 / 255);
  // compute the hue vector as a linear combination of the basis vectors, and extract the
  // saturation, there's probably a better pythonese way of doing this

  List<double> hueVec = vecAdd(
    vecAdd(
      vecMul(BASIS[0], rgbSca[0]),
      vecMul(BASIS[1], rgbSca[1]),
    ),
    vecMul(BASIS[2], rgbSca[2]),
  );

  final double saturation = vecLen(hueVec);
  if (saturation > EPSILON) {
    hueVec = vecMul(hueVec, 1 / saturation);
  }

  return trapezoid(hueVec, saturation);
}
