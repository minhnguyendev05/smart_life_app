import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

class CloudinaryUploadService {
  bool get isConfigured =>
      AppSecrets.cloudinaryCloudName.isNotEmpty &&
      AppSecrets.cloudinaryUploadPreset.isNotEmpty;

  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/${AppSecrets.cloudinaryCloudName}/auto/upload';

  Future<String?> uploadBytes({
    required List<int> bytes,
    required String filename,
    required String folder,
  }) async {
    if (!isConfigured) {
      return null;
    }

    try {
      final optimizedBytes = await _optimizeImageIfNeeded(bytes, filename);
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = AppSecrets.cloudinaryUploadPreset;
      request.fields['folder'] = folder;
      request.fields['quality'] = 'auto:good';
      request.fields['fetch_format'] = 'auto';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          optimizedBytes,
          filename: filename,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>> _optimizeImageIfNeeded(List<int> bytes, String filename) async {
    final lower = filename.toLowerCase();
    final imageLike = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
    if (!imageLike) {
      return bytes;
    }

    if (kIsWeb) {
      return bytes;
    }

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        quality: 72,
        minWidth: 1280,
        minHeight: 1280,
      );
      if (compressed.isEmpty) {
        return bytes;
      }
      return compressed;
    } catch (_) {
      return bytes;
    }
  }
}
