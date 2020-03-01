import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:math_experiments/work_funcs.dart';
import 'package:tuple/tuple.dart';
import 'dart:developer' as dev;
import 'cartesian_isolate.dart';
import 'isolate_wrapper.dart';

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

    if (hash != null && (other as FunctionDef).hash != null)
      return hash == (other as FunctionDef).hash;

    return super == (other);
  }
}

typedef double MathFunc(double x);

class CartesianPlane extends StatefulWidget {
  const CartesianPlane(
      {Rect coordinates,
      this.currentX,
      this.lineSize = 2,
      this.aspectRatio,
      this.defs})
      : this.coordinates = coordinates ?? const Rect.fromLTRB(-1, 1, 1, -1);
  final Rect coordinates;
  final double currentX;
  final double aspectRatio;
  final int lineSize;
  final List<FunctionDef> defs;

  @override
  _CartesianPlaneState createState() => _CartesianPlaneState();
}

@immutable
class IntSize {
  const IntSize(int width, int height)
      : this.width = width ?? 0,
        this.height = height ?? 0;
  final int width;
  final int height;
  factory IntSize.round(Size s) => IntSize(s.width.round(), s.height.round());
  factory IntSize.floor(Size s) => IntSize(s.width.floor(), s.height.floor());
  factory IntSize.ceil(Size s) => IntSize(s.width.ceil(), s.height.ceil());
}

