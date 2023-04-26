// ignore_for_file: constant_identifier_names

import 'dart:math';

// # a small value, really close to zero, more than adequate for our 3 orders of magnitude
// # of color resolution
const EPSILON = 1.0e-5;

//"""Scale a vector."""
List<double> vecMul<T extends num>(List<T> vec, double sca) {
  return vec.map<double>((e) => e * sca).toList();
}

List<T> vecAdd<T extends num>(List<T> vector1, List<T> vector2) {
  assert(vector1.length == vector2.length, 'Vectors must have the same length');
  List<num> result = [];
  for (int i = 0; i < vector1.length; i++) {
    result.add(vector1[i] + vector2[i]);
  }
  return result.cast<T>().toList();
}

//"""Return the unit vector for a given angle (in radians)."""
List<double> vecFromAngle(double angle) {
  return [cos(angle), sin(angle)];
}

//"""Return the vector's magnitude."""
double vecLen<T extends num>(List<T> a) {
  double lenSq = vecLenSq(a);
  return lenSq > EPSILON ? sqrt(lenSq) : 0.0;
}

//"""Retrun sum."""
double vecDot<T extends num>(List<T> vector1, List<T> vector2) {
  assert(vector1.length == vector2.length, 'Vectors must have the same length');
  double result = 0;
  for (int i = 0; i < vector1.length; i++) {
    result += vector1[i] * vector2[i];
  }

  return result;
}

// """Return the vector's magnitude squared."""
double vecLenSq<T extends num>(List<T> a) {
  return vecDot(a, a);
}

List<int> vecInt<T extends num>(List<T> vec) {
  return vec.map((x) => x.toInt()).toList();
}
