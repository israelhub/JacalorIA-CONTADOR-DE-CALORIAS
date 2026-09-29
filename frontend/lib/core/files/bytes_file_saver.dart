import 'dart:typed_data';

import 'bytes_file_saver_stub.dart'
    if (dart.library.io) 'bytes_file_saver_io.dart' as impl;

/// Saves [bytes] to the user's downloads folder on IO platforms.
/// On web, triggers a browser download instead.
Future<void> saveBytesToDownloads({
  required Uint8List bytes,
  required String filename,
  String mimeType = 'application/octet-stream',
}) {
  return impl.saveBytesToDownloads(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
  );
}

/// Writes [bytes] to a local file and returns its path for sharing on IO platforms.
Future<String> writeBytesToTempForSharing({
  required Uint8List bytes,
  required String filename,
}) {
  return impl.writeBytesToTempForSharing(
    bytes: bytes,
    filename: filename,
  );
}
