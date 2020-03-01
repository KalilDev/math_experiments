import 'dart:math';

double getInitialTheta(double Em, double g, double m, double l) {
  final sin = ((Em / (m * g)) - l) / l;
  final integerPart = sin.isNegative ? sin.ceil() : sin.floor();
  return asin(sin - integerPart) + integerPart * pi;
}

// this approximation that results in simple harmonic motion works only for
// theta approx 0, but fuck it.
double thetaAtT(double t, double theta0, double l, double g) =>
    theta0 * cos(pendulumFrequency(g, l) * t);

double pendulumFrequency(double g, double l) => sqrt(g / l);

// 2pi*sqrt(length / g)
double pendulumPeriod(double l, double g) => 2 * pi / pendulumFrequency(g, l);

double heightAtTheta(double theta, double l) {
  print(-cos(theta) * l + l);
  return -cos(theta) * l + l;
}

double gravitationalEnergy(double m, double g, double h) {
  print(m * g * h);
  print(h);
  return m * g * h;
}
