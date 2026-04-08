// Open Map Service - Configuration for OpenStreetMap tiles via Flutter Map
//
// This service provides:
// - Free OpenStreetMap tile layer (no API key needed)
// - Marker configurations for different location types
// - Polyline styling for routes
// - Camera bounds calculation
//
// No external APIs required - everything is local and free!

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// OpenStreetMap tile configuration
class OpenMapService {
  /// OpenStreetMap Standard Tile Layer configuration
  /// Free to use, no API key required
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttribution =
      '© OpenStreetMap contributors | Free for personal use';

  /// Get TileLayer for OpenStreetMap
  static TileLayer getOsmTileLayer() {
    return TileLayer(
      urlTemplate: osmTileUrl,
      userAgentPackageName: 'com.example.smartlifeapp',
    );
  }

  /// Get marker color based on location type
  static Color getMarkerColor(String type) {
    switch (type) {
      case 'library':
        return Colors.blue;
      case 'cafeteria':
        return Colors.orange;
      case 'classroom':
        return Colors.red;
      case 'facility':
        return Colors.green;
      case 'current':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Get marker icon emoji based on location type
  static String getMarkerEmoji(String type) {
    switch (type) {
      case 'library':
        return '📚';
      case 'cafeteria':
        return '🍜';
      case 'classroom':
        return '🏫';
      case 'facility':
        return '⚽';
      case 'current':
        return '📍';
      default:
        return '📌';
    }
  }

  /// Create a styled Polyline for routes
  static Polyline createRoutePolyline(
    List<LatLng> points, {
    Color color = Colors.blue,
    double width = 5,
  }) {
    return Polyline(points: points, color: color, strokeWidth: width);
  }

  /// Calculate bounding box for multiple LatLng points
  static LatLngBounds calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError('Cannot calculate bounds for empty list');
    }

    double maxLat = points[0].latitude;
    double minLat = points[0].latitude;
    double maxLng = points[0].longitude;
    double minLng = points[0].longitude;

    for (final point in points) {
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLng = maxLng < point.longitude ? point.longitude : maxLng;
      minLng = minLng > point.longitude ? point.longitude : minLng;
    }

    return LatLngBounds(LatLng(maxLat, minLng), LatLng(minLat, maxLng));
  }

  /// Predefined camera position for Hanoi Water University
  static const LatLng hanoiWaterUniversityCenter = LatLng(20.8883, 106.7009);
  static const double defaultZoom = 15.0;
  static const double minZoom = 2.0;
  static const double maxZoom = 18.0;

  /// Animation duration for camera updates
  static const Duration cameraPanDuration = Duration(milliseconds: 500);

  /// Calculate center point between two locations
  static LatLng calculateMidpoint(LatLng start, LatLng end) {
    return LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2,
    );
  }

  /// Distance calculation using Haversine formula
  /// Returns distance in meters
  static double calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371000; // in meters
    final dLat = _toRadian(end.latitude - start.latitude);
    final dLng = _toRadian(end.longitude - start.longitude);

    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_toRadian(start.latitude)) *
            math.cos(_toRadian(end.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  static double _toRadian(double degree) => degree * (math.pi / 180);

  // Re-export for convenience
  static const emptyLatLng = LatLng(0, 0);
}
