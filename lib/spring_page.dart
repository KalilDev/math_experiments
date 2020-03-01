import 'dart:math';
import 'package:math_experiments/cartesian_plane.dart';
import 'package:math_experiments/common_mhs.dart';

import 'constants_provider.dart';
import 'work_funcs.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

class SpringTheme {
  SpringTheme(
      {this.velocityColor,
      this.forceColor,
      this.boxColor,
      this.springColor,
      this.mechanicalColor,
      this.textColor,
      this.backgroundTextColor});
  factory SpringTheme.light() => SpringTheme(
      velocityColor: Colors.lightBlue,
      forceColor: Colors.teal,
      boxColor: Colors.blue,
      springColor: Colors.black,
      mechanicalColor: Colors.red,
      textColor: Colors.black,
      backgroundTextColor: Colors.black);
  factory SpringTheme.dark() => SpringTheme(
      velocityColor: Colors.indigo[200],
      forceColor: Colors.teal[200],
      boxColor: Colors.blue[200],
      springColor: Colors.white,
      mechanicalColor: Colors.red[200],
      textColor: Colors.black.withAlpha(0xCC),
      backgroundTextColor: Colors.white.withAlpha(0xCC));
  final Color velocityColor;
  final Color forceColor;
  final Color boxColor;
  final Color springColor;
  final Color mechanicalColor;
  final Color textColor;
  final Color backgroundTextColor;
}

class SpringPage extends CommonMHSWidget {
  @override
  _SpringPageState createState() => _SpringPageState();
}

class _SpringPageState extends CommonMHSState {
  @override
  Widget buildRepresentation(ConstantsProvider consts, Brightness b, double t) {
    double getSpringFFraction() {
      final double xMax = maxDistance(consts.Em, consts.K);
      final double fMax = xMax * consts.K;
      final double force = distanceAtT(t, xMax) * consts.K;
      return force / fMax;
    }

    double getSpringVFraction() {
      final double vMax = maxVelocity(consts.Em, consts.M);
      final double velocity = velAtT(t, vMax);
      return velocity / vMax;
    }

    double getSpringXFraction() {
      final double xMax = maxDistance(consts.Em, consts.K);
      final double distance = distanceAtT(t, xMax);
      return distance / xMax;
    }

    int getSpringPieces() {
      final double frac = consts.K / 4;
      return (log(frac * frac * frac + 1) + 1).round();
    }

    final SpringTheme theme =
        b == Brightness.light ? SpringTheme.light() : SpringTheme.dark();

    return SizedBox(
      child: CustomPaint(
        painter: SpringPainter(
            theme: theme,
            x: getSpringXFraction(),
            vel: getSpringVFraction(),
            force: getSpringFFraction(),
            springPieces: getSpringPieces(),
            texts: SpringTexts(
                spring: 'K: ${consts.K.round()}N/m',
                position:
                    'S: ${distanceAtT(t, maxDistance(consts.Em, consts.K)).toStringAsFixed(2)}m',
                velocity:
                    'V: ${velAtT(t, maxVelocity(consts.Em, consts.M)).toStringAsFixed(2)}m/s\n' +
                        'p: ${kineticEnergyDerivative(consts.M, velAtT(t, maxVelocity(consts.Em, consts.M))).toStringAsFixed(2)}KgM/s',
                force:
                    'Fe: ${elasticEnergyDerivative(consts.K, distanceAtT(t, maxDistance(consts.Em, consts.K))).toStringAsFixed(2)}N',
                box: 'M: ${consts.M.toStringAsFixed(2)}Kg')),
      ),
      height: 96.0,
    );
  }

  @override
  double getPeriod(ConstantsProvider consts) =>
      getSpringPeriod(consts.K, consts.M);

  @override
  void updateFunctions(ConstantsProvider consts, Brightness b) {
    final SpringTheme theme =
        b == Brightness.light ? SpringTheme.light() : SpringTheme.dark();
    defs = [
      FunctionDef(
          func: (double x) => elasticEnergy(
              consts.K, distanceAtT(x, maxDistance(consts.Em, consts.K))),
          deriv: (double x) => sin(2 * pi * x) * -consts.Em * pi,
          color: theme.forceColor,
          hash: this.runtimeType.hashCode + 1),
      FunctionDef(
          func: (double x) => kineticEnergy(
              consts.M, velAtT(x, maxVelocity(consts.Em, consts.M))),
          deriv: (double x) => sin(2 * pi * x) * consts.Em * pi,
          color: theme.velocityColor,
          hash: this.runtimeType.hashCode + 2),
      FunctionDef(
          func: (double x) => consts.Em,
          color: theme.mechanicalColor,
          hash: this.runtimeType.hashCode + 3),
    ];
  }
}

class SpringTexts {
  SpringTexts(
      {this.force, this.velocity, this.position, this.spring, this.box});
  final String force;
  final String velocity;
  final String position;
  final String spring;
  final String box;
}

class SpringPainter extends CustomPainter {
  SpringPainter(
      {this.x,
      this.vel,
      this.force,
      this.springPieces = 10,
      this.texts,
      this.theme});
  // fraction between -1 & 1
  final double x;
  // fraction between -1 & 1
  final double vel;
  // fraction between -1 & 1
  final double force;

  final int springPieces;
  final SpringTexts texts;
  final double padding = 24.0;
  final double boxSize = 96.0;
  final SpringTheme theme;
  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double xAxisSize = size.width - (2 * padding + boxSize);
    // Fraction of the xSize
    final double springSize = padding + inverseLerp(-1, 1, x) * xAxisSize;
    final double yMid = size.height / 2;

