import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryUploadService {
  bool get isConfigured =>
      CloudinaryConfig.cloudName.isNotEmpty &&
      CloudinaryConfig.uploadPreset.isNotEmpty;

  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/auto/upload';

  Future<String?> uploadBytes({
    required List<int> bytes,
    required String filename,
    required String folder,
  }) async {
    if (!isConfigured) {
      debugPrint('❌ Cloudinary chưa được cấu hình. Vui lòng kiểm tra cloudinary_config.dart');
      return null;
    }

    try {
      final optimizedBytes = await _optimizeImageIfNeeded(bytes, filename);
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Sử dụng các thông số từ cấu hình mới
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = folder;
      
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
        debugPrint('❌ Lỗi Cloudinary (${response.statusCode}): ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String?;
    } catch (e) {
      debugPrint('❌ Lỗi kết nối Cloudinary: $e');
      return null;
    }
  }

  Future<List<int>> _optimizeImageIfNeeded(List<int> bytes, String filename) async {
    final lower = filename.toLowerCase();
    final imageLike = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
    if (!imageLike) return bytes;
    if (kIsWeb) return bytes;

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        quality: 72,
        minWidth: 1280,
        minHeight: 1280,
      );
      return compressed.isEmpty ? bytes : compressed;
    } catch (_) {
      return bytes;
    }
  }
}
