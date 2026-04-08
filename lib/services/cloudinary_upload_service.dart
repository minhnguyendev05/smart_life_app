import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryUploadService {
  bool get isConfigured =>
      CloudinaryConfig.cloudName.isNotEmpty &&
      CloudinaryConfig.uploadPreset.isNotEmpty;

  // Sử dụng 'auto' để Cloudinary tự nhận diện định dạng file tốt nhất
  String _uploadUrl() =>
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/auto/upload';

  Future<String?> uploadBytes({
    required List<int> bytes,
    required String filename,
    required String folder,
  }) async {
    if (!isConfigured) return null;

    try {
      final optimizedBytes = await _optimizeImageIfNeeded(bytes, filename);
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl()));
      
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
        debugPrint('❌ Cloudinary Error: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      // Trả về URL an toàn (https)
      return data['secure_url'] as String?;
    } catch (e) {
      debugPrint('❌ Connection Error: $e');
      return null;
    }
  }

  Future<List<int>> _optimizeImageIfNeeded(List<int> bytes, String filename) async {
    final lower = filename.toLowerCase();
    final imageLike = lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
    if (!imageLike || kIsWeb) return bytes;

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        Uint8List.fromList(bytes),
        quality: 75,
      );
      return compressed.isEmpty ? bytes : compressed;
    } catch (_) {
      return bytes;
    }
  }
}