class _CartesianPlaneState extends State<CartesianPlane> {
  ImageProvider image;
  @override
  void didUpdateWidget(CartesianPlane oldWidget) {
    if (oldWidget.coordinates != widget.coordinates ||
        oldWidget.aspectRatio != widget.aspectRatio ||
        oldWidget.lineSize != widget.lineSize ||
        oldWidget.defs != widget.defs) {
      if (image != null) {
        image.evict();
        image = null;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  Iterable<Tuple2<int, Color>> getYs(double x, int yPixels) sync* {
    for (int i = 0; i < widget.defs.length; i++) {
      final Color color = widget.defs[i].color ?? Colors.black;
      final MathFunc f = widget.defs[i].func;
      final double y =
          inverseLerp(widget.coordinates.top, widget.coordinates.bottom, f(x));
      final int yPixel = (y * yPixels).round();
      yield Tuple2<int, Color>(yPixel, color);
    }
  }

  Uint8List oldGetImage(IntSize sizePx) {
    final Uint8List bytes = Uint8List(4 * sizePx.width * sizePx.height);
    // Flutter expects an RGBA image
    // We will make an List with all the x values as the idx and the y values and then we will add
    // those to the image.
    final timer = Stopwatch();
    timer.start();
    for (int x = 0; x < sizePx.width; x++) {
      final List<Tuple2<int, Color>> yVals = getYs(
              lerpDouble(widget.coordinates.left, widget.coordinates.right,
                  x / sizePx.width),
              sizePx.height)
          .toList(growable: false);
      for (int y = 0; y < sizePx.height; y++) {
        //dev.debugger(when: x == 300);
        final int i = (sizePx.width * y + x) * 4;
        bytes[i] = 0x00;
        bytes[i + 1] = 0x00;
        bytes[i + 2] = 0x00;
        bytes[i + 3] = 0x00;
        // Faster than iterable. Even more when using an generator function.
        for (int j = 0; j < yVals.length; j++) {
          final Tuple2<int, Color> item = yVals[j];
          final int dy = (item.item1 - y).abs();
          if (dy <= widget.lineSize) {
            final Color c = item.item2;
            bytes[i] = c.red;
            bytes[i + 1] = c.green;
            bytes[i + 2] = c.blue;
            bytes[i + 3] = (c.alpha * (1 - (dy / widget.lineSize))).round();
          }
        }
      }
    }
    timer.stop();
    print('Old algo finished: ${timer.elapsedMicroseconds / 1000}');
    // Flutter does not let me instantiate an image from raw channel data smh
    return img
        .encodePng(img.Image.fromBytes(sizePx.width, sizePx.height, bytes));
  }

  Future<Uint8List> getFutureImage(IntSize sizePx) async {
    final timer = Stopwatch();
    timer.start();
    // We will make an List with all the x values as the idx and the y values and then we will add
    // those to the image.
    // This is an flattened 2d array basically. Its more performant than an
    // array[sizePx.width] of arrays[defs.length].
    final List<Tuple2<int, Color>> values =
        List<Tuple2<int, Color>>(sizePx.width * widget.defs.length);

    for (int x = 0; x < sizePx.width; x++) {
      final List<Tuple2<int, Color>> yVals = getYs(
              lerpDouble(widget.coordinates.left, widget.coordinates.right,
                  x / sizePx.width),
              sizePx.height)
          .toList();

      for (int i = 0; i < yVals.length; i++) {
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
    final Uint8List bytes = await runOnIsolate<Uint8List, PixelDataMessage>(
            wrappedProcessImage,
            PixelDataMessage(
                values: values,
                width: sizePx.width,
                height: sizePx.height,
                lineSize: widget.lineSize))
        .catchError((e) => print(e));
    print('computational gap was ${timer.elapsedMicroseconds}');
    // Flutter does not let me instantiate an image from raw channel data smh
    return bytes;
  }

  Uint8List getImage(IntSize sizePx) {
    final Uint8List bytes = Uint8List.fromList(List<int>.filled(
        4 * sizePx.width * sizePx.height, 0x00,
        growable: false));
    // Flutter expects an RGBA image
    // We will make an List with all the x values as the idx and the y values and then we will add
    // those to the image.
    // This is an flattened 2d array basically. Its more performant
    final List<Tuple2<int, Color>> values =
        List<Tuple2<int, Color>>(sizePx.width * widget.defs.length);
    final timer = Stopwatch();
    timer.start();
    for (int x = 0; x < sizePx.width; x++) {
      final Iterable<Tuple2<int, Color>> yVals = getYs(
          lerpDouble(widget.coordinates.left, widget.coordinates.right,
              x / sizePx.width),
          sizePx.height);
      int i = 0;
      for (Tuple2<int, Color> val in yVals) {
        values[sizePx.width * i + x] = val;
        i++;
      }
    }
    print('New algo calculated: ${timer.elapsedMicroseconds / 1000}');
    final int singlePxAlpha = (255 * 1 / widget.lineSize).floor();
    // Now we convert the tuples into proper pixel data
    for (int i = 0; i < values.length; i++) {
      final int x = i % sizePx.width;
      final int y = values[i].item1;
      final Color c = values[i].item2;
      for (int j = 0; j <= widget.lineSize; j++) {
        final int yOffset = j.isEven ? -(j / 2).ceil() : (j / 2).ceil();
        final int ny = yOffset + y;
        if (ny >= sizePx.height || ny < 0) continue;
        final int byteIdx = (ny * sizePx.width + x) * 4;
        bytes[byteIdx] = c.red;
        bytes[byteIdx + 1] = c.green;
        bytes[byteIdx + 2] = c.blue;
        bytes[byteIdx + 3] = singlePxAlpha * (widget.lineSize - j);
      }
    }
    timer.stop();
    print('New algo finished: ${timer.elapsedMicroseconds / 1000}');
    return img
        .encodePng(img.Image.fromBytes(sizePx.width, sizePx.height, bytes));
  }

  Iterable<Tuple3<Offset, Offset, Color>> getPoints(Size s) sync* {
    for (int i = 0; i < widget.defs.length; i++) {
      final MathFunc F = widget.defs[i].func;
      final Color c = widget.defs[i].color;
      final double xPos = inverseLerp(widget.coordinates.left,
              widget.coordinates.right, widget.currentX) *
          s.width;
      final double yPos = inverseLerp(widget.coordinates.top,
              widget.coordinates.bottom, F(widget.currentX)) *
          s.height;
      yield Tuple3(
          Offset(xPos, yPos), Offset(widget.currentX, F(widget.currentX)), c);
    }
  }

  Iterable<Tuple3<Offset, double, Color>> getDerivatives(Size s) sync* {
    for (int i = 0; i < widget.defs.length; i++) {
      final MathFunc F = widget.defs[i].func;
      final MathFunc D = widget.defs[i].deriv;
      if (D == null) continue;
      final Color c = widget.defs[i].color;
      final double xPos = inverseLerp(widget.coordinates.left,
              widget.coordinates.right, widget.currentX) *
          s.width;
      final double yPos = inverseLerp(widget.coordinates.top,
              widget.coordinates.bottom, F(widget.currentX)) *
          s.height;
      // The derivative works for an 1:1 cartesian plane, which isn't the case always
      // We need to scale it accordingly
      final double xSize = s.width / widget.coordinates.width.abs();
      final double ySize = s.height / widget.coordinates.height.abs();
      final double d = D(widget.currentX);
      final double scaledD = d * (ySize / xSize);
      yield Tuple3(Offset(xPos, yPos), scaledD, c);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: widget.aspectRatio ??
            widget.coordinates.width.abs() / widget.coordinates.height.abs(),
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          /*image ??= MemoryImage(getImage(IntSize.ceil(
              constraints.biggest * MediaQuery.of(context).devicePixelRatio)));*/
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
              FutureBuilder(
                  future: getFutureImage(IntSize.ceil(constraints.biggest *
                      MediaQuery.of(context).devicePixelRatio)),
                  builder: (BuildContext c, AsyncSnapshot<Uint8List> img) {
                    if (img.hasData) {
                      image = MemoryImage(img.data);
                      return Image(image: image);
                    }
                    return SizedBox();
                  })
              /*Image(
                image: image,
              ),*/
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
    for (Tuple3<Offset, Offset, Color> point in points) {
      canvas.drawCircle(point.item1, lineSize, Paint()..color = point.item3);
      final TextPainter tp = TextPainter(
          text: TextSpan(
              text:
                  '(x: ${point.item2.dx.toStringAsFixed(2)}, y: ${point.item2.dy.toStringAsFixed(2)})',
              style: textStyle),
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, point.item1);
    }
    for (Tuple3<Offset, double, Color> point in derivatives) {
      final double yStart = point.item1.dx * point.item2 + point.item1.dy;
      final double yEnd =
          point.item1.dy - (size.width - point.item1.dx) * point.item2;
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
