import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../services/llm_api_service.dart';
import '../services/open_meteo_service.dart';
import '../services/weather_service.dart';
import '../providers/map_provider.dart';

/// AI-powered smart suggestion
class SmartSuggestion {
  SmartSuggestion({
    required this.title,
    required this.description,
    required this.category, // 'weather', 'study', 'finance', 'navigation'
    required this.priority, // 1-10
    required this.actionUrl,
    this.emoji = '💡',
  });

  final String title;
  final String description;
  final String category;
  final int priority;
  final String emoji;
  final String actionUrl; // URI to launch action
}

/// AI Provider for generating smart suggestions
class AIProvider extends ChangeNotifier {
  final OpenMeteoService weatherService;
  final LlmApiService llmApiService;

  List<SmartSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;

  AIProvider({required this.weatherService, required this.llmApiService});

  // Getters
  List<SmartSuggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Generate smart suggestions based on multiple factors
  Future<void> generateSuggestions({
    required WeatherSnapshot currentWeather,
    required List<StudyTask> todaysTasks,
    required double walletBalance,
    required List<LocationSuggestion> nearbyLocations,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _suggestions = [];

      // Build context for AI
      final context = _buildContext(
        currentWeather,
        todaysTasks,
        walletBalance,
        nearbyLocations,
      );

      // Generate suggestions using LLM
      final aiSuggestions = await _generateAISuggestions(context);
      _suggestions.addAll(aiSuggestions);

      // Add rule-based suggestions as fallback/supplement
      _suggestions.addAll(
        _generateRuleBasedSuggestions(
          currentWeather,
          todaysTasks,
          walletBalance,
          nearbyLocations,
        ),
      );

      // Sort by priority (highest first)
      _suggestions.sort((a, b) => b.priority.compareTo(a.priority));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi tạo gợi ý: $e';
      // Fallback to rule-based suggestions
      _suggestions = _generateRuleBasedSuggestions(
        currentWeather,
        todaysTasks,
        walletBalance,
        nearbyLocations,
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Build context string for LLM
  String _buildContext(
    WeatherSnapshot weather,
    List<StudyTask> tasks,
    double walletBalance,
    List<LocationSuggestion> nearbyLocations,
  ) {
    final buffer = StringBuffer();

    // Weather context
    buffer.writeln('Thời tiết hiện tại:');
    buffer.writeln('- Nhiệt độ: ${weather.temperature.toStringAsFixed(1)}°C');
    buffer.writeln('- Tình trạng: ${weather.summary}');
    buffer.writeln('- AQI: ${weather.aqi} (${weather.aqiDescription})');
    buffer.writeln(
      '- Độ ẩm: ${weather.humidity}%, Gió: ${weather.windSpeed} m/s',
    );

    // Schedule context
    buffer.writeln('\nLịch học hôm nay:');
    if (tasks.isEmpty) {
      buffer.writeln('- Không có buổi học nào hôm nay');
    } else {
      for (final task in tasks) {
        final status = task.isOverdue ? '⚠️ QUAAẠ HẠN' : '📋';
        buffer.writeln(
          '$status ${task.title} (${task.subject}) - '
          'Đến ${task.deadline.hour}:${task.deadline.minute.toString().padLeft(2, '0')}',
        );
      }
    }

    // Wallet context
    buffer.writeln('\nTình hình tài chính:');
    if (walletBalance < 50000) {
      buffer.writeln(
        '- Ví: ${walletBalance.toStringAsFixed(0)} VND (CẢNH BÁO: ít tiền)',
      );
    } else if (walletBalance < 100000) {
      buffer.writeln(
        '- Ví: ${walletBalance.toStringAsFixed(0)} VND (cần tiết kiệm)',
      );
    } else {
      buffer.writeln(
        '- Ví: ${walletBalance.toStringAsFixed(0)} VND (bình thường)',
      );
    }

    // Nearby locations
    buffer.writeln('\nĐiểm gần đây:');
    if (nearbyLocations.isEmpty) {
      buffer.writeln('- Không có điểm nào gần');
    } else {
      for (final loc in nearbyLocations.take(3)) {
        buffer.writeln('- ${loc.name} (${loc.description})');
      }
    }

    return buffer.toString();
  }

  /// Generate AI suggestions using LLM (Gemini/OpenAI)
  Future<List<SmartSuggestion>> _generateAISuggestions(String context) async {
    final prompt =
        '''Dựa vào thông tin sau của sinh viên, hãy tạo 2-3 gợi ý thông minh (smart suggestions) giúp sinh viên hôm nay.
Mỗi gợi ý phải ngắn gọn (1-2 dòng), hữu ích, và cụ thể.
Trả lời theo định dạng JSON:
[
  {"title": "Tiêu đề", "description": "Mô tả chi tiết", "category": "weather|study|finance|navigation", "priority": 8}
]

Thông tin sinh viên:
$context

Gợi ý (JSON):''';

    final response = await llmApiService.generateReply(prompt);
    if (response == null || response.trim().isEmpty) {
      return [];
    }

    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch == null) return [];

      final suggestions = jsonDecode(jsonMatch.group(0)!) as List;
      return suggestions.map((item) {
        final map = item as Map<String, dynamic>;
        return SmartSuggestion(
          title: map['title'] as String? ?? 'Gợi ý',
          description: map['description'] as String? ?? '',
          category: map['category'] as String? ?? 'study',
          priority: (map['priority'] as int?) ?? 5,
          actionUrl: '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Generate rule-based suggestions (high-quality fallback)
  List<SmartSuggestion> _generateRuleBasedSuggestions(
    WeatherSnapshot weather,
    List<StudyTask> tasks,
    double walletBalance,
    List<LocationSuggestion> nearbyLocations,
  ) {
    final suggestions = <SmartSuggestion>[];

    // Weather-based suggestions
    if (weather.isBadAQI) {
      suggestions.add(
        SmartSuggestion(
          title: 'Cảnh báo chất lượng không khí',
          description:
              'Chất lượng không khí ${weather.aqiDescription}. '
              'Hãy đeo khẩu trang khi ra ngoài và hạn chế hoạt động ngoài trời.',
          category: 'weather',
          priority: 10,
          emoji: '😷',
          actionUrl: 'app://settings/health',
        ),
      );
    }

    if (weather.temperature < 10) {
      suggestions.add(
        SmartSuggestion(
          title: 'Thời tiết lạnh',
          description:
              'Nhiệt độ dưới 10°C. Mặc áo ấm, mang theo khăn khi ra ngoài.',
          category: 'weather',
          priority: 7,
          emoji: '🧥',
          actionUrl: '',
        ),
      );
    } else if (weather.temperature > 32) {
      suggestions.add(
        SmartSuggestion(
          title: 'Thời tiết nóng',
          description:
              'Nhiệt độ trên 32°C. Mang theo nước uống, ô, và kem chống nắng.',
          category: 'weather',
          priority: 7,
          emoji: '☀️',
          actionUrl: '',
        ),
      );
    }

    // Study-based suggestions
    final overdueTasks = tasks.where((t) => t.isOverdue).length;
    if (overdueTasks > 0) {
      suggestions.add(
        SmartSuggestion(
          title: 'Deadline quá hạn',
          description:
              'Bạn có $overdueTasks deadline quá hạn. '
              'Ưu tiên hoàn thành ngay trong 2 giờ tới.',
          category: 'study',
          priority: 10,
          emoji: '⚠️',
          actionUrl: 'app://study/tasks',
        ),
      );
    }

    if (tasks.isNotEmpty) {
      final nextTask = tasks.isNotEmpty ? tasks[0] : null;
      if (nextTask != null) {
        final now = DateTime.now();
        final timeUntil = nextTask.deadline.difference(now).inMinutes;

        if (timeUntil > 0 && timeUntil < 60) {
          suggestions.add(
            SmartSuggestion(
              title: 'Sắp đến giờ học',
              description:
                  'Bạn còn $timeUntil phút để đến '
                  '${nextTask.subject}. Hãy chuẩn bị ra đi!',
              category: 'study',
              priority: 9,
              emoji: '⏰',
              actionUrl: 'app://study/navigate',
            ),
          );
        }
      }
    }

    // Finance-based suggestions
    if (walletBalance < 50000) {
      final cafeterias = nearbyLocations
          .where((loc) => loc.type == 'cafeteria')
          .toList()
          .cast<LocationSuggestion>();

      String suggestion =
          'Ví còn ${walletBalance.toStringAsFixed(0)} VND (ít tiền). ';
      if (cafeterias.isNotEmpty) {
        suggestion += 'Hãy ghé ${cafeterias[0].name} để ăn cơm giá rẻ gần đây.';
      } else {
        suggestion += 'Nên tìm quán ăn giá rẻ để tiết kiệm.';
      }

      suggestions.add(
        SmartSuggestion(
          title: 'Gợi ý tiết kiệm',
          description: suggestion,
          category: 'finance',
          priority: 8,
          emoji: '💰',
          actionUrl: 'app://finance/budget',
        ),
      );
    }

    // Navigation suggestions
    if (weather.isOutdoorSafe &&
        !weather.isBadAQI &&
        tasks.isNotEmpty &&
        nearbyLocations.isNotEmpty) {
      suggestions.add(
        SmartSuggestion(
          title: 'Hướng dẫn chỉ đường',
          description: 'Thời tiết tốt. Mở bản đồ để xem tuyến đi học gần nhất.',
          category: 'navigation',
          priority: 6,
          emoji: '🗺️',
          actionUrl: 'app://map/navigate',
        ),
      );
    }

    return suggestions;
  }

  /// Get top N suggestions
  List<SmartSuggestion> getTopSuggestions({int count = 3}) {
    return _suggestions.take(count).toList();
  }

  /// Get suggestions by category
  List<SmartSuggestion> getSuggestionsByCategory(String category) {
    return _suggestions.where((s) => s.category == category).toList();
  }
}
