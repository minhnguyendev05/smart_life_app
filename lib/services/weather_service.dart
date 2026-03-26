import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

class WeatherSnapshot {
  WeatherSnapshot({
    required this.city,
    required this.temperature,
    required this.aqi,
    required this.summary,
  });

  final String city;
  final double temperature;
  final int aqi;
  final String summary;
}

class WeatherForecast {
  WeatherForecast({
    required this.today,
    required this.tomorrow,
  });

  final WeatherSnapshot today;
  final WeatherSnapshot tomorrow;
}

class WeatherService {
  Future<WeatherForecast> fetchTodayAndTomorrow() async {
    final today = await fetchToday();
    final tomorrow = await fetchTomorrow();
    return WeatherForecast(today: today, tomorrow: tomorrow);
  }

  Future<WeatherSnapshot> fetchToday() async {
    if (AppSecrets.openWeatherApiKey.isEmpty) {
      return WeatherSnapshot(
        city: 'Không rõ',
        temperature: 0,
        aqi: 0,
        summary: 'Thiếu OPENWEATHER_API_KEY',
      );
    }

    try {
      final pos = await _resolveLocation();
      final weatherUri = Uri.parse('https://api.openweathermap.org/data/2.5/weather').replace(
        queryParameters: {
          'lat': '${pos.latitude}',
          'lon': '${pos.longitude}',
          'units': 'metric',
          'lang': 'vi',
          'appid': AppSecrets.openWeatherApiKey,
        },
      );

      final aqiUri = Uri.parse('https://api.openweathermap.org/data/2.5/air_pollution').replace(
        queryParameters: {
          'lat': '${pos.latitude}',
          'lon': '${pos.longitude}',
          'appid': AppSecrets.openWeatherApiKey,
        },
      );

      final weatherRes = await http.get(weatherUri).timeout(const Duration(seconds: 10));
      final aqiRes = await http.get(aqiUri).timeout(const Duration(seconds: 10));

      if (weatherRes.statusCode != 200) {
        throw Exception('weather api status ${weatherRes.statusCode}');
      }

      final weatherJson = jsonDecode(weatherRes.body) as Map<String, dynamic>;
      final weather = (weatherJson['weather'] as List<dynamic>?)?.firstOrNull
          as Map<String, dynamic>?;

      int aqi = 0;
      if (aqiRes.statusCode == 200) {
        final aqiJson = jsonDecode(aqiRes.body) as Map<String, dynamic>;
        final first = (aqiJson['list'] as List<dynamic>?)?.firstOrNull
            as Map<String, dynamic>?;
        aqi = (first?['main'] as Map<String, dynamic>?)?['aqi'] as int? ?? 0;
      }

      return WeatherSnapshot(
        city: weatherJson['name'] as String? ?? 'Unknown',
        temperature: ((weatherJson['main'] as Map<String, dynamic>?)?['temp'] as num?)
                ?.toDouble() ??
            0,
        aqi: aqi,
        summary: weather?['description'] as String? ?? 'Không rõ',
      );
    } catch (_) {
      return WeatherSnapshot(
        city: 'Không rõ',
        temperature: 0,
        aqi: 0,
        summary: 'Không lấy được dữ liệu thời tiết',
      );
    }
  }

  Future<WeatherSnapshot> fetchTomorrow() async {
    if (AppSecrets.openWeatherApiKey.isEmpty) {
      return WeatherSnapshot(
        city: 'Không rõ',
        temperature: 0,
        aqi: 0,
        summary: 'Thiếu OPENWEATHER_API_KEY',
      );
    }

    try {
      final pos = await _resolveLocation();
      final forecastUri = Uri.parse('https://api.openweathermap.org/data/2.5/forecast').replace(
        queryParameters: {
          'lat': '${pos.latitude}',
          'lon': '${pos.longitude}',
          'units': 'metric',
          'lang': 'vi',
          'appid': AppSecrets.openWeatherApiKey,
        },
      );

      final response = await http.get(forecastUri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('forecast api status ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final city = (json['city'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown';
      final list = (json['list'] as List?) ?? const [];
      if (list.isEmpty) {
        throw Exception('empty forecast');
      }

      final now = DateTime.now();
      final tomorrowDate = DateTime(now.year, now.month, now.day + 1);
      Map<String, dynamic>? candidate;

      for (final item in list) {
        final row = item as Map<String, dynamic>;
        final dtTxt = row['dt_txt'] as String?;
        if (dtTxt == null) continue;
        final dt = DateTime.tryParse(dtTxt);
        if (dt == null) continue;
        if (dt.year == tomorrowDate.year && dt.month == tomorrowDate.month && dt.day == tomorrowDate.day) {
          candidate = row;
          final h = dt.hour;
          if (h >= 11 && h <= 14) {
            break;
          }
        }
      }

      final row = candidate ?? (list.first as Map<String, dynamic>);
      final main = row['main'] as Map<String, dynamic>? ?? const {};
      final weather = (row['weather'] as List?)?.firstOrNull as Map<String, dynamic>?;

      return WeatherSnapshot(
        city: city,
        temperature: (main['temp'] as num?)?.toDouble() ?? todayFallback.temperature,
        aqi: 76,
        summary: 'Dự báo mai: ${weather?['description'] as String? ?? 'Không rõ'}',
      );
    } catch (_) {
      return WeatherSnapshot(
        city: 'Không rõ',
        temperature: 0,
        aqi: 0,
        summary: 'Không lấy được dự báo ngày mai',
      );
    }
  }

  WeatherSnapshot get todayFallback => WeatherSnapshot(
        city: 'Không rõ',
        temperature: 0,
        aqi: 0,
        summary: 'Không có dữ liệu',
      );

  Future<Position> _resolveLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Position(
        longitude: 106.7009,
        latitude: 10.7769,
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
      return Position(
        longitude: 106.7009,
        latitude: 10.7769,
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
