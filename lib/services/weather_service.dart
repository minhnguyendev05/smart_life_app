import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';
import '../services/local_storage_service.dart';

/// Enum for AQI severity levels
enum AQISeverity { good, fair, moderate, poor, veryPoor }

/// Enhanced Weather Snapshot with AQI details and caching support
class WeatherSnapshot {
  WeatherSnapshot({
    required this.city,
    required this.temperature,
    required this.aqi,
    required this.summary,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    this.timestamp = '',
    this.fromCache = false,
  });

  final String city;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int aqi;
  final String summary;
  final String timestamp;
  final bool fromCache;

  /// Get AQI severity level
  AQISeverity get aqiSeverity {
    if (aqi <= 1) return AQISeverity.good;
    if (aqi <= 2) return AQISeverity.fair;
    if (aqi <= 3) return AQISeverity.moderate;
    if (aqi <= 4) return AQISeverity.poor;
    return AQISeverity.veryPoor;
  }

  /// Check if AQI is bad (poor or very poor)
  bool get isBadAQI => aqi >= 4;

  /// Check if outdoor activities are safe based on weather conditions
  bool get isOutdoorSafe => !isBadAQI && temperature >= 5 && temperature <= 35;

  /// Get AQI description in Vietnamese
  String get aqiDescription {
    switch (aqiSeverity) {
      case AQISeverity.good:
        return 'Tốt';
      case AQISeverity.fair:
        return 'Khá';
      case AQISeverity.moderate:
        return 'Trung bình';
      case AQISeverity.poor:
        return 'Xấu';
      case AQISeverity.veryPoor:
        return 'Rất xấu';
    }
  }

  /// Convert to Map for caching
  Map<String, dynamic> toMap() => {
    'city': city,
    'temperature': temperature,
    'feelsLike': feelsLike,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'aqi': aqi,
    'summary': summary,
    'timestamp': DateTime.now().toIso8601String(),
  };

  /// Create from cached Map
  factory WeatherSnapshot.fromMap(Map<String, dynamic> map) => WeatherSnapshot(
    city: map['city'] as String? ?? 'Không rõ',
    temperature: (map['temperature'] as num?)?.toDouble() ?? 0,
    feelsLike: (map['feelsLike'] as num?)?.toDouble() ?? 0,
    humidity: map['humidity'] as int? ?? 0,
    windSpeed: (map['windSpeed'] as num?)?.toDouble() ?? 0,
    aqi: map['aqi'] as int? ?? 0,
    summary: map['summary'] as String? ?? 'Không rõ',
    timestamp: map['timestamp'] as String? ?? '',
    fromCache: true,
  );
}

/// Weather Forecast with today and tomorrow
class WeatherForecast {
  WeatherForecast({required this.today, required this.tomorrow});

  final WeatherSnapshot today;
  final WeatherSnapshot tomorrow;
}

/// Enhanced Weather Service with local cache fallback
class WeatherService {
  static const _cacheKeyToday = 'weather_today_cache';
  static const _cacheKeyTomorrow = 'weather_tomorrow_cache';
  static const _cacheDurationHours = 3;

  final LocalStorageService storage;

  WeatherService({required this.storage});

  /// Fetch weather for today and tomorrow with cache fallback
  Future<WeatherForecast> fetchTodayAndTomorrow() async {
    final today = await fetchToday();
    final tomorrow = await fetchTomorrow();
    return WeatherForecast(today: today, tomorrow: tomorrow);
  }

  /// Fetch today's weather with fallback to cache
  Future<WeatherSnapshot> fetchToday() async {
    try {
      final snapshot = await _fetchWeatherFromAPI();
      // Cache the result
      await _cacheWeather(_cacheKeyToday, snapshot);
      return snapshot;
    } catch (e) {
      // Fallback to cached weather
      final cached = await _getCachedWeather(_cacheKeyToday);
      if (cached != null) {
        return cached;
      }
      // Return error snapshot
      return WeatherSnapshot(
        city: 'Không rõ',
        temperature: 0,
        feelsLike: 0,
        humidity: 0,
        windSpeed: 0,
        aqi: 0,
        summary: 'Lỗi kết nối. Dữ liệu không khả dụng',
      );
    }
  }

