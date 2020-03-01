import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:math_experiments/work_funcs.dart';
import 'package:tuple/tuple.dart';
import 'cartesian_isolate.dart';
import 'isolate_wrapper.dart';

@immutable
class IntSize {
  const IntSize(int width, int height)
      : width = width ?? 0,
        height = height ?? 0;
  final int width;
  final int height;
  factory IntSize.round(Size s) => IntSize(s.width.round(), s.height.round());
  factory IntSize.floor(Size s) => IntSize(s.width.floor(), s.height.floor());
  factory IntSize.ceil(Size s) => IntSize(s.width.ceil(), s.height.ceil());

  @override
  int get hashCode {
    var result = 17;

    result = 31 * result + width.hashCode;
    result = 31 * result + height.hashCode;

    return result;
  }

  @override
  bool operator ==(other) {
    if (other is IntSize) return width == other.width && height == other.height;
    return false;
  }
}

@immutable
class FunctionDef {
  const FunctionDef({this.func, this.deriv, this.color, this.hash});
  final MathFunc func;
  final MathFunc deriv;
  final Color color;
  final int hash;

  @override
  int get hashCode => hash ?? super.hashCode;

  @override
  bool operator ==(other) {
    if (other.runtimeType != runtimeType) return false;

    if (hash != null && (other as FunctionDef).hash != null) {
      return hash == (other as FunctionDef).hash;
    }

    return super == (other);
  }
}

typedef MathFunc = double Function(double x);

class CartesianPlane extends StatefulWidget {
  const CartesianPlane(
      {Rect coords,
      this.currentX,
      this.lineSize = 2,
      this.aspectRatio,
      this.defs})
      : coords = coords ?? const Rect.fromLTRB(-1, 1, 1, -1);
  final Rect coords;
  final double currentX;
  final double aspectRatio;
  final int lineSize;
  final List<FunctionDef> defs;

  @override
  _CartesianPlaneState createState() => _CartesianPlaneState();
}

class _CartesianPlaneState extends State<CartesianPlane> {
  Tuple2<List<FunctionDef>, IntSize> currentProcessing;
  Tuple3<ImageProvider, List<FunctionDef>, IntSize> currentImage;
  IntSize currentSize;

  Future<void> maybeUpdateImage() async {
    // The wanted image is already being processed
    if (currentProcessing != null &&
        listEquals<FunctionDef>(currentProcessing.item1, widget.defs) &&
        currentProcessing.item2 == currentSize) return;
    // The current image is already the wanted image
    if (currentImage != null &&
        listEquals<FunctionDef>(currentImage.item2, widget.defs) &&
        currentImage.item3 == currentSize) return;

    final defs = widget.defs;
    final size = currentSize;
    final coords = widget.coords;
    final lineSize = widget.lineSize;
    // We will need to process the image now
    final processing = Tuple2<List<FunctionDef>, IntSize>(defs, size);
    currentProcessing = processing;
    final bytes = await getFutureImage(size, defs, coords, lineSize);

    // Exit if a new image was scheduled
    if (processing != currentProcessing) return print('Early return 0');

    final image = MemoryImage(bytes);
    await precacheImage(image, context);

    // Exit if a new image was scheduled
    if (processing != currentProcessing) {
      print('Early return 1');
      return image.evict();
    }

    // Finally we update the widget
    setState(() {
      print('Setting state: $processing');
      currentProcessing = null;
      currentImage = Tuple3(image, widget.defs, currentSize);
    });
  }

  static Iterable<Tuple2<int, Color>> getYs(
      double x, int yPixels, List<FunctionDef> defs, Rect coordinates) sync* {
    for (var i = 0; i < defs.length; i++) {
      final color = defs[i].color ?? Colors.black;
      final F = defs[i].func;
      final y = inverseLerp(coordinates.top, coordinates.bottom, F(x));
      final yPixel = (y * yPixels).round();
      yield Tuple2<int, Color>(yPixel, color);
    }
  }

