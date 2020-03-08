import '../cartesian_utils.dart' show MinColor;
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

@immutable
class PixelDataMessage {
  const PixelDataMessage({this.values, this.width, this.height, this.lineSize});
  final List<Tuple2<int, MinColor>> values;
  final int width;
  final int height;
  final int lineSize;
}
