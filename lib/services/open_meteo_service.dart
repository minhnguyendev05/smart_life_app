import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../services/local_storage_service.dart';
import '../services/weather_service.dart';

/// Open-Meteo Service - Free, no API key required
/// Uses Open-Meteo API (https://open-meteo.com/) for weather data
///
/// Advantages over OpenWeatherMap:
/// - No API key required (completely free)
/// - No rate limits (generous for personal use)
/// - Faster, simpler API responses
/// - Includes air quality data
class OpenMeteoService {
  static const _cacheKeyToday = 'weather_today_cache';
  static const _cacheKeyTomorrow = 'weather_tomorrow_cache';
  static const _cacheDurationHours = 3;

  // Weather code to description mapping (WMO codes)
  static const _weatherCodeDescriptions = {
    0: 'Trời quang đãng',
    1: 'Hầu như thoáng',
    2: 'Có mây',
    3: 'Mây rải rác',
    45: 'Sương mù',
    48: 'Sương mù nhẹ',
    51: 'Mưa nhỏ nhất',
    53: 'Mưa vừa',
    55: 'Mưa nặng',
    61: 'Mưa',
    63: 'Mưa vừa',
    65: 'Mưa nặng',
    71: 'Tuyết',
    73: 'Tuyết vừa',
    75: 'Tuyết nặng',
    80: 'Mưa rải rác',
    81: 'Mưa',
    82: 'Mưa nặng',
    85: 'Tuyết rải rác',
    86: 'Tuyết',
    95: 'Giông bão',
    96: 'Giông bão + mưa đá',
    99: 'Giông bão + tuyết',
  };

  final LocalStorageService storage;

  OpenMeteoService({required this.storage});

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
      final lat = pos.latitude.toStringAsFixed(2);
      final lng = pos.longitude.toStringAsFixed(2);

      // Call Open-Meteo forecast API
      final forecastUri = Uri.parse('https://api.open-meteo.com/v1/forecast')
          .replace(
            queryParameters: {
              'latitude': lat,
              'longitude': lng,
              'daily':
                  'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,wind_speed_10m_max',
              'timezone': 'auto',
              'temperature_unit': 'celsius',
            },
          );

      // Debug: Print the full API URL
      if (kDebugMode) {
        debugPrint('📅 Forecast API URL: ${forecastUri.toString()}');
      }

