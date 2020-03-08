import 'dart:typed_data';
import 'package:math_experiments/cartesian_plane/cartesian_utils.dart'
    show MinColor;

import 'message.dart';
import 'package:image/image.dart' as img;

Uint8List processImage(PixelDataMessage data) {
  final byteCount = 4 * data.width * data.height;
  final timer = Stopwatch()..start();
  final bytes = Uint8List(byteCount);
  timer.stop();
  print('Creating uint8list took ${timer.elapsedMicroseconds}');

  final sizeOfRow = 4 * data.width;
  final defCount = data.colors.length;
  final yStartAtIndex = List<int>.generate(defCount, (int i) => i * data.width);
  timer
    ..reset()
    ..start();
  // There are two loops because data.values is an 2d array
  for (var x = 0; x < data.width; x++) {
    for (var i = 0; i < defCount; i++) {
      final y = data.values[x + yStartAtIndex[i]];
      final c = data.colors[i];
      final initialByteIdx = y * sizeOfRow + x * 4;
      for (var py = 0; py < data.lineSize; py++) {
        // Least Significant Bit
        final lsb = py & 0x1;
        // When py is odd, pyOffset will be negative and we will divide py + 1 by two
        // When py is even, pyOffset will be positive and we will divide only py by two
        final pyOffset = (-1 * lsb) * ((py + lsb) >> 0x1);
        final byteIdx = initialByteIdx + pyOffset * sizeOfRow;
        // Ok, now that we have the byte index we will set the color.
        bytes[byteIdx] = MinColor.redVal(c);
        bytes[byteIdx + 1] = MinColor.greenVal(c);
        bytes[byteIdx + 2] = MinColor.blueVal(c);
        bytes[byteIdx + 3] = MinColor.alphaVal(c);
      }
    }
  }
  timer.stop();
  print('new: ${timer.elapsedMicroseconds}');
  return bytes;
}
