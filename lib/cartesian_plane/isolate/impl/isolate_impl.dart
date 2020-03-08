import 'dart:isolate';
import 'dart:typed_data';
import 'package:math_experiments/isolate_wrapper.dart';

import '../process_image.dart';
import '../message.dart';

Future<Uint8List> processImageImpl(PixelDataMessage message) {
  print('Using isolate impl');
  return runOnIsolate<Uint8List, PixelDataMessage>(
      wrappedProcessImage, message);
}

void wrappedProcessImage(SendPort mainSink) {
  final isolateStream = ReceivePort();
  mainSink.send(isolateStream.sendPort);

  isolateStream.listen((dynamic message) {
    mainSink.send(processImage(message as PixelDataMessage));
  });
}