      final response = await http
          .get(forecastUri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Forecast API error: ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // Extract location info
      final city = _getLocationName(pos);

      // Extract daily forecast data
      final daily = json['daily'] as Map<String, dynamic>? ?? {};
      final times = (daily['time'] as List?)?.cast<String>() ?? [];
      final codes = (daily['weather_code'] as List?)?.cast<int>() ?? [];
      final tempMax = (daily['temperature_2m_max'] as List?)?.cast<num>() ?? [];
      final tempMin = (daily['temperature_2m_min'] as List?)?.cast<num>() ?? [];
      final windSpeed =
          (daily['wind_speed_10m_max'] as List?)?.cast<num>() ?? [];

      if (times.isEmpty || codes.isEmpty) {
        throw Exception('Empty forecast data');
      }

      // Find tomorrow's forecast (index 1)
      int forecastIndex = 1;
      if (times.length > 1) {
        forecastIndex = 1;
      }

      final code = codes.length > forecastIndex
          ? codes[forecastIndex]
          : codes[0];
      final maxTemp = tempMax.length > forecastIndex
          ? tempMax[forecastIndex].toDouble()
          : 20.0;
      final minTemp = tempMin.length > forecastIndex
          ? tempMin[forecastIndex].toDouble()
          : 15.0;
      final avgTemp = (maxTemp + minTemp) / 2;
      final windSpd = windSpeed.length > forecastIndex
          ? windSpeed[forecastIndex].toDouble()
          : 0.0;
      final description = _weatherCodeDescriptions[code] ?? 'Không rõ';

      final snapshot = WeatherSnapshot(
        city: city,
        temperature: avgTemp,
        feelsLike: avgTemp - 1.5, // Rough feels_like estimate
        humidity:
            65, // Default, Open-Meteo doesn't provide daily humidity in free tier
        windSpeed: windSpd,
        aqi: 0, // Will be fetched from air quality API
        summary: 'Dự báo mai: $description (${maxTemp.toStringAsFixed(0)}°C)',
      );

      // Try to fetch AQI separately
      final aqiSnapshot = await _fetchAirQuality(pos);
      final finalSnapshot = WeatherSnapshot(
        city: snapshot.city,
        temperature: snapshot.temperature,
        feelsLike: snapshot.feelsLike,
        humidity: snapshot.humidity,
        windSpeed: snapshot.windSpeed,
        aqi: aqiSnapshot.aqi,
        summary: snapshot.summary,
      );

      await _cacheWeather(_cacheKeyTomorrow, finalSnapshot);
      return finalSnapshot;
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

  /// Internal: Fetch current weather from Open-Meteo API
  Future<WeatherSnapshot> _fetchWeatherFromAPI() async {
    final pos = await _resolveLocation();
    final lat = pos.latitude.toStringAsFixed(2);
    final lng = pos.longitude.toStringAsFixed(2);

    // Call current weather API (use hourly data)
    final weatherUri = Uri.parse('https://api.open-meteo.com/v1/forecast')
        .replace(
          queryParameters: {
            'latitude': lat,
            'longitude': lng,
            'current_weather': 'true',
            'hourly': 'relative_humidity_2m,apparent_temperature',
            'timezone': 'auto',
            'temperature_unit': 'celsius',
          },
        );

    // Debug: Print the full API URL
    if (kDebugMode) {
      debugPrint('🌤️ Weather API URL: ${weatherUri.toString()}');
    }

    final weatherRes = await http
        .get(weatherUri)
        .timeout(const Duration(seconds: 10));

    if (weatherRes.statusCode != 200) {
      throw Exception('Weather API error: ${weatherRes.statusCode}');
    }

    final json = jsonDecode(weatherRes.body) as Map<String, dynamic>;
    final current = json['current_weather'] as Map<String, dynamic>? ?? {};
    final hourly = json['hourly'] as Map<String, dynamic>? ?? {};

    final temp = (current['temperature'] as num?)?.toDouble() ?? 20.0;
    final feelsLike = () {
      final times = (hourly['time'] as List?)?.cast<String>() ?? [];
      final apparentValues =
          (hourly['apparent_temperature'] as List?)?.cast<num>() ?? [];
      final currentTime = current['time'] as String?;
      if (currentTime != null && currentTime.isNotEmpty) {
        final nowIndex = _findHourlyIndex(times, currentTime);
        if (nowIndex >= 0 && nowIndex < apparentValues.length) {
          return apparentValues[nowIndex].toDouble();
        }
      }
      return temp; // Fallback to actual temperature
    }();
    final windSpeed = (current['windspeed'] as num?)?.toDouble() ?? 0.0;
    final code = current['weathercode'] as int? ?? 0;
    final description = _weatherCodeDescriptions[code] ?? 'Không rõ';

    final humidity = () {
      final times = (hourly['time'] as List?)?.cast<String>() ?? [];
      final humidityValues =
          (hourly['relative_humidity_2m'] as List?)?.cast<num>() ?? [];
      final currentTime = current['time'] as String?;
      if (currentTime != null && currentTime.isNotEmpty) {
        final nowIndex = _findHourlyIndex(times, currentTime);
        if (nowIndex >= 0 && nowIndex < humidityValues.length) {
          return humidityValues[nowIndex].toDouble().round();
        }
      }
      return 50;
    }();

    // Fetch air quality
    final aqiSnapshot = await _fetchAirQuality(pos);

    final city = _getLocationName(pos);

    return WeatherSnapshot(
      city: city,
      temperature:
          feelsLike, // Use apparent_temperature as main temperature (feels more real)
      feelsLike: temp, // Actual measured temperature as feels like
      humidity: humidity,
      windSpeed: windSpeed,
      aqi: aqiSnapshot.aqi,
      summary: description,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  /// Fetch air quality data from Open-Meteo
  Future<WeatherSnapshot> _fetchAirQuality(Position pos) async {
    try {
      final lat = pos.latitude.toStringAsFixed(2);
      final lng = pos.longitude.toStringAsFixed(2);

      final aqiUri = Uri.parse('https://api.open-meteo.com/v1/air-quality')
          .replace(
            queryParameters: {
              'latitude': lat,
              'longitude': lng,
              'hourly': 'us_aqi',
              'timezone': 'auto',
            },
          );

      // Debug: Print the full API URL
      if (kDebugMode) {
        debugPrint('🌫️ AQI API URL: ${aqiUri.toString()}');
      }

      final response = await http
          .get(aqiUri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final hourly = json['hourly'] as Map<String, dynamic>? ?? {};
        final times = (hourly['time'] as List?)?.cast<String>() ?? [];
        final usAqi = (hourly['us_aqi'] as List?)?.cast<num>() ?? [];

        final currentTime = DateTime.now().toIso8601String();
        final index = _findHourlyIndex(times, currentTime);

        final rawAqi = index >= 0 && index < usAqi.length
            ? usAqi[index].toInt()
            : (usAqi.isNotEmpty ? usAqi.first.toInt() : 0);

        // Map US AQI to European AQI scale
        final aqi = _mapUsAqiToEuropean(rawAqi);

        return WeatherSnapshot(
          city: _getLocationName(pos),
          temperature: 0,
          feelsLike: 0,
          humidity: 0,
          windSpeed: 0,
          aqi: aqi,
          summary: '',
        );
      }
    } catch (_) {
      // Silently fail - AQI is optional
    }

    return WeatherSnapshot(
      city: '',
      temperature: 0,
      feelsLike: 0,
      humidity: 0,
      windSpeed: 0,
      aqi: 0,
      summary: '',
    );
  }

  /// Find the appropriate hourly index for a given time string, handling timezone and formatting differences.
  int _findHourlyIndex(List<String> times, String currentTime) {
    final normalizedCurrent = _normalizeHourlyTime(currentTime);
    final normalizedTimes = times
        .map((t) => _normalizeHourlyTime(t))
        .toList(growable: false);
    final exactIndex = normalizedTimes.indexOf(normalizedCurrent);
    if (exactIndex >= 0) return exactIndex;

    final currentDate = DateTime.tryParse(currentTime);
    if (currentDate != null) {
      return normalizedTimes.indexWhere((hour) {
        final parsed = DateTime.tryParse(hour);
        return parsed != null &&
            parsed.year == currentDate.year &&
            parsed.month == currentDate.month &&
            parsed.day == currentDate.day &&
            parsed.hour == currentDate.hour;
      });
    }

    return -1;
  }

  String _normalizeHourlyTime(String time) {
    final parsed = DateTime.tryParse(time);
    if (parsed == null) return time.length >= 16 ? time.substring(0, 16) : time;
    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
    ).toIso8601String().substring(0, 16);
  }

  /// Map US AQI to European AQI scale
  int _mapUsAqiToEuropean(int usAqi) {
    if (usAqi <= 50) return 1; // Good
    if (usAqi <= 100) return 2; // Fair
    if (usAqi <= 150) return 3; // Moderate
    return 4; // Poor/Very Poor (European scale goes to 5, but we cap at 4 for simplicity)
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
      return _hannoiWaterUniversityPosition();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Fallback to Hanoi Water University
      return _hannoiWaterUniversityPosition();
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Get Hanoi Water University position
  Position _hannoiWaterUniversityPosition() {
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

  /// Get location name from coordinates (reverse geocoding)
  /// For now, returns common Vietnam locations
  String _getLocationName(Position pos) {
    // Check if near Hanoi (20.8°N, 106.8°E)
    if (pos.latitude > 20.5 &&
        pos.latitude < 21.2 &&
        pos.longitude > 106.4 &&
        pos.longitude < 107.0) {
      return 'Hà Nội';
    }
    // Check if near Ho Chi Minh (10.8°N, 106.7°E)
    if (pos.latitude > 10.4 &&
        pos.latitude < 11.2 &&
        pos.longitude > 106.3 &&
        pos.longitude < 107.1) {
      return 'TP. Hồ Chí Minh';
    }
    // Default
    return 'Vị trí của bạn';
  }
}
