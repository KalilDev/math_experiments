import 'dart:typed_data';

import '../cartesian_utils.dart' show MinColor;
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

@immutable
class PixelDataMessage {
  const PixelDataMessage(
      {this.values, this.colors, this.width, this.height, this.lineSize});
  final Uint16List values;
  final Uint32List colors;
  final int width;
  final int height;
  final int lineSize;
}
