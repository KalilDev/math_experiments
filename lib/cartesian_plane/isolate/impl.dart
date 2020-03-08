// ignore: uri_does_not_exist
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'message.dart';

import 'impl/stub_impl.dart' as stub;

import 'impl/stub_impl.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'isolate_impl.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'worker_impl.dart';

final bool useStub = kIsWeb && kDebugMode;

final Future<Uint8List> Function(PixelDataMessage message) futureProcessImage =
    useStub ? stub.processImageImpl : processImageImpl;
