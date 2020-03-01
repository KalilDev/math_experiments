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
  final Uint8List bytes = Uint8List.fromList(
      List<int>.filled(4 * data.width * data.height, 0x00, growable: false));
  final int singlePxAlpha = (255 * 1 / data.lineSize).floor();
  for (int i = 0; i < data.values.length; i++) {
    final int x = i % data.width;
    final int y = data.values[i].item1;
    final Color c = data.values[i].item2;
    for (int j = 0; j <= data.lineSize; j++) {
      final int yOffset = j.isEven ? -(j / 2).ceil() : (j / 2).ceil();
      final int ny = yOffset + y;
      if (ny >= data.height || ny < 0) continue;
      final int byteIdx = (ny * data.width + x) * 4;
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
  final ReceivePort isolateStream = ReceivePort();
  mainSink.send(isolateStream.sendPort);

  isolateStream.listen((dynamic message) {
    mainSink.send(processImage(message as PixelDataMessage));
  });
}
