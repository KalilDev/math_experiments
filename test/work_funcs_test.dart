import 'dart:math';

import 'package:math_experiments/work_funcs.dart';
import 'package:test/test.dart';

const double _kErrorMargin = 0.000001;

class DoubleMatcher extends Matcher {
  const DoubleMatcher(this.n, [double epsilon])
      : epsilon = epsilon ?? _kErrorMargin;
  final double n;
  final double epsilon;

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    final delta = matchState['delta'] as double;
    return mismatchDescription
      ..add(
          'The delta would be acceptable if it were =<$epsilon, but it is $delta.');
  }

  @override
  Description describe(Description description) {
    return description..add('≈$n');
  }

  @override
  bool matches(item, Map matchState) {
    if (item is double) {
      final diff = (n - item).abs();
      matchState['delta'] = diff;
      final didMatch = diff <= _kErrorMargin;
      return didMatch;
    }
    return false;
  }
}

void main() {
  double kineticAndElastic(double constant, double variable) {
    final kinetic = kineticEnergy(constant, variable);
    final elastic = elasticEnergy(constant, variable);
    expect(kinetic, elastic);
    return kinetic;
  }

  test('Base kinetic & elastic energy tests', () {
    // There isn't kinetic energy unless there is mass or you are a photon
    expect(kineticAndElastic(0.0, -11231), DoubleMatcher(0));
    expect(kineticAndElastic(0.0, 112), DoubleMatcher(0));
    expect(kineticAndElastic(0.0, 0), DoubleMatcher(0));

    // Some examples that were validated by hand
    expect(kineticAndElastic(1.0, -132), DoubleMatcher(8712));
    expect(kineticAndElastic(1.0, 11), DoubleMatcher(60.5));
    expect(kineticAndElastic(112.0, 112), DoubleMatcher(702464));
    expect(kineticAndElastic(112.0, 11), DoubleMatcher(6776));
    expect(kineticAndElastic(1234.0, 0), DoubleMatcher(0));
    expect(kineticAndElastic(1234.0, 1023), DoubleMatcher(645708393));
  });

  test('Full system test', () {
    //
    // This is the simulation for an full spring SHM system.
    //

    // 100N/m
    const K = 100.0;
    // 200J
    const Em = 200.0;
    // 1kg
    const M = 1.0;
    // So, there are 3 states:
    // A: Totally compressed to the left
    // B: At the center moving right at max speed
    // C: Totally compressed to the right
    // D: At the center moving left at max speed

    // State to period mapping:
    // 0.0: A
    // 0.5: B
    // 1.0: C
    // 1.5: D
    // 2.0: A
    // This allows us to use an sawtooth going from 0 to 2 for the animation.

    // Params:
    // V -> velocity
    // D -> compression
    // We -> elastic energy (work)
    // Wk -> kinetic energy
    // Fe -> elastic force (derivative of elastic energy)
    // P -> linear momentum (derivative of kinectic energy)
    // Params at each state:
    // A:
    //  V = 0.0
    //  D = -2.0
    //  We = 200.0
    //  Wk = 0.0
    //  Fe = 200.0 // 200N towards the center
    //  P = 0.0
    // B:
    //  V = 20.0
    //  D = 0.0
    //  We = 0.0
    //  Wk = 200.0
    //  Fe = 0.0
    //  P = -20.0
    // C:
    //  V = 0.0
    //  D = 2.0
    //  We = 200.0
    //  Wk = 0.0
    //  Fe = -200.0 // 200N towards the center
    //  P = 0.0
    // D:
    //  V = -20.0
    //  D = 0.0
    //  We = 0.0
    //  Wk = 200.0
    //  Fe = 0.0
    //  P = 20.0

    // These are constant across all states
    final kMaxVel = maxVelocity(Em, M);
    final kMaxDist = maxDistance(Em, K);
    // Validate values
    expect(kMaxVel, 20);
    expect(kMaxDist, 2);

    void expectAtT(
        {double t,
        double V,
        double D,
        double We,
        double Wk,
        double Fe,
        double P}) {
      expect(velAtT(t, kMaxVel), DoubleMatcher(V),
          reason: 'Velocity didn\'t match at $t');
      expect(distanceAtT(t, kMaxDist), DoubleMatcher(D),
          reason: 'Distance didn\'t match at $t');
      expect(elasticEnergy(K, distanceAtT(t, kMaxDist)), DoubleMatcher(We),
          reason: 'Elastic energy didn\'t match at $t');
      expect(kineticEnergy(M, velAtT(t, kMaxVel)), DoubleMatcher(Wk),
          reason: 'Kinectic energy didn\'t match at $t');
      expect(elasticEnergyDerivative(K, distanceAtT(t, kMaxDist)),
          DoubleMatcher(Fe),
          reason: 'Elastic force didn\'t match at $t');
      expect(kineticEnergyDerivative(M, velAtT(t, kMaxVel)), DoubleMatcher(P),
          reason: 'Linear momentum didn\'t match at $t');
    }

    // Testing A
    expectAtT(t: 0.0, V: 0, D: -2, We: 200, Wk: 0, Fe: 200, P: 0);
    // Testing B
    expectAtT(t: 0.5, V: 20, D: 0, We: 0, Wk: 200, Fe: 0, P: 20);
    // Testing C
    expectAtT(t: 1.0, V: 0, D: 2, We: 200, Wk: 0, Fe: -200, P: 0);
    // Testing D
    expectAtT(t: 1.5, V: -20, D: 0, We: 0, Wk: 200, Fe: 0, P: -20);
    // Testing A
    expectAtT(t: 2.0, V: 0, D: -2, We: 200, Wk: 0, Fe: 200, P: 0);

    // Asserting that both are equal at theta = pi/4 rad
    final displacement = (sqrt2 / 2) * kMaxDist;
    final velocity = (sqrt2 / 2) * kMaxVel;
    expect(elasticEnergy(K, displacement), DoubleMatcher(100));
    expect(kineticEnergy(M, velocity), DoubleMatcher(100));
  });
}
