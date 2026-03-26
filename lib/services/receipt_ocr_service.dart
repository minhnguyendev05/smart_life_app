import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

class ReceiptOcrResult {
  ReceiptOcrResult({
    required this.title,
    required this.amount,
    required this.category,
    required this.rawText,
  });

  final String title;
  final double amount;
  final String category;
  final String rawText;
}

class ReceiptOcrService {
  bool get isConfigured => AppSecrets.ocrApiKey.isNotEmpty;

  Future<ReceiptOcrResult?> parseReceipt({
    required List<int> imageBytes,
    required String filename,
  }) async {
    final text = await _extractText(imageBytes: imageBytes, filename: filename);
    if (text == null || text.trim().isEmpty) {
      return null;
    }

    final amount = _extractAmount(text);
    final category = _guessCategory(text);
    final title = _guessTitle(text, category);

    return ReceiptOcrResult(
      title: title,
      amount: amount,
      category: category,
      rawText: text,
    );
  }

  Future<String?> _extractText({
    required List<int> imageBytes,
    required String filename,
  }) async {
    if (!isConfigured) {
      return null;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.ocr.space/parse/image'),
      );

      request.headers['apikey'] = AppSecrets.ocrApiKey;
      request.fields['language'] = 'eng';
      request.fields['isOverlayRequired'] = 'false';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

        final streamed = await request.send().timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamed)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final parsed = data['ParsedResults'] as List<dynamic>?;
      if (parsed == null || parsed.isEmpty) {
        return null;
      }

      return parsed.first['ParsedText'] as String?;
    } catch (_) {
      return null;
    }
  }

  double _extractAmount(String text) {
    final normalized = text.replaceAll(',', '.');
    final regex = RegExp(r'\d+(?:\.\d{1,3})?(?:\.\d{3})*');
    final matches = regex.allMatches(normalized).map((m) => m.group(0) ?? '').toList();

    double best = 0;
    for (final m in matches) {
      final v = double.tryParse(m.replaceAll('.', '')) ?? double.tryParse(m) ?? 0;
      if (v > best) {
        best = v;
      }
    }
    return best;
  }

  String _guessCategory(String text) {
    final t = text.toLowerCase();
    if (t.contains('coffee') || t.contains('tea') || t.contains('food') || t.contains('restaurant')) {
      return 'An uong';
    }
    if (t.contains('book') || t.contains('stationery') || t.contains('print')) {
      return 'Học tập';
    }
    if (t.contains('taxi') || t.contains('grab') || t.contains('bus')) {
      return 'Di chuyen';
    }
    return 'Sinh hoat';
  }

  String _guessTitle(String text, String category) {
    final firstLine = text.split('\n').map((e) => e.trim()).firstWhere(
          (e) => e.isNotEmpty,
          orElse: () => '',
        );
    if (firstLine.isNotEmpty) {
      return firstLine.length > 40 ? firstLine.substring(0, 40) : firstLine;
    }
    return 'Hoa don $category';
  }
}
