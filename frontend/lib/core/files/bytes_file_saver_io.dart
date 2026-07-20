import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<void> saveBytesToDownloads({
  required Uint8List bytes,
  required String filename,
  String mimeType = 'application/octet-stream',
}) async {
  final directory = await _resolveDownloadsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
}

Future<String> writeBytesToTempForSharing({
  required Uint8List bytes,
  required String filename,
}) async {
  final directory = await _resolveDownloadsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<Directory> _resolveDownloadsDirectory() async {
  if (Platform.isAndroid) {
    final dir = Directory('/storage/emulated/0/Download');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  final picked = await getDownloadsDirectory();
  if (picked != null) {
    if (!picked.existsSync()) {
      await picked.create(recursive: true);
    }
    return picked;
  }

  final fallback = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}downloads');
  if (!fallback.existsSync()) {
    await fallback.create(recursive: true);
  }
  return fallback;
}
