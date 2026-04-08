import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

enum _LlmProviderType { openai, gemini, groq, unknown }

class LlmApiService {
  Future<String?> generateReply(String prompt) async {
    if (AppSecrets.llmApiKey.isEmpty) {
      return null;
    }

    final endpoint = AppSecrets.llmEndpoint;
    final uri = Uri.parse(endpoint);
    final provider = _resolveProvider(uri);

    try {
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(provider),
            body: jsonEncode(_buildRequest(provider, prompt)),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final data = jsonDecode(response.body);
      return _extractResponseText(provider, data)?.trim();
    } catch (_) {
      return null;
    }
  }

  _LlmProviderType _resolveProvider(Uri uri) {
    final providerName = AppSecrets.llmProvider.toLowerCase();

    if (providerName != 'auto') {
      if (providerName.contains('gemini')) return _LlmProviderType.gemini;
      if (providerName.contains('groq')) return _LlmProviderType.groq;
      if (providerName.contains('openai')) return _LlmProviderType.openai;
    }

    final host = uri.host.toLowerCase();
    if (host.contains('openai.com')) return _LlmProviderType.openai;
    if (host.contains('groq.com')) return _LlmProviderType.groq;
    if (host.contains('gemini') || host.contains('googleapis.com')) {
      return _LlmProviderType.gemini;
    }
    return _LlmProviderType.openai;
  }

  Map<String, String> _buildHeaders(_LlmProviderType provider) {
    if (provider == _LlmProviderType.gemini) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppSecrets.llmApiKey}',
      };
    }

    if (provider == _LlmProviderType.groq) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppSecrets.llmApiKey}',
      };
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${AppSecrets.llmApiKey}',
    };
  }

  Map<String, dynamic> _buildRequest(_LlmProviderType provider, String prompt) {
    switch (provider) {
      case _LlmProviderType.gemini:
        return {
          'model': AppSecrets.llmModel,
          'temperature': 0.7,
          'max_output_tokens': 512,
          'instances': [
            {'content': prompt},
          ],
        };
      case _LlmProviderType.groq:
        return {
          'model': AppSecrets.llmModel,
          'prompt': prompt,
          'temperature': 0.7,
          'max_tokens': 512,
        };
      case _LlmProviderType.openai:
      case _LlmProviderType.unknown:
        return {
          'model': AppSecrets.llmModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are SmartLife student assistant. Keep answers concise and practical.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 512,
        };
    }
  }

  String? _extractResponseText(_LlmProviderType provider, dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    if (provider == _LlmProviderType.openai ||
        provider == _LlmProviderType.unknown) {
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return null;
      final message = choices.first['message'] as Map<String, dynamic>?;
      return message?['content'] as String?;
    }

    if (provider == _LlmProviderType.gemini) {
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final firstCandidate = candidates.first as Map<String, dynamic>;
        final content = firstCandidate['content'];
        if (content is String) return content;
        if (content is List && content.isNotEmpty) {
          final firstChunk = content.first;
          if (firstChunk is Map<String, dynamic>) {
            return firstChunk['text'] as String? ??
                firstChunk['content'] as String?;
          }
        }
      }
    }

    if (provider == _LlmProviderType.groq) {
      final output = data['output'] as String?;
      if (output != null && output.isNotEmpty) return output;
      final outputs = data['outputs'] as List<dynamic>?;
      if (outputs != null && outputs.isNotEmpty) {
        final firstOutput = outputs.first;
        if (firstOutput is Map<String, dynamic>) {
          return firstOutput['generated_text'] as String? ??
              firstOutput['text'] as String?;
        }
      }
    }

    // Generic fallback for common fields.
    return data['text'] as String? ?? data['output_text'] as String?;
  }
}
