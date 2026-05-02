import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SupabaseStorageService {
  static const String _supabaseUrl = 'https://pfeqheolinzgyelxwref.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBmZXFoZW9saW56Z3llbHh3cmVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MzE4OTUsImV4cCI6MjA5MTUwNzg5NX0.k_juFUSDvy8CbE-MjQ5FPZugM9pEz4P7BekjEz3_cHs';

  /// Uploads bytes to a specific bucket and returns the public URL
  static Future<String?> uploadBytes(
    Uint8List bytes,
    String bucketName, {
    String? extension,
  }) async {
    try {
      final ext = _normalizeExtension(extension) ?? _inferImageExtension(bytes);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final uri = Uri.parse(
        '$_supabaseUrl/storage/v1/object/$bucketName/$fileName',
      );

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_anonKey',
          'apikey': _anonKey,
          'Content-Type': _contentTypeForExtension(ext),
        },
        body: bytes,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return '$_supabaseUrl/storage/v1/object/public/$bucketName/$fileName';
      } else {
        debugPrint('Supabase upload failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to Supabase: $e');
      return null;
    }
  }

  static Future<String?> uploadFile(File file, String bucketName) async {
    final bytes = await file.readAsBytes();
    final ext = _fileExtension(file.path);
    return uploadBytes(bytes, bucketName, extension: ext);
  }

  static Future<String?> uploadAvatar(File file) async {
    return uploadFile(file, 'avatars');
  }

  static Future<String?> uploadAvatarBytes(
    Uint8List bytes, {
    String? extension,
  }) async {
    return uploadBytes(bytes, 'avatars', extension: extension);
  }

  static Future<String?> uploadMealPhoto(
    Uint8List bytes, {
    String? extension,
  }) async {
    return uploadBytes(bytes, 'meals', extension: extension);
  }

  static String _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return '.jpg';
    }

    return path.substring(dotIndex);
  }

  static String? _normalizeExtension(String? extension) {
    if (extension == null) {
      return null;
    }

    final trimmed = extension.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed.startsWith('.') ? trimmed : '.$trimmed';
  }

  static String _inferImageExtension(Uint8List bytes) {
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return '.webp';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return '.png';
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return '.jpg';
    }

    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return '.gif';
    }

    return '.jpg';
  }

  static String _contentTypeForExtension(String extension) {
    switch (extension) {
      case '.webp':
        return 'image/webp';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
