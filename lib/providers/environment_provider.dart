import 'dart:async';
import 'package:flutter/material.dart';

import '../services/open_meteo_service.dart';
import '../services/local_reminder_service.dart';
import '../services/weather_service.dart';

/// Environment Provider manages weather data and AQI monitoring
class EnvironmentProvider extends ChangeNotifier {
  EnvironmentProvider({
    required this.weatherService,
    required this.reminderService,
  });

  final OpenMeteoService weatherService;
  final LocalReminderService reminderService;

  WeatherSnapshot? _currentWeather;
  WeatherSnapshot? _tomorrowWeather;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _refreshTimer;
  static const _refreshIntervalMinutes = 30;

  // Getters
  WeatherSnapshot? get currentWeather => _currentWeather;
  WeatherSnapshot? get tomorrowWeather => _tomorrowWeather;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _currentWeather != null;
  bool get isBadAQI => _currentWeather?.isBadAQI ?? false;

  /// Initialize weather data and setup auto-refresh
  Future<void> initialize() async {
    await loadWeatherData();
    _startAutoRefresh();
  }

  /// Load weather data from service
  Future<void> loadWeatherData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final forecast = await weatherService.fetchTodayAndTomorrow();
      _currentWeather = forecast.today;
      _tomorrowWeather = forecast.tomorrow;

      // Notice: Bad AQI is displayed in UI and recommendations
      // Notifications can be scheduled using LocalReminderService

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi tải dữ liệu thời tiết: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get weather description with recommendations
  String getWeatherRecommendation() {
    final current = _currentWeather;
    if (current == null) return 'Không có dữ liệu thời tiết';

    final buffer = StringBuffer();
    buffer.writeln('🌡️ Nhiệt độ: ${current.temperature.toStringAsFixed(1)}°C');
    buffer.writeln('Cảm nhận như: ${current.feelsLike.toStringAsFixed(1)}°C');
    buffer.writeln('💧 Độ ẩm: ${current.humidity}%');
    buffer.writeln(
      '💨 Tốc độ gió: ${current.windSpeed.toStringAsFixed(1)} m/s',
    );
    buffer.writeln(current.summary);

    // Add recommendations based on weather
    if (current.temperature < 15) {
      buffer.writeln('\n💡 Gợi ý: Thời tiết lạnh, hãy mặc áo ấm.');
    } else if (current.temperature > 30) {
      buffer.writeln('\n💡 Gợi ý: Thời tiết nóng, phai uống nhiều nước.');
    }

    if (current.windSpeed > 5) {
      buffer.writeln('💡 Gợi ý: Gió mạnh, cẩn thận khi di chuyển ngoài trời.');
    }

    if (current.isBadAQI) {
      buffer.writeln(
        '💡 Gợi ý: Chất lượng không khí ${current.aqiDescription}. '
        'Nên đeo khẩu trang ngoài trời.',
      );
    }

    return buffer.toString();
  }

  /// Get icon emoji for AQI
  String getAQIEmoji() {
    final current = _currentWeather;
    if (current == null) return '❓';

    switch (current.aqiSeverity) {
      case AQISeverity.good:
        return '😊';
      case AQISeverity.fair:
        return '☺️';
      case AQISeverity.moderate:
        return '😐';
      case AQISeverity.poor:
        return '😷';
      case AQISeverity.veryPoor:
        return '😷😷';
    }
  }

  /// Determine if outdoor activities are safe
  bool isOutdoorSafe() {
    final current = _currentWeather;
    if (current == null) return true;

    // Not safe if AQI is poor or very poor
    if (current.isBadAQI) return false;

    // Not safe if temperature is extremely hot or cold
    if (current.temperature < 0 || current.temperature > 35) return false;

    // Not safe if wind speed is too high
    if (current.windSpeed > 10) return false;

    return true;
  }

  /// Get recommendation for studying based on weather
  String getStudyRecommendation() {
    final current = _currentWeather;
    if (current == null) return 'Hãy kiểm tra dữ liệu thời tiết';

    if (!isOutdoorSafe()) {
      return '🏠 Điều kiện thời tiết không tốt. Hãy ở nhà hoặc vào phòng học trong nhà.';
    }

    if (current.isBadAQI) {
      return '😷 Chất lượng không khí ${current.aqiDescription}. '
          'Nếu phải đi, hãy đeo khẩu trang.';
    }

    if (current.temperature < 15) {
      return '🧥 Thời tiết lạnh, mặc áo ấm khi đi học.';
    }

    if (current.temperature > 30) {
      return '☀️ Thời tiết nóng, mang theo nước uống và ô.';
    }

    return '✅ Điều kiện thời tiết tốt cho học tập. Hãy tỉnh táo!';
  }

  /// Start auto-refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(minutes: _refreshIntervalMinutes),
      (_) => loadWeatherData(),
    );
  }

  /// Manual refresh
  Future<void> refreshNow() async {
    await loadWeatherData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
