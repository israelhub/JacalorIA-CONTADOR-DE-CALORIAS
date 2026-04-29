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
      final ext = extension ?? '.webp';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final uri = Uri.parse(
        '$_supabaseUrl/storage/v1/object/$bucketName/$fileName',
      );

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_anonKey',
          'apikey': _anonKey,
          'Content-Type': 'application/octet-stream',
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

  static Future<String?> uploadAvatarBytes(Uint8List bytes) async {
    return uploadBytes(bytes, 'avatars', extension: '.webp');
  }

  static Future<String?> uploadMealPhoto(Uint8List bytes) async {
    return uploadBytes(bytes, 'meals', extension: '.webp');
  }

  static String _fileExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return '.webp';
    }

    return path.substring(dotIndex);
  }
}
