import 'dart:math';
import 'package:math_experiments/common_mhs.dart';
import 'package:math_experiments/pendulum_funcs.dart';

import 'constants_provider.dart';
import 'package:flutter/material.dart';
import 'cartesian_plane/cartesian_utils.dart';

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
    final theta0 = getInitialTheta(consts.Em, consts.g, consts.M, consts.l);
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

  @override
  Rect getCoords(ConstantsProvider consts) => Rect.fromLTRB(
      0.0,
      gravitationalEnergy(
              consts.M, consts.g, heightAtTheta(consts.theta0, consts.l)) *
          1.01,
      2.0,
      gravitationalEnergy(
              consts.M, consts.g, heightAtTheta(consts.theta0, consts.l)) *
          -0.01);
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
    final start = Offset(size.width / 2, 0);
    void drawPendulum() {
      final l = 3 * size.height / 4;
      final point =
          Offset(start.dx + sin(theta) * l, start.dy + cos(theta) * l);

      final linePaint = Paint()..color = Colors.black;
      canvas.drawLine(start, point, linePaint);

      final pointPaint = Paint()..color = Colors.blue;
      canvas.drawCircle(point, 4.0, pointPaint);
    }

    void drawTheta() {
      final angleSize = 80.0;
      final startAngle = Offset(start.dx, start.dy + angleSize);
      final finishAngle = Offset(
          start.dx + sin(theta) * angleSize, start.dy + cos(theta) * angleSize);
      final delta = finishAngle - startAngle;
      final path = Path();
      final controlPoint = Offset(
          startAngle.dx + delta.dx / 2 + angleSize / 10 * sin(theta),
          startAngle.dy + delta.dy / 2 + angleSize / 10 * cos(theta));
      path
        ..moveTo(start.dx, start.dy)
        ..lineTo(startAngle.dx, startAngle.dy)
        ..quadraticBezierTo(
            controlPoint.dx, controlPoint.dy, finishAngle.dx, finishAngle.dy)
        ..lineTo(start.dx, start.dy);
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
      final tp = TextPainter(
          text: TextSpan(
              text: 'θ\n${(theta * 180 / pi).round()}°',
              style: TextStyle(color: Colors.black)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center);
      tp.layout();
      tp.paint(canvas, controlPoint.translate(-tp.width / 2, 0));
    }

    drawPendulum();
    drawTheta();
  }
}
