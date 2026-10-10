import 'dart:typed_data';

import 'browser_jpeg_encoder_stub.dart'
    if (dart.library.io) 'browser_jpeg_encoder_io.dart' as impl;

Future<Uint8List?> encodeImageBytesToJpegInBrowser(
  Uint8List bytes, {
  required int maxDimension,
  required int quality,
}) {
  return impl.encodeImageBytesToJpegInBrowser(
    bytes,
    maxDimension: maxDimension,
    quality: quality,
  );
}