    Matrix4 getVectorMatrix(double t,
        {bool onBox = true, bool center = false}) {
      final double scale = boxSize * 0.8;
      final double offset = t > 0 && onBox ? springSize + boxSize : springSize;
      final double yOffset = center ? ((boxSize - scale) / 2) / scale : 0.0;
      final Matrix4 matrix = Matrix4.identity() * scale;
      matrix..translate(offset / scale, yOffset);
      return matrix * Matrix4.diagonal3(Vector3(2.0 * t, 1, 1));
    }

    void drawForce() {
      final Paint forcePaint = Paint()..color = theme.forceColor;
      final Path forcePath = Path()
        ..moveTo(0, 0.25)
        ..lineTo(0.5, 0.25)
        ..lineTo(0.5, 0)
        ..lineTo(1.0, 0.5)
        ..lineTo(0.5, 1)
        ..lineTo(0.5, 0.75)
        ..lineTo(0, 0.75)
        ..lineTo(0, 0.25)
        ..close();

      final Matrix4 matrix =
          getVectorMatrix(-force, onBox: false, center: true);

      canvas.drawPath(forcePath.transform(matrix.storage), forcePaint);
      if (texts?.force != null) {
        final Vector3 topLeft = matrix * Vector3.zero();
        final Vector3 bottomRight = matrix * Vector3(1, 1, 0);
        final Vector3 textSize = bottomRight - topLeft;
        final TextSpan span = TextSpan(
            text: texts.force, style: TextStyle(color: theme.textColor));
        final TextPainter painter = TextPainter(
            text: span,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr);
        painter.layout(minWidth: textSize.x.abs(), maxWidth: textSize.x.abs());
        if (painter.height > textSize.y) return;
        painter.paint(
            canvas,
            Offset(min(topLeft.x, bottomRight.x),
                topLeft.y + (textSize.y - painter.height) / 2));
      }
    }

    void drawVelocity() {
      final Paint velPaint = Paint()..color = theme.velocityColor;
      Path getVelPath(int p) {
        final Path path = Path();
        int parts = -1;
        for (int i = 1; i <= p; i++) {
          parts += i + 1;
        }
        final double yFrac = 1 / parts;
        final double xFrac = 1 / p;
        for (int i = p; i > 0; i--) {
          final double yStart = 1 - parts * yFrac;
          final double yEnd = yStart + i * yFrac;
          path
            ..moveTo(0, yStart)
            ..lineTo(xFrac * i, yStart)
            ..lineTo(0, yEnd)
            ..lineTo(0, yStart);
          parts -= i + 1;
        }
        return path..close();
      }

      final Matrix4 matrix = getVectorMatrix(-vel);

      canvas.drawPath(getVelPath(3).transform(matrix.storage), velPaint);

      if (texts?.velocity != null) {
        final Vector3 topLeft = matrix * Vector3.zero();
        final Vector3 bottomRight = matrix * Vector3(1, 1, 0);
        final Vector3 textSize = bottomRight - topLeft;
        final TextSpan span = TextSpan(
            text: texts.velocity, style: TextStyle(color: theme.textColor));
        final TextPainter painter = TextPainter(
            text: span,
            textAlign: textSize.x.isNegative ? TextAlign.right : TextAlign.left,
            textDirection: TextDirection.ltr);
        painter.layout();
        if (painter.height > textSize.y) return;
        final Offset offset = Offset(
            min(topLeft.x, bottomRight.x + textSize.x.abs() - painter.width),
            topLeft.y);
        canvas.drawRect(
            Rect.fromLTWH(offset.dx, offset.dy, painter.width, painter.height),
            velPaint);
        painter.paint(canvas, offset);
      }
    }

    void drawBox() {
      final Paint paint = Paint()..color = theme.boxColor;
      canvas.drawRect(
          Rect.fromLTRB(springSize, 0, springSize + boxSize, boxSize), paint);
      if (texts?.box != null) {
        final TextSpan span =
            TextSpan(text: texts.box, style: TextStyle(color: theme.textColor));
        final TextPainter painter = TextPainter(
            text: span,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr);
        painter.layout(minWidth: boxSize, maxWidth: boxSize);
        if (painter.height > boxSize) return;
        painter.paint(canvas, Offset(springSize, size.height - painter.height));
      }
    }

    void drawSpring() {
      final Path spring = Path()..moveTo(0, yMid);
      final Paint paint = Paint()
        ..color = theme.springColor
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      for (int i = 0; i <= springPieces; i++) {
        final double pieceFrac = i / springPieces;
        final double halfwayFrac = 0.5 / springPieces;
        spring.quadraticBezierTo((pieceFrac - halfwayFrac) * springSize,
            i.isEven ? 0 : size.height, pieceFrac * springSize, yMid);
      }
      spring
        ..moveTo(0, yMid)
        ..close();
      canvas.drawPath(spring, paint);
      if (texts?.spring != null) {
        final TextSpan span = TextSpan(
            text: texts.spring,
            style: TextStyle(color: theme.backgroundTextColor));
        final TextPainter painter = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        painter.layout();
        painter.paint(canvas, Offset.zero);
      }
    }

    void drawRuler() {
      if (texts?.position != null) {
        final TextSpan span = TextSpan(
            text: texts.position,
            style: TextStyle(color: theme.backgroundTextColor));
        final TextPainter painter = TextPainter(
            text: span,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr);
        painter.layout(minWidth: springSize, maxWidth: springSize);
        painter.paint(canvas, Offset(0, size.height - painter.height));
      }
    }

    drawSpring();
    drawRuler();
    drawBox();
    drawVelocity();
    drawForce();
  }
}
