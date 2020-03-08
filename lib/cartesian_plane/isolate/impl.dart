import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'message.dart';

import 'impl/stub_impl.dart' as stub;

// ignore: uri_does_not_exist
import 'impl/stub_impl.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'isolate_impl.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'worker_impl.dart';

final bool _useStub = kIsWeb && kDebugMode;

final Future<Uint8List> Function(PixelDataMessage message) futureProcessImage =
    _useStub ? stub.processImageImpl : processImageImpl;
