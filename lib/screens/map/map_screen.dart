import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;

import '../../config/app_secrets.dart';
import '../../services/directions_service.dart';
import '../../services/nearby_places_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const gmaps.LatLng _defaultCenter = gmaps.LatLng(10.7769, 106.7009);

  gmaps.GoogleMapController? _mapController;
  gmaps.LatLng _current = _defaultCenter;
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
        _current = gmaps.LatLng(pos.latitude, pos.longitude);
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
    final markers = {
      gmaps.Marker(
        markerId: const gmaps.MarkerId('me'),
        position: _current,
        infoWindow: const gmaps.InfoWindow(title: 'Vị trí của bạn'),
      ),
      ..._nearby.map(
        (p) => gmaps.Marker(
          markerId: gmaps.MarkerId(p.title),
          position: gmaps.LatLng(p.latitude, p.longitude),
          infoWindow: gmaps.InfoWindow(title: p.title, snippet: _formatDistance(p.distanceMeters)),
        ),
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ & Định vị')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (AppSecrets.mapsApiKey.isEmpty)
            const Card(
              margin: EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'GOOGLE_MAPS_API_KEY chưa được truyền qua dart-define. Bản đồ vẫn hoạt động nếu đã cấu hình MAPS_API_KEY trong native.',
                ),
              ),
            ),
          SizedBox(
            height: 230,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Container(
                          color: Theme.of(context)
                              .colorScheme
                              .errorContainer
                              .withValues(alpha: 0.35),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(16),
                          child: Text(_error!, textAlign: TextAlign.center),
                        )
                      : kIsWeb
                          ? fm.FlutterMap(
                              options: fm.MapOptions(
                                initialCenter:
                                    ll.LatLng(_current.latitude, _current.longitude),
                                initialZoom: 15,
                              ),
                              children: [
                                fm.TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.smart_life_app',
                                ),
                                fm.MarkerLayer(
                                  markers: [
                                    fm.Marker(
                                      point: ll.LatLng(
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
                                      (e) => fm.Marker(
                                        point: ll.LatLng(
                                          e.latitude,
                                          e.longitude,
                                        ),
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
                                  fm.PolylineLayer(
                                    polylines: [
                                      fm.Polyline(
                                        points: _activeRoute!.path
                                            .map((p) => ll.LatLng(p.lat, p.lng))
                                            .toList(),
                                        strokeWidth: 4,
                                        color: Colors.teal,
                                      ),
                                    ],
                                  ),
                              ],
                            )
                          : gmaps.GoogleMap(
                              initialCameraPosition: gmaps.CameraPosition(
                                target: _current,
                                zoom: 15,
                              ),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              markers: markers,
                              polylines: _activeRoute == null
                                  ? const {}
                                  : {
                                      gmaps.Polyline(
                                        polylineId: const gmaps.PolylineId('route'),
                                        color: Colors.teal,
                                        width: 5,
                                        points: _activeRoute!.path
                                            .map((p) => gmaps.LatLng(p.lat, p.lng))
                                            .toList(),
                                      ),
                                    },
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                            ),
            ),
          ),
          const SizedBox(height: 14),
          if (!_loading && _error == null)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  if (!kIsWeb) {
                    _mapController?.animateCamera(
                      gmaps.CameraUpdate.newLatLngZoom(_current, 15),
                    );
                  }
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Về vị trí tôi'),
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
                    ..._activeRoute!.steps.take(6).map(
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(item.title),
                  subtitle: Text('Cách ${_formatDistance(item.distanceMeters)}'),
                  trailing: TextButton(
                    onPressed: () => _navigateTo(
                      gmaps.LatLng(item.latitude, item.longitude),
                    ),
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

  Future<void> _navigateTo(gmaps.LatLng destination) async {
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
        const SnackBar(content: Text('Không lấy được route turn-by-turn từ API.')),
      );
      return;
    }

    if (!kIsWeb) {
      await _mapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(destination, 15.5),
      );
    }
  }
}
