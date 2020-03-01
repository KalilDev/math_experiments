import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:tuple/tuple.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/*typedef Result IsolateFunction<Result, Message>(Message msg);

void isolateFunctionWrapper(SendPort mainSink) {
  final ReceivePort isolateStream = ReceivePort();
  mainSink.send(isolateStream.sendPort);

  isolateStream.listen((dynamic message) {
    final data = message as Tuple2;
    final IsolateFunction F = data.item1;
    final msg = data.item2;
    final result = F(msg);
    mainSink.send(result);
  });
}*/

Future<Result> runOnIsolate<Result, Message>(
    void F(SendPort s), Message msg) async {
  // Setup communication with isolate
  final ReceivePort mainStream = ReceivePort();
  final ReceivePort errorStream = ReceivePort();
  final ReceivePort exitStream = ReceivePort();
  // Start isolate with F. Sidenote: F needs to be static and send the isolate's
  // sendPort through the main sink. We cannot wrap F because dart isolates can't
  // receive functions (even static ones), so the user MUSTN't fuck this up.
  final Isolate isolate = await Isolate.spawn<SendPort>(F, mainStream.sendPort,
      onError: errorStream.sendPort, onExit: exitStream.sendPort);

  void dispose() {
    isolate?.kill(priority: Isolate.immediate);
    mainStream.close();
    errorStream.close();
    exitStream.close();
  }

  final Completer<Result> completer = Completer<Result>();

  mainStream.listen((data) {
    if (data is SendPort) {
      // This is the first message, and it ALWAYS should be the isolate's
      // [SendPort]. Be sure that F sends it!!!!
      data.send(msg);
    } else {
      // This is the actual calculation returned from the isolate, it should be
      // of the return type.
      try {
        final Result result = data as Result;
        completer.complete(result);
      } on CastError catch (e, s) {
        // The stack trace has no relevant info in this case.
        completer.completeError(e, s);
      } finally {
        dispose();
      }
    }
  });
  errorStream.listen((e) {
    completer.completeError(e);
    dispose();
  });
  exitStream.listen((e) {
    if (!completer.isCompleted) {
      // This shoudn't have happened!
      completer.completeError(Exception(
          'The isolate was killed before it completed the calculation!'));
      dispose();
    }
  });

  return completer.future;
}

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
