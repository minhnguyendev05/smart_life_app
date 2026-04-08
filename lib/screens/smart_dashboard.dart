import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../providers/map_provider.dart';
import '../providers/environment_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/study_provider.dart';
import '../providers/finance_provider.dart';
import '../services/open_map_service.dart';
import '../services/weather_service.dart';

/// SmartDashboard - Main demo widget integrating Map + Weather + AI
class SmartDashboard extends StatefulWidget {
  const SmartDashboard({super.key});

  @override
  State<SmartDashboard> createState() => _SmartDashboardState();
}

class _SmartDashboardState extends State<SmartDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeProviders();
  }

  /// Initialize all providers
  Future<void> _initializeProviders() async {
    // Initialize map and environment providers before awaiting
    final mapProvider = context.read<MapProvider>();
    final envProvider = context.read<EnvironmentProvider>();

    await mapProvider.initializeMap();
    await envProvider.initialize();

    // Generate AI suggestions
    _generateAISuggestions();
  }

  /// Generate smart AI suggestions
  Future<void> _generateAISuggestions() async {
    final aiProvider = context.read<AIProvider>();
    final envProvider = context.read<EnvironmentProvider>();
    final mapProvider = context.read<MapProvider>();
    final studyProvider = context.read<StudyProvider>();
    final financeProvider = context.read<FinanceProvider>();

    final weather = envProvider.currentWeather;
    if (weather == null) return;

    final nearbyLocations = mapProvider.getNearbyLocations('cafeteria');

    await aiProvider.generateSuggestions(
      currentWeather: weather,
      todaysTasks: studyProvider.tasks,
      walletBalance: financeProvider.balance,
      nearbyLocations: nearbyLocations,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartLife Dashboard'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Bản đồ'),
            Tab(icon: Icon(Icons.cloud), text: 'Thời tiết'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Gợi ý'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMapTab(), _buildWeatherTab(), _buildSuggestionsTab()],
      ),
    );
  }

  /// Tab 1: Map with markers and navigation
  Widget _buildMapTab() {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, _) {
        if (mapProvider.isLoading) {
          return _buildLoadingWidget('Đang tải bản đồ...');
        }

        return Stack(
          children: [
            // Flutter Map with OpenStreetMap tiles
            FlutterMap(
              mapController: mapProvider.mapController,
              options: MapOptions(
                initialCenter: mapProvider.currentPosition != null
                    ? LatLng(
                        mapProvider.currentPosition!.latitude,
                        mapProvider.currentPosition!.longitude,
                      )
                    : const LatLng(20.8883, 106.7009),
                initialZoom: 15,
                minZoom: 2,
                maxZoom: 18,
              ),
              children: [
                // OpenStreetMap Tile Layer
                OpenMapService.getOsmTileLayer(),

                // Markers Layer
                MarkerLayer(markers: mapProvider.markers),

                // Polylines Layer for routes
                PolylineLayer(polylines: mapProvider.polylines),
              ],
            ),

            // Bottom sheet with location details
            if (mapProvider.selectedLocation != null ||
                mapProvider.currentRoute != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildLocationSheet(mapProvider),
              ),

            // Loading indicator
            if (mapProvider.isLoading)
              Center(
                child: CircularProgressIndicator(backgroundColor: Colors.white),
              ),

            // Error message
            if (mapProvider.errorMessage != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      mapProvider.errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Build location detail bottom sheet
  Widget _buildLocationSheet(MapProvider mapProvider) {
    if (mapProvider.currentRoute != null) {
      return _buildNavigationSheet(mapProvider);
    }

    final location = mapProvider.selectedLocation;
    if (location == null) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                location.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                location.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => mapProvider.startNavigation(location),
                icon: const Icon(Icons.directions),
                label: const Text('Chỉ đường'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => mapProvider.stopNavigation(),
                icon: const Icon(Icons.close),
                label: const Text('Đóng'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build navigation sheet with directions
  Widget _buildNavigationSheet(MapProvider mapProvider) {
    final route = mapProvider.currentRoute!;
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.2,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chỉ đường đến ${route.to.name}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.straighten,
                label: 'Khoảng cách',
                value: '${(route.distance / 1000).toStringAsFixed(2)} km',
              ),
              _buildInfoRow(
                icon: Icons.schedule,
                label: 'Thời gian dự kiến',
                value: '${route.estimatedDuration} phút (đi bộ)',
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  mapProvider.stopNavigation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigation stopped')),
                  );
                },
                icon: const Icon(Icons.stop),
                label: const Text('Dừng chỉ đường'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build info row
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Weather and Environment
  Widget _buildWeatherTab() {
    return Consumer<EnvironmentProvider>(
      builder: (context, envProvider, _) {
        final weather = envProvider.currentWeather;

        // Show loading state
        if (envProvider.isLoading && weather == null) {
          return _buildLoadingWidget('Đang tải thời tiết...');
        }

        // Show error state with retry
        if (envProvider.errorMessage != null && weather == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Lỗi kết nối',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            envProvider.errorMessage ?? 'Không xác định lỗi',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => envProvider.refreshNow(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        // Handle null data after loading completes
        if (weather == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Không có dữ liệu',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Không thể tải dữ liệu thời tiết. Vui lòng kiểm tra kết nối mạng.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => envProvider.refreshNow(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => envProvider.refreshNow(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current weather card
                Card(
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hôm nay',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                                Text(
                                  weather.city,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                            Text(
                              '${weather.temperature.toStringAsFixed(1)}°',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          weather.summary,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Weather details
                Text(
                  'Chi tiết',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildWeatherDetail(
                        icon: Icons.opacity,
                        label: 'Độ ẩm',
                        value: '${weather.humidity}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildWeatherDetail(
                        icon: Icons.air,
                        label: 'Gió',
                        value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildWeatherDetail(
                        icon: Icons.thermostat,
                        label: 'Cảm nhận',
                        value: '${weather.feelsLike.toStringAsFixed(1)}°C',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildWeatherDetail(
                        icon: Icons.health_and_safety,
                        label: 'AQI',
                        value: '${weather.aqi}',
                        color: weather.aqi >= 4 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // AQI Status
                _buildAQICard(weather, envProvider),
                const SizedBox(height: 20),

                // Recommendations
                Text(
                  'Gợi ý hoạt động',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _buildRecommendationCard(
                  envProvider.getStudyRecommendation(),
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildRecommendationCard(
                  envProvider.getWeatherRecommendation(),
                  Colors.orange,
                ),

                // Tomorrow forecast
                if (envProvider.tomorrowWeather != null) ...[
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dự báo ngày mai',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            envProvider.tomorrowWeather!.summary,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nhiệt độ dự kiến: '
                            '${envProvider.tomorrowWeather!.temperature.toStringAsFixed(1)}°C',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build weather detail card
  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.blue),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// Build AQI status card
  Widget _buildAQICard(
    WeatherSnapshot weather,
    EnvironmentProvider envProvider,
  ) {
    final isBad = weather.isBadAQI;
    return Card(
      color: isBad ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              envProvider.getAQIEmoji(),
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chất lượng không khí ${weather.aqiDescription}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isBad ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isBad
                        ? 'Hãy đeo khẩu trang khi ra ngoài'
                        : 'Điều kiện tốt để hoạt động ngoài trời',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build recommendation card
  Widget _buildRecommendationCard(String text, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  /// Tab 3: AI Smart Suggestions
  Widget _buildSuggestionsTab() {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, _) {
        if (aiProvider.isLoading) {
          return _buildLoadingWidget('Đang tạo gợi ý...');
        }

        if (aiProvider.suggestions.isEmpty) {
          return _buildEmptyWidget('Không có gợi ý nào');
        }

        return RefreshIndicator(
          onRefresh: () => _generateAISuggestions(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: aiProvider.suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = aiProvider.suggestions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSuggestionCard(suggestion),
              );
            },
          ),
        );
      },
    );
  }

  /// Build individual suggestion card
  Widget _buildSuggestionCard(SmartSuggestion suggestion) {
    final priorityColor = suggestion.priority >= 8
        ? Colors.red
        : suggestion.priority >= 6
        ? Colors.orange
        : Colors.blue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(suggestion.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Ưu tiên ${suggestion.priority}/10',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              suggestion.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(suggestion.category.toUpperCase()),
              backgroundColor: _getCategoryColor(
                suggestion.category,
              ).withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  /// Get color for suggestion category
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'weather':
        return Colors.blue;
      case 'study':
        return Colors.purple;
      case 'finance':
        return Colors.green;
      case 'navigation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Build loading widget
  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  /// Build empty widget
  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

/// Extension for WeatherSnapshot to provide additional utilities
extension WeatherSnapshotExtension on WeatherSnapshot {
  bool get isOutdoorSafe => !isBadAQI && temperature >= 5 && temperature <= 35;
}
