import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

Uint8List createUint8ListImpl(int length) =>
    allocate<Uint8>(count: length).asTypedList(length);
