import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/directions_service.dart';
import '../../services/nearby_places_service.dart';
import '../../services/open_map_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultCenter = LatLng(20.8883, 106.7009);

  LatLng _current = _defaultCenter;
  bool _loading = true;
  bool _routing = false;
  bool _loadingNearby = false;
  String? _error;
  RouteResult? _activeRoute;
  final _directionsService = DirectionsService();
  final _nearbyService = NearbyPlacesService();

  List<NearbyPlace> _nearby = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _error = 'Dịch vụ vị trí đang tắt. Hãy bật GPS.';
          _loading = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _error = 'Bạn cần cấp quyền vị trí để sử dụng tính năng bản đồ.';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _current = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });
      await _loadNearbyPlaces();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể lấy vị trí hiện tại: $e';
        _loading = false;
      });
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  Future<void> _loadNearbyPlaces() async {
    if (!mounted) return;
    setState(() {
      _loadingNearby = true;
    });

    final places = await _nearbyService.fetchNearbyPlaces(
      lat: _current.latitude,
      lng: _current.longitude,
    );

    if (!mounted) return;
    setState(() {
      _nearby = places;
      _loadingNearby = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ & Định vị')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 230,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, textAlign: TextAlign.center),
                    )
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          _current.latitude,
                          _current.longitude,
                        ),
                        initialZoom: 15,
                      ),
                      children: [
                        OpenMapService.getOsmTileLayer(),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _current.latitude,
                                _current.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                              ),
                            ),
                            ..._nearby.map(
                              (e) => Marker(
                                point: LatLng(e.latitude, e.longitude),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.place,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_activeRoute != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _activeRoute!.path
                                    .map((p) => LatLng(p.lat, p.lng))
                                    .toList(),
                                strokeWidth: 4,
                                color: Colors.teal,
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          if (!_loading && _error == null)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: _loadingNearby ? null : _loadNearbyPlaces,
                icon: const Icon(Icons.my_location),
                label: const Text('Tải lại địa điểm'),
              ),
            ),
          const SizedBox(height: 8),
          if (_routing) const LinearProgressIndicator(),
          if (_loadingNearby) const LinearProgressIndicator(),
          if (_activeRoute != null)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lộ trình: ${(_activeRoute!.distanceMeters / 1000).toStringAsFixed(1)} km • ${(_activeRoute!.durationSeconds / 60).toStringAsFixed(0)} phút',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ..._activeRoute!.steps
                        .take(6)
                        .map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• ${s.instruction} (${s.distanceMeters.toStringAsFixed(0)}m)',
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          Text(
            'Gợi ý địa điểm gần bạn',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loadingNearby ? null : _loadNearbyPlaces,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới địa điểm'),
            ),
          ),
          ..._nearby.map(
            (item) => TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              tween: Tween(begin: 0.98, end: 1),
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(item.title),
                  subtitle: Text(
                    'Cách ${_formatDistance(item.distanceMeters)}',
                  ),
                  trailing: TextButton(
                    onPressed: () =>
                        _navigateTo(LatLng(item.latitude, item.longitude)),
                    child: const Text('Chỉ đường'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateTo(LatLng destination) async {
    setState(() => _routing = true);
    final route = await _directionsService.fetchRoute(
      fromLat: _current.latitude,
      fromLng: _current.longitude,
      toLat: destination.latitude,
      toLng: destination.longitude,
    );
    if (!mounted) return;
    setState(() {
      _routing = false;
      _activeRoute = route;
    });
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không lấy được route turn-by-turn từ API.'),
        ),
      );
      return;
    }
  }
}
