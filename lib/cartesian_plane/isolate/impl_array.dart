import 'dart:typed_data';

import 'impl_array/sdk_impl.dart'
    if (dart.library.ffi) 'impl_array/ffi_impl.dart';

Uint8List createUint8List(int length) => createUint8ListImpl(length);
