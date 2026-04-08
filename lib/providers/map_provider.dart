import 'dart:math' show sin, cos, asin, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Model for a location suggestion (place, classroom, etc.)
class LocationSuggestion {
  LocationSuggestion({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type, // 'library', 'cafeteria', 'classroom', etc.
    this.iconUrl,
  });

  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String type;
  final String? iconUrl;

  /// Pre-defined locations at Hanoi Water University
  static final defaultLocations = <LocationSuggestion>[
    LocationSuggestion(
      id: 'lib_a',
      name: 'Thư viện A',
      description: 'Thư viện chính, tầng 1-4',
      latitude: 20.8890,
      longitude: 106.7010,
      type: 'library',
    ),
    LocationSuggestion(
      id: 'cafeteria_main',
      name: 'Nhà ăn Chính',
      description: 'Nhà ăn lớn, 2 tầng',
      latitude: 20.8870,
      longitude: 106.7020,
      type: 'cafeteria',
    ),
    LocationSuggestion(
      id: 'cafeteria_sub',
      name: 'Quán cơm giá rẻ',
      description: 'Ăn nhanh gần sân chơi',
      latitude: 20.8880,
      longitude: 106.6995,
      type: 'cafeteria',
    ),
    LocationSuggestion(
      id: 'building_a1',
      name: 'Tòa A1 (Lý Thuyết)',
      description: 'Giảng đường, phòng học lý thuyết',
      latitude: 20.8900,
      longitude: 106.7000,
      type: 'classroom',
    ),
    LocationSuggestion(
      id: 'building_b2',
      name: 'Tòa B2 (Thực Hành)',
      description: 'Phòng thực hành, lab',
      latitude: 20.8875,
      longitude: 106.7030,
      type: 'classroom',
    ),
    LocationSuggestion(
      id: 'playground',
      name: 'Sân chơi',
      description: 'Sân bóng đá, cầu lông',
      latitude: 20.8860,
      longitude: 106.7000,
      type: 'facility',
    ),
  ];
}

/// Navigation route information
class NavigationRoute {
  NavigationRoute({
    required this.from,
    required this.to,
    required this.distance, // in meters
    required this.estimatedDuration, // in minutes
    this.polylinePoints = const [],
  });

  final LocationSuggestion from;
  final LocationSuggestion to;
  final double distance;
  final int estimatedDuration;
  final List<LatLng> polylinePoints;
}

/// Map Provider for managing map state, location, and navigation
/// Uses Flutter Map (OpenStreetMap) instead of Google Maps
class MapProvider extends ChangeNotifier {
  MapController? _mapController;
  Position? _currentPosition;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  LocationSuggestion? _selectedLocation;
  NavigationRoute? _currentRoute;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  MapController? get mapController => _mapController;
  Position? get currentPosition => _currentPosition;
  List<Marker> get markers => _markers;
  List<Polyline> get polylines => _polylines;
  LocationSuggestion? get selectedLocation => _selectedLocation;
  NavigationRoute? get currentRoute => _currentRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Initialize the map with current location and default markers
  Future<void> initializeMap() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current position
      await _updateCurrentPosition();

      // Add default location markers
      _addDefaultMarkers();

      // Add user's current position marker
      if (_currentPosition != null) {
        _addUserMarker();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi khởi tạo bản đồ: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get current device location
  Future<void> _updateCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Dịch vụ vị trí chưa được bật');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Quyền truy cập vị trí bị từ chối');
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // Fallback to Hanoi Water University
      _currentPosition = Position(
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
  }

  /// Add all default location markers
  void _addDefaultMarkers() {
    for (final location in LocationSuggestion.defaultLocations) {
      final marker = _createMarker(location);
      _markers.add(marker);
    }
  }