  /// Fetch tomorrow's weather with cache fallback
  Future<WeatherSnapshot> fetchTomorrow() async {
    try {
      final pos = await _resolveLocation();
      final forecastUri =
          Uri.parse('https://api.openweathermap.org/data/2.5/forecast').replace(
            queryParameters: {
              'lat': '${pos.latitude}',
              'lon': '${pos.longitude}',
              'units': 'metric',
              'lang': 'vi',
              'appid': AppSecrets.openWeatherApiKey,
            },
          );

      final response = await http
          .get(forecastUri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Forecast API error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final city =
          (json['city'] as Map<String, dynamic>?)?['name'] as String? ??
          'Unknown';
      final list = (json['list'] as List?) ?? const [];
      if (list.isEmpty) {
        throw Exception('Empty forecast list');
      }

      // Find forecast for tomorrow around noon
      final now = DateTime.now();
      final tomorrowDate = DateTime(now.year, now.month, now.day + 1);
      Map<String, dynamic>? candidate;

      for (final item in list) {
        final row = item as Map<String, dynamic>;
        final dtTxt = row['dt_txt'] as String?;
        if (dtTxt == null) continue;
        final dt = DateTime.tryParse(dtTxt);
        if (dt == null) continue;
        if (dt.year == tomorrowDate.year &&
            dt.month == tomorrowDate.month &&
            dt.day == tomorrowDate.day) {
          candidate = row;
          final h = dt.hour;
          if (h >= 11 && h <= 14) {
            break;
          }
        }
      }

      final row = candidate ?? (list.first as Map<String, dynamic>);
      final main = row['main'] as Map<String, dynamic>? ?? const {};
      final weather =
          (row['weather'] as List?)?.firstOrNull as Map<String, dynamic>?;

      final snapshot = WeatherSnapshot(
        city: city,
        temperature: (main['temp'] as num?)?.toDouble() ?? 0,
        feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0,
        humidity: main['humidity'] as int? ?? 0,
        windSpeed:
            ((row['wind'] as Map<String, dynamic>?)?['speed'] as num?)
                ?.toDouble() ??
            0,
        aqi: 0,
        summary:
            'Dự báo mai: ${weather?['description'] as String? ?? 'Không rõ'}',
      );

      await _cacheWeather(_cacheKeyTomorrow, snapshot);
      return snapshot;
    } catch (e) {
      final cached = await _getCachedWeather(_cacheKeyTomorrow);
      if (cached != null) {
        return cached;
      }
      return WeatherSnapshot(
        city: 'Không rõ',
        temperature: 0,
        feelsLike: 0,
        humidity: 0,
        windSpeed: 0,
        aqi: 0,
        summary: 'Không lấy được dự báo ngày mai',
      );
    }
  }

  /// Internal: Fetch weather from API
  Future<WeatherSnapshot> _fetchWeatherFromAPI() async {
    if (AppSecrets.openWeatherApiKey.isEmpty) {
      // Return demo/mock data if no API key
      return WeatherSnapshot(
        city: 'Hà Nội (Demo)',
        temperature: 26.5,
        feelsLike: 27.2,
        humidity: 72,
        windSpeed: 2.8,
        aqi: 2,
        summary: 'Mây rải rác - Chế độ Demo',
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    final pos = await _resolveLocation();
    final weatherUri =
        Uri.parse('https://api.openweathermap.org/data/2.5/weather').replace(
          queryParameters: {
            'lat': '${pos.latitude}',
            'lon': '${pos.longitude}',
            'units': 'metric',
            'lang': 'vi',
            'appid': AppSecrets.openWeatherApiKey,
          },
        );

    final aqiUri =
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/air_pollution',
        ).replace(
          queryParameters: {
            'lat': '${pos.latitude}',
            'lon': '${pos.longitude}',
            'appid': AppSecrets.openWeatherApiKey,
          },
        );

    final weatherRes = await http
        .get(weatherUri)
        .timeout(const Duration(seconds: 10));
    final aqiRes = await http.get(aqiUri).timeout(const Duration(seconds: 10));

    if (weatherRes.statusCode != 200) {
      throw Exception('Weather API error: ${weatherRes.statusCode}');
    }

    final weatherJson = jsonDecode(weatherRes.body) as Map<String, dynamic>;
    final weather =
        (weatherJson['weather'] as List<dynamic>?)?.firstOrNull
            as Map<String, dynamic>?;
    final main = weatherJson['main'] as Map<String, dynamic>?;

    int aqi = 0;
    if (aqiRes.statusCode == 200) {
      final aqiJson = jsonDecode(aqiRes.body) as Map<String, dynamic>;
      final first =
          (aqiJson['list'] as List<dynamic>?)?.firstOrNull
              as Map<String, dynamic>?;
      aqi = (first?['main'] as Map<String, dynamic>?)?['aqi'] as int? ?? 0;
    }

    return WeatherSnapshot(
      city: weatherJson['name'] as String? ?? 'Unknown',
      temperature: (main?['temp'] as num?)?.toDouble() ?? 0,
      feelsLike: (main?['feels_like'] as num?)?.toDouble() ?? 0,
      humidity: main?['humidity'] as int? ?? 0,
      windSpeed:
          ((weatherJson['wind'] as Map<String, dynamic>?)?['speed'] as num?)
              ?.toDouble() ??
          0,
      aqi: aqi,
      summary: weather?['description'] as String? ?? 'Không rõ',
    );
  }

  /// Cache weather snapshot to local storage
  Future<void> _cacheWeather(String key, WeatherSnapshot snapshot) async {
    try {
      await storage.saveList(key, [snapshot.toMap()]);
    } catch (_) {
      // Silently fail caching
    }
  }

  /// Get cached weather snapshot from local storage
  Future<WeatherSnapshot?> _getCachedWeather(String key) async {
    try {
      final list = await storage.readList(key);
      if (list.isEmpty) return null;

      final map = Map<String, dynamic>.from(list[0]);
      final cached = WeatherSnapshot.fromMap(map);

      // Check cache expiry
      if (cached.timestamp.isNotEmpty) {
        final cacheTime = DateTime.parse(cached.timestamp);
        final now = DateTime.now();
        if (now.difference(cacheTime).inHours > _cacheDurationHours) {
          return null; // Cache expired
        }
      }

      return cached;
    } catch (_) {
      return null;
    }
  }

  /// Resolve current device location with fallback to Hanoi Water University
  Future<Position> _resolveLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Fallback to Hanoi Water University (Thủy Lợi)
      return Position(
        longitude: 106.7009,
        latitude: 20.8883,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Fallback to Hanoi Water University
      return Position(
        longitude: 106.7009,
        latitude: 20.8883,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}
