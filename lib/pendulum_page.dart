import 'dart:math';
import 'package:math_experiments/common_mhs.dart';
import 'package:math_experiments/pendulum_funcs.dart';

import 'constants_provider.dart';
import 'package:flutter/material.dart';
import 'cartesian_plane.dart';

class PendulumPage extends CommonMHSWidget {
  @override
  _PendulumPageState createState() => _PendulumPageState();
}

class _PendulumPageState extends CommonMHSState {
  @override
  Widget buildRepresentation(ConstantsProvider consts, Brightness b, double t) {
    double getTheta() {
      return thetaAtT(
          t,
          getInitialTheta(consts.Em, consts.g, consts.M, consts.l),
          consts.l,
          consts.g);
    }

    return AspectRatio(
      aspectRatio: 1,
      child: SizedBox.expand(
        child: CustomPaint(
          painter: PendulumPainter(getTheta()),
        ),
      ),
    );
  }

  @override
  double getPeriod(ConstantsProvider consts) =>
      pendulumPeriod(consts.l, consts.g);

  @override
  void updateFunctions(ConstantsProvider consts, Brightness b) {
    final double theta0 =
        getInitialTheta(consts.Em, consts.g, consts.M, consts.l);
    defs = [
      FunctionDef(
          func: (double x) => gravitationalEnergy(consts.M, consts.g,
              heightAtTheta(thetaAtT(x, theta0, consts.l, consts.g), consts.l)),
          deriv: (double x) => 0,
          color: Colors.teal),
      FunctionDef(
          func: (double x) =>
              consts.Em -
              gravitationalEnergy(
                  consts.M,
                  consts.g,
                  heightAtTheta(
                      thetaAtT(x, theta0, consts.l, consts.g), consts.l)),
          deriv: (double x) => 0,
          color: Colors.indigo),
      FunctionDef(
          func: (double x) => consts.Em,
          deriv: (double x) => 0,
          color: Colors.red),
    ];
  }
}

class PendulumPainter extends CustomPainter {
  PendulumPainter(this.theta);
  final double theta;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    void drawPendulum() {
      final double l = size.width / 2;
      final Offset center = size.center(Offset.zero);
      final Offset point = Offset(sin(theta) * l + l, cos(theta) * l + l);

      final Paint linePaint = Paint()..color = Colors.black;
      canvas.drawLine(center, point, linePaint);

      final Paint pointPaint = Paint()..color = Colors.blue;
      canvas.drawCircle(point, 4.0, pointPaint);
    }

    drawPendulum();
  }
}