  /// Create a marker for a location (flutter_map)
  Marker _createMarker(LocationSuggestion location) {
    final color = _getMarkerIconColor(location.type);
    return Marker(
      point: LatLng(location.latitude, location.longitude),
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () => selectLocation(location),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Text(
                _getMarkerEmoji(location.type),
                style: const TextStyle(fontSize: 20),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                location.name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get color for marker icon based on location type
  Color _getMarkerIconColor(String type) {
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

  /// Get emoji for marker based on location type
  String _getMarkerEmoji(String type) {
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

  /// Add the user's current position marker
  void _addUserMarker() {
    if (_currentPosition == null) return;

    final userMarker = Marker(
      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      width: 80,
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: const Text('📍', style: TextStyle(fontSize: 22)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'Vị trí của bạn',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    _markers.add(userMarker);
  }

  /// Select a location and zoom to it
  void selectLocation(LocationSuggestion location) {
    _selectedLocation = location;
    _currentRoute = null;
    _polylines.clear();

    if (_mapController != null) {
      _mapController!.move(LatLng(location.latitude, location.longitude), 16);
    }

    notifyListeners();
  }

  /// Start navigation to a location from current position
  Future<void> startNavigation(LocationSuggestion destination) async {
    if (_currentPosition == null) {
      _errorMessage = 'Vị trí hiện tại chưa xác định';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final from = LocationSuggestion(
        id: 'current_pos',
        name: 'Vị trí hiện tại',
        description: 'Điểm bắt đầu',
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        type: 'current',
      );

      // Calculate simple route (in real app, use Google Directions API)
      final route = await _calculateRoute(from, destination);
      _currentRoute = route;

      // Draw polyline on map
      _drawRoute(route);

      // Zoom to fit route
      _zoomToRoute();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi tính toán tuyến đường: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate route between two locations (simple Haversine distance)
  Future<NavigationRoute> _calculateRoute(
    LocationSuggestion from,
    LocationSuggestion to,
  ) async {
    // Calculate straight-line distance (in real app, use routing API)
    final distance = _calculateDistanceFromCoords(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );

    // Estimate duration: 1.4 m/s average walking speed
    final estimatedDuration = (distance / 1.4 / 60).round();

    // Create polyline points (simple line for demo)
    final polylinePoints = [
      LatLng(from.latitude, from.longitude),
      // Add intermediate points for better visualization
      LatLng(
        (from.latitude + to.latitude) / 2,
        (from.longitude + to.longitude) / 2,
      ),
      LatLng(to.latitude, to.longitude),
    ];

    return NavigationRoute(
      from: from,
      to: to,
      distance: distance,
      estimatedDuration: estimatedDuration,
      polylinePoints: polylinePoints,
    );
  }

  /// Draw the calculated route on the map
  void _drawRoute(NavigationRoute route) {
    _polylines.clear();
    _polylines.add(
      Polyline(
        points: route.polylinePoints,
        color: Colors.blue,
        strokeWidth: 5,
      ),
    );
  }

  /// Zoom map to fit the entire route
  void _zoomToRoute() {
    if (_currentRoute == null || _mapController == null) return;

    final bounds = _calculateBounds(_currentRoute!.polylinePoints);
    final centerPoint = LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.east + bounds.west) / 2,
    );

    // Calculate appropriate zoom level based on bounds
    final distance = _calculateDistance(
      LatLng(bounds.north, bounds.west),
      LatLng(bounds.south, bounds.east),
    );
    final zoom = _calculateZoomFromDistance(distance);

    _mapController!.move(centerPoint, zoom);
  }

  /// Calculate approximate zoom level based on distance
  double _calculateZoomFromDistance(double distanceMeters) {
    // Rough approximation: zoom level based on distance
    if (distanceMeters > 50000) return 10;
    if (distanceMeters > 20000) return 11;
    if (distanceMeters > 10000) return 12;
    if (distanceMeters > 5000) return 13;
    if (distanceMeters > 2000) return 14;
    if (distanceMeters > 1000) return 15;
    return 16;
  }

  /// Calculate bounding box for a list of points
  LatLngBounds _calculateBounds(List<LatLng> points) {
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

    return LatLngBounds(
      LatLng(maxLat, minLng), // northWest
      LatLng(minLat, maxLng), // southEast
    );
  }

  /// Calculate distance between two LatLng points (Haversine formula)
  double _calculateDistance(LatLng from, LatLng to) {
    return _calculateDistanceFromCoords(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistanceFromCoords(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000; // Radius in meters
    final dLat = _toRadian(lat2 - lat1);
    final dLng = _toRadian(lng2 - lng1);

    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadian(lat1)) *
            cos(_toRadian(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * asin(sqrt(a));
    return earthRadius * c; // Distance in meters
  }

  double _toRadian(double degree) => degree * (3.14159265359 / 180);

  /// Set the Flutter Map controller callback
  void onMapCreated(MapController controller) {
    _mapController = controller;
  }

  /// Stop navigation and clear route
  void stopNavigation() {
    _currentRoute = null;
    _polylines.clear();
    notifyListeners();
  }

  /// Get nearby locations based on type
  List<LocationSuggestion> getNearbyLocations(
    String type, {
    double radiusMeters = 500,
  }) {
    if (_currentPosition == null) return [];

    return LocationSuggestion.defaultLocations.where((location) {
      if (location.type != type) return false;

      final distance = _calculateDistanceFromCoords(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        location.latitude,
        location.longitude,
      );

      return distance <= radiusMeters;
    }).toList();
  }

  /// Cleanup
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
