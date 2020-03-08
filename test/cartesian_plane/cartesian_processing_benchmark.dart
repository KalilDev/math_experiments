library cartesian_widget;

@Timeout(const Duration(seconds: 150000))
import 'package:flutter/material.dart';
import 'package:math_experiments/cartesian_plane/cartesian_widget.dart';
import 'package:math_experiments/cartesian_plane/cartesian_isolate.dart';
import 'package:math_experiments/cartesian_plane/cartesian_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_experiments/cartesian_plane/isolate/impl/stub_impl.dart'
    as stub;
import 'dart:math';

import 'package:math_experiments/cartesian_plane/isolate/process_image.dart';

extension on List<num> {
  double get average => (cast<num>()).reduce((a, b) => a + b) / length;
  num get median {
    final list = sorted;
    if (length.isOdd) {
      final i = ((length - 1) / 2).round();
      return list[i.round()];
    } else {
      final i2 = (length / 2).round();
      return (list[i2 - 1] + list[i2]) / 2;
    }
  }

  num get highest => sorted.last;
  num get lowest => sorted.first;
  List<num> get sorted => List<num>.from(this)..sort((a, b) => a.compareTo(b));
}

extension on num {
  String get pretty {
    final sign = this.sign == -1 ? '-' : '';
    final integerPart = floor().abs();
    final nSections = (integerPart.toString().length / 3).ceil() - 1;
    final p = pow(10, nSections * 3);
    final leadingVal = (integerPart / p).floor();
    final toBeGrouped = (integerPart - (leadingVal * p)).toString();
    final lostLength = integerPart.toString().length -
        leadingVal.toString().length -
        toBeGrouped.length;
    var text = sign + leadingVal.toString();
    for (var i = 0; i < toBeGrouped.length + lostLength; i++) {
      if (i % 3 == 0) {
        text += ',';
      }
      text += i < lostLength ? '0' : toBeGrouped[i - lostLength];
    }
    final fractionalPart = (abs() - integerPart).abs();
    if (fractionalPart != 0) {
      // Remove the leading zero
      final frac = fractionalPart.toStringAsFixed(2);
      text += frac.substring(1, frac.length);
    }
    return text;
  }
}

void main() {
  test('Benchmark', () async {
    final numberOfTries = 10;
    double function(double x) => x;
    final coords = Rect.fromLTRB(-1, 2, 1, 0);
    final def = [FunctionDef(func: function, color: Colors.amber)];
    final size = IntSize(1000, 1000);
    final timeTaken = List<int>(numberOfTries);
    final timer = Stopwatch();

    for (var i = 0; i < numberOfTries; i++) {
      timer
        ..reset()
        ..start();
      await getFutureImage(size, def, coords, 4,
          imageConverter: (PixelDataMessage a) => Future.value(null));
      timer.stop();
      timeTaken[i] = timer.elapsedMicroseconds;
    }
    print('Average time taken: ${timeTaken.average.pretty}μs\n'
        'Median time: ${timeTaken.median.pretty}μs\n'
        'Slowest time: ${timeTaken.highest.pretty}μs\n'
        'Fastest time: ${timeTaken.lowest.pretty}μs\n'
        'Delta between fastest & slowest: ${(timeTaken.highest - timeTaken.lowest).pretty}μs\n'
        'Full table: $timeTaken');
  });
}