  static Future<Uint8List> getFutureImage(IntSize sizePx,
      List<FunctionDef> defs, Rect coordinates, int lineSize) async {
    final timer = Stopwatch();
    timer.start();
    // We will make an List with all the x values as the idx and the y values and then we will add
    // those to the image.
    // This is an flattened 2d array basically. Its more performant than an
    // array[sizePx.width] of arrays[defs.length].
    final values = List<Tuple2<int, Color>>(sizePx.width * defs.length);

    for (var x = 0; x < sizePx.width; x++) {
      final yVals = getYs(
              lerpDouble(coordinates.left, coordinates.right, x / sizePx.width),
              sizePx.height,
              defs,
              coordinates)
          .toList();

      for (var i = 0; i < yVals.length; i++) {
        values[sizePx.width * i + x] = yVals[i];
      }
    }
    print('calcs took ${timer.elapsedMicroseconds}');
    timer.reset();
    timer.start();
    // Let there be an async gap. This will prevent dropped
    await Future.value(null);
    print('gap was ${timer.elapsedMicroseconds}');
    // Now we convert the tuples into proper pixel data
    timer.reset();
    timer.start();
    final bytes = await runOnIsolate<Uint8List, PixelDataMessage>(
            wrappedProcessImage,
            PixelDataMessage(
                values: values,
                width: sizePx.width,
                height: sizePx.height,
                lineSize: lineSize))
        .catchError((e) => print(e));
    print('computational gap was ${timer.elapsedMicroseconds}');
    // Flutter does not let me instantiate an image from raw channel data smh
    return bytes;
  }

  Iterable<Tuple3<Offset, Offset, Color>> getPoints(Size s) sync* {
    for (var i = 0; i < widget.defs.length; i++) {
      final F = widget.defs[i].func;
      final c = widget.defs[i].color;
      final xPos = inverseLerp(
              widget.coords.left, widget.coords.right, widget.currentX) *
          s.width;
      final yPos = inverseLerp(
              widget.coords.top, widget.coords.bottom, F(widget.currentX)) *
          s.height;
      yield Tuple3(
          Offset(xPos, yPos), Offset(widget.currentX, F(widget.currentX)), c);
    }
  }

  Iterable<Tuple3<Offset, double, Color>> getDerivatives(Size s) sync* {
    for (var i = 0; i < widget.defs.length; i++) {
      final F = widget.defs[i].func;
      final D = widget.defs[i].deriv;
      if (D == null) continue;
      final c = widget.defs[i].color;
      final xPos = inverseLerp(
              widget.coords.left, widget.coords.right, widget.currentX) *
          s.width;
      final yPos = inverseLerp(
              widget.coords.top, widget.coords.bottom, F(widget.currentX)) *
          s.height;
      // The derivative works for an 1:1 cartesian plane, which isn't the case always
      // We need to scale it accordingly
      final xSize = s.width / widget.coords.width.abs();
      final ySize = s.height / widget.coords.height.abs();
      final d = D(widget.currentX) * (ySize / xSize);
      yield Tuple3(Offset(xPos, yPos), d, c);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: widget.aspectRatio ??
            widget.coords.width.abs() / widget.coords.height.abs(),
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          currentSize = IntSize.ceil(constraints.biggest);
          maybeUpdateImage();
          return Stack(
            children: <Widget>[
              if (widget.currentX != null)
                ClipRect(
                  child: CustomPaint(
                    painter: _CartesianScalePaint(
                        points: getPoints(constraints.biggest),
                        derivatives: getDerivatives(constraints.biggest),
                        lineSize: widget.lineSize * 1.0,
                        textStyle: DefaultTextStyle.of(context).style),
                    size: constraints.biggest,
                  ),
                ),
              if (currentImage != null) Image(image: currentImage.item1)
            ],
          );
        }));
  }
}

class _CartesianScalePaint extends CustomPainter {
  _CartesianScalePaint(
      {this.points, this.derivatives, this.lineSize, this.textStyle});
  final Iterable<Tuple3<Offset, Offset, Color>> points;
  final Iterable<Tuple3<Offset, double, Color>> derivatives;
  final double lineSize;
  final TextStyle textStyle;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    for (var point in points) {
      canvas.drawCircle(point.item1, lineSize, Paint()..color = point.item3);
      final tp = TextPainter(
          text: TextSpan(
              text:
                  '(x: ${point.item2.dx.toStringAsFixed(2)}, y: ${point.item2.dy.toStringAsFixed(2)})',
              style: textStyle),
          textDirection: TextDirection.ltr);

      tp.layout();
      tp.paint(canvas, point.item1);
    }
    for (var point in derivatives) {
      final yStart = point.item1.dx * point.item2 + point.item1.dy;
      final yEnd = point.item1.dy - (size.width - point.item1.dx) * point.item2;
      canvas.drawLine(
          Offset(0, yStart),
          Offset(size.width, yEnd),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = lineSize / 2
            ..color = point.item3);
    }
  }
}
