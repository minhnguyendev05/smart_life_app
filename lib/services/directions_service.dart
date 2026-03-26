import 'dart:convert';

import 'package:http/http.dart' as http;

class RouteStep {
  RouteStep({
    required this.instruction,
    required this.distanceMeters,
  });

  final String instruction;
  final double distanceMeters;
}

class RouteResult {
  RouteResult({
    required this.path,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<({double lat, double lng})> path;
  final List<RouteStep> steps;
  final double distanceMeters;
  final double durationSeconds;
}

class DirectionsService {
  Future<RouteResult?> fetchRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final path = '/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat';
    final uri = Uri.https('router.project-osrm.org', path, {
      'overview': 'full',
      'geometries': 'geojson',
      'steps': 'true',
    });

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = (body['routes'] as List?) ?? const [];
      if (routes.isEmpty) {
        return null;
      }

      final first = routes.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>? ?? const {};
      final coords = (geometry['coordinates'] as List?) ?? const [];
      final waypoints = coords.map((c) {
        final row = c as List;
        return (lat: (row[1] as num).toDouble(), lng: (row[0] as num).toDouble());
      }).toList();

      final legs = (first['legs'] as List?) ?? const [];
      final allSteps = <RouteStep>[];
      for (final leg in legs) {
        final legMap = leg as Map<String, dynamic>;
        final steps = (legMap['steps'] as List?) ?? const [];
        for (final step in steps) {
          final stepMap = step as Map<String, dynamic>;
          final maneuver = stepMap['maneuver'] as Map<String, dynamic>? ?? const {};
          final maneuverType = maneuver['type'] as String? ?? 'drive';
          final modifier = maneuver['modifier'] as String? ?? '';
          final distance = (stepMap['distance'] as num?)?.toDouble() ?? 0;
          final name = (stepMap['name'] as String?)?.trim() ?? '';
          final instruction = _buildInstruction(
            maneuverType: maneuverType,
            modifier: modifier,
            roadName: name,
          );
          allSteps.add(RouteStep(instruction: instruction, distanceMeters: distance));
        }
      }

      return RouteResult(
        path: waypoints,
        steps: allSteps,
        distanceMeters: (first['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (first['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  String _buildInstruction({
    required String maneuverType,
    required String modifier,
    required String roadName,
  }) {
    final road = roadName.isEmpty ? '' : ' vao $roadName';
    switch (maneuverType) {
      case 'turn':
        if (modifier == 'left') return 'Re trai$road';
        if (modifier == 'right') return 'Re phai$road';
        return 'Re $modifier$road';
      case 'new name':
        return 'Di tiep tuc$road';
      case 'depart':
        return 'Bat dau hanh trinh$road';
      case 'arrive':
        return 'Da den noi';
      case 'roundabout':
        return 'Di theo vong xuyen$road';
      default:
        return 'Di thang$road';
    }
  }
}
