import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> saveBytesToDownloads({
  required Uint8List bytes,
  required String filename,
  String mimeType = 'application/octet-stream',
}) async {
  _triggerBrowserDownload(bytes: bytes, filename: filename, mimeType: mimeType);
}

Future<String> writeBytesToTempForSharing({
  required Uint8List bytes,
  required String filename,
}) {
  throw UnsupportedError('Local file paths are not available on web.');
}

void _triggerBrowserDownload({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
