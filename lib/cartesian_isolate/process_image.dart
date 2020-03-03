import 'dart:typed_data';
import 'message.dart';
import 'package:image/image.dart' as img;

Uint8List processImage(PixelDataMessage data) {
  final bytes = Uint8List.fromList(
      List<int>.filled(4 * data.width * data.height, 0x00, growable: false));
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
      bytes[byteIdx + 3] = c.alpha; //singlePxAlpha * (data.lineSize - j);
    }
  }
  var image = img.Image.fromBytes(data.width, data.height, bytes);
  return img.encodePng(image);
}
