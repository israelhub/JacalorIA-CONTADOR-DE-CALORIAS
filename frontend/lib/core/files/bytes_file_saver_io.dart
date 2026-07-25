import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const _downloadsChannel = MethodChannel('com.jacaloria.app/downloads');

Future<void> saveBytesToDownloads({
  required Uint8List bytes,
  required String filename,
  String mimeType = 'application/octet-stream',
}) async {
  if (Platform.isAndroid) {
    await _downloadsChannel.invokeMethod<void>('saveToDownloads', {
      'bytes': bytes,
      'filename': filename,
      'mimeType': mimeType,
    });
    return;
  }

  final directory = await _resolveDownloadsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
}

Future<String> writeBytesToTempForSharing({
  required Uint8List bytes,
  required String filename,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<Directory> _resolveDownloadsDirectory() async {
  final picked = await getDownloadsDirectory();
  if (picked != null) {
    if (!picked.existsSync()) {
      await picked.create(recursive: true);
    }
    return picked;
  }

  final fallback = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}downloads',
  );
  if (!fallback.existsSync()) {
    await fallback.create(recursive: true);
  }
  return fallback;
}
