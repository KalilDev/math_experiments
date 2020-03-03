import 'package:math_experiments/cartesian_isolate/min_color.dart';
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
