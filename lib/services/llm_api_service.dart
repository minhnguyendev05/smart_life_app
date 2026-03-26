import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

class LlmApiService {
  Future<String?> generateReply(String prompt) async {
    if (AppSecrets.llmApiKey.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse(AppSecrets.llmEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AppSecrets.llmApiKey}',
            },
            body: jsonEncode({
              'model': AppSecrets.llmModel,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are SmartLife student assistant. Keep answers concise and practical.',
                },
                {
                  'role': 'user',
                  'content': prompt,
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return null;
      }
      final message = choices.first['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return null;
      }
      return content.trim();
    } catch (_) {
      return null;
    }
  }
}
