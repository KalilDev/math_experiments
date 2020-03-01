import 'dart:math' show sqrt, cos, pi, sin;

extension on num {
  num get squared => this * this;
  num get cubed => this * this * this;
}

double inverseLerp(double a, double b, double y) {
  return (y - a) / (b - a);
}

// mv^2/2
double kineticEnergy(double mass, double velocity) =>
    (mass * velocity.squared) / 2;

// mv -> Linear momentum
double kineticEnergyDerivative(double mass, double velocity) {
  return mass * velocity;
}

// mv^3/6 + C
double kineticEnergyIntegral(double mass, double velocity, {double C = 0.0}) =>
    (mass * velocity.cubed) / 6 + C;

// √2e/m
double kineticEnergyVelocity(double kineticEnergy, double mass) =>
    sqrt(2 * kineticEnergy / mass);

// kx^2/2
double elasticEnergy(double springConst, double displacement) =>
    (springConst * displacement.squared) / 2;

// kx -> Elastic force
double elasticEnergyDerivative(double springConst, double displacement) =>
    springConst * -displacement;

// kx^3/6 + C
double elasticEnergyIntegral(double springConst, double displacement,
        {double C = 0.0}) =>
    (springConst * displacement.cubed) / 6 + C;

// √2e/k
double elasticEnergyDistance(double elasticEnergy, double mass) =>
    sqrt(2 * elasticEnergy / mass);

double distanceAtT(double t, double maxDist) => -cos(t * pi) * maxDist;
double velAtT(double t, double maxVel) => sin(t * pi) * maxVel;

double maxDistance(double Em, double K) => elasticEnergyDistance(Em, K);
double maxVelocity(double Em, double M) => kineticEnergyVelocity(Em, M);

double getSpringPeriod(double K, double M) => 2 * pi * sqrt(M / K);
