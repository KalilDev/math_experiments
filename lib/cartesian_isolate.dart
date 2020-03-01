import 'dart:isolate';
import 'dart:typed_data';
import 'package:tuple/tuple.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

@immutable
class PixelDataMessage {
  const PixelDataMessage({this.values, this.width, this.height, this.lineSize});
  final List<Tuple2<int, Color>> values;
  final int width;
  final int height;
  final int lineSize;
}

Uint8List processImage(PixelDataMessage data) {
  final bytes = Uint8List.fromList(
      List<int>.filled(4 * data.width * data.height, 0x00, growable: false));
  final singlePxAlpha = (255 * 1 / data.lineSize).floor();
  for (var i = 0; i < data.values.length; i++) {
    final x = i % data.width;
    final y = data.values[i].item1;
    final c = data.values[i].item2;
    for (var j = 0; j <= data.lineSize; j++) {
      final yOffset = j.isEven ? -(j / 2).ceil() : (j / 2).ceil();
      final py = yOffset + y;
      if (py >= data.height || py < 0) continue;
      final byteIdx = (py * data.width + x) * 4;
      bytes[byteIdx] = c.red;
      bytes[byteIdx + 1] = c.green;
      bytes[byteIdx + 2] = c.blue;
      bytes[byteIdx + 3] = singlePxAlpha * (data.lineSize - j);
    }
  }
  final Uint8List result =
      img.encodePng(img.Image.fromBytes(data.width, data.height, bytes));
  return result;
}

void wrappedProcessImage(SendPort mainSink) {
  final isolateStream = ReceivePort();
  mainSink.send(isolateStream.sendPort);

  isolateStream.listen((dynamic message) {
    mainSink.send(processImage(message as PixelDataMessage));
  });
}
