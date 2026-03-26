import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NearbyPlace {
  NearbyPlace({
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  final String title;
  final double latitude;
  final double longitude;
  final double distanceMeters;
}

class NearbyPlacesService {
  Future<List<NearbyPlace>> fetchNearbyPlaces({
    required double lat,
    required double lng,
    int radiusMeters = 1200,
    int limit = 10,
  }) async {
    final query = '''
[out:json][timeout:15];
(
  node(around:$radiusMeters,$lat,$lng)["amenity"~"cafe|restaurant|library|fast_food|pharmacy|college|school|bank"];
);
out body 60;
''';

    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {'Content-Type': 'text/plain; charset=utf-8'},
            body: query,
          )
          .timeout(const Duration(seconds: 14));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = (body['elements'] as List?) ?? const [];

      final mapped = elements.map((row) {
        final item = row as Map<String, dynamic>;
        final tags = item['tags'] as Map<String, dynamic>? ?? const {};
        final name = (tags['name'] as String?)?.trim();
        final amenity = (tags['amenity'] as String?)?.trim() ?? 'place';
        final placeLat = (item['lat'] as num?)?.toDouble() ?? 0;
        final placeLng = (item['lon'] as num?)?.toDouble() ?? 0;
        final distance = Geolocator.distanceBetween(lat, lng, placeLat, placeLng);

        return NearbyPlace(
          title: name == null || name.isEmpty ? amenity : name,
          latitude: placeLat,
          longitude: placeLng,
          distanceMeters: distance,
        );
      }).where((e) => e.latitude != 0 && e.longitude != 0).toList();

      mapped.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return mapped.take(limit).toList();
    } catch (_) {
      return [];
    }
  }
}
