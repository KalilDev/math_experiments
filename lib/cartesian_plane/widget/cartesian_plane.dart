import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../cartesian_isolate.dart';
import '../cartesian_utils.dart';
import 'package:math_experiments/work_funcs.dart';
import 'package:tuple/tuple.dart';

@visibleForTesting
Iterable<Tuple2<int, MinColor>> getYs(
    double x, int yPixels, List<FunctionDef> defs, Rect coordinates) sync* {
  for (var i = 0; i < defs.length; i++) {
    final color = MinColor(defs[i].color.value ?? Colors.black.value);
    final F = defs[i].func;
    final debug = F(x);
    final y = inverseLerp(coordinates.top, coordinates.bottom, F(x));
    final yPixel = (y * yPixels).round();
    yield Tuple2<int, MinColor>(yPixel, color);
  }
}

@visibleForTesting
Future<Uint8List> getFutureImage(
    IntSize sizePx, List<FunctionDef> defs, Rect coordinates, int lineSize,
    {Future<Uint8List> Function(PixelDataMessage msg) imageConverter}) async {
  // Use the isolate/worker implementation by default
  imageConverter ??= futureProcessImage;
// We will make an List with all the x values as the idx and the y values and then we will add
// those to the image.
// This is an flattened 2d array basically. Its more performant than an
// array[sizePx.width] of arrays[defs.length].
  final values = List<Tuple2<int, MinColor>>(sizePx.width * defs.length);

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

// Let there be an async gap, this will avoid dropping frames.
  await Future.value(null);

// Now we convert the tuples into an actual image.
  final bytes = imageConverter(PixelDataMessage(
          values: values,
          width: sizePx.width,
          height: sizePx.height,
          lineSize: lineSize))
      .catchError((e) => print(e));
// Flutter does not let me instantiate an image from raw channel data smh
  return bytes;
}

@visibleForTesting
String defaultDescription(double x, double y) =>
    '(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)})';

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
    final bytes = await getFutureImage(size, defs, coords, lineSize * 4);

    // Exit if a new image was scheduled
    if (processing != currentProcessing) return;

    final image = MemoryImage(bytes);
    await precacheImage(image, context);

    // Exit if a new image was scheduled
    if (processing != currentProcessing) {
      return image.evict();
    }

    // Finally we update the widget
    setState(() {
      currentProcessing = null;
      currentImage = Tuple3(image, widget.defs, currentSize);
    });
  }

  Iterable<Tuple3<Offset, String, Color>> getPoints(Size s) sync* {
    for (var i = 0; i < widget.defs.length; i++) {
      final F = widget.defs[i].func;
      final c = widget.defs[i].color;
      final describe = widget.defs[i].describe ?? defaultDescription;
      final y = F(widget.currentX);
      final xPos = inverseLerp(
              widget.coords.left, widget.coords.right, widget.currentX) *
          s.width;
      final yPos =
          inverseLerp(widget.coords.top, widget.coords.bottom, y) * s.height;
      final description = describe(widget.currentX, y);
      yield Tuple3(Offset(xPos, yPos), description, c);
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

  Iterable<Tuple3<Offset, String, Color>> getNames(Size s) sync* {
    for (var i = 0; i < widget.defs.length; i++) {
      final F = widget.defs[i].func;
      final name = widget.defs[i].name;
      if (name == null) continue;
      final c = widget.defs[i].color;
      final yPos = inverseLerp(
              widget.coords.top, widget.coords.bottom, F(widget.coords.left)) *
          s.height;
      yield Tuple3(Offset(0, yPos), name, c);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
        aspectRatio: widget.aspectRatio ??
            widget.coords.width.abs() / widget.coords.height.abs(),
        child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          currentSize = IntSize.ceil(constraints.biggest * 4);
          maybeUpdateImage();
          return Stack(
            children: <Widget>[
              if (widget.currentX != null)
                ClipRect(
                  child: CustomPaint(
                    painter: _CartesianScalePaint(
                        points: getPoints(constraints.biggest),
                        derivatives: getDerivatives(constraints.biggest),
                        names: getNames(constraints.biggest),
                        lineSize: widget.lineSize * 1.0,
                        textStyle: DefaultTextStyle.of(context).style),
                    size: constraints.biggest,
                  ),
                ),
              if (currentImage != null)
                Image(
                  fit: BoxFit.fill,
                  image: currentImage.item1,
                  width: constraints.biggest.width,
                  height: constraints.biggest.height,
                )
            ],
          );
        }));
  }
}

class _CartesianScalePaint extends CustomPainter {
  _CartesianScalePaint(
      {this.points,
      this.derivatives,
      this.names,
      this.lineSize,
      this.textStyle});
  final Iterable<Tuple3<Offset, String, Color>> points;
  final Iterable<Tuple3<Offset, double, Color>> derivatives;
  final Iterable<Tuple3<Offset, String, Color>> names;
  final double lineSize;
  final TextStyle textStyle;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    void drawText(Offset start, String text, [Color color]) {
      final tp = TextPainter(
          text: TextSpan(
              text: text,
              style:
                  color != null ? textStyle.copyWith(color: color) : textStyle),
          textDirection: TextDirection.ltr);

      tp.layout();
      final dy =
          (start.dy + tp.height).clamp(tp.height, size.height) - tp.height;
      final dx = (start.dx + tp.width).clamp(tp.width, size.width) - tp.width;
      tp.paint(canvas, Offset(dx, dy));
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
    for (var point in points) {
      canvas.drawCircle(point.item1, lineSize, Paint()..color = point.item3);
      drawText(point.item1, point.item2);
    }
    for (var point in names) {
      drawText(point.item1, point.item2, point.item3);
    }
  }
}
