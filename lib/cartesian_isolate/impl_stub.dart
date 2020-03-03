import 'dart:typed_data';
import 'package:math_experiments/cartesian_isolate/message.dart';

import 'process_image.dart';

Future<Uint8List> processImageImpl(PixelDataMessage message) {
  print('Using stub impl');
  return Future.microtask(() => processImage(message));
}
