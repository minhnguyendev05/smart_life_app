import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

class PdfOptimizationService {
  bool get isConfigured =>
      AppSecrets.ilovePdfApiKey.isNotEmpty &&
      AppSecrets.ilovePdfCompressEndpoint.isNotEmpty;

  Future<Uint8List> compressPdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (!isConfigured) {
      return bytes;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppSecrets.ilovePdfCompressEndpoint),
      )
        ..headers['Authorization'] = 'Bearer ${AppSecrets.ilovePdfApiKey}'
        ..headers['Accept'] = 'application/pdf'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename,
          ),
        );

      final streamed = await request.send();
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        return bytes;
      }

      final compressed = await streamed.stream.toBytes();
      if (compressed.isEmpty) {
        return bytes;
      }
      return Uint8List.fromList(compressed);
    } catch (_) {
      return bytes;
    }
  }
}
