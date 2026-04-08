# SmartLife Map + Environment + AI Module

## Overview

This module integrates three key features for the SmartLife application:
1. **Google Maps with Navigation** - Location discovery and directions to campus locations
2. **Environmental Monitoring** - Real-time weather and AQI with fallback caching
3. **AI-Powered Smart Suggestions** - Context-aware recommendations based on weather, schedule, and finances

## Architecture

### Services
- **`weather_service.dart`** - Handles weather and AQI data fetching with local cache fallback
- **`local_reminder_service.dart`** - Manages local notifications
- **`local_storage_service.dart`** - Provides Hive-based persistent storage

### Providers
- **`map_provider.dart`** - Manages map state, location markers, and navigation
- **`environment_provider.dart`** - Manages weather data and AQI with auto-refresh
- **`ai_provider.dart`** - Generates smart suggestions using LLM + rule-based logic

### Screens
- **`smart_dashboard.dart`** - Main demo widget with 3 tabs:
  - Map tab with markers and navigation
  - Weather tab with detailed info and recommendations
  - Suggestions tab with prioritized recommendations

## Setup & Configuration

### 1. Add Environment Variables

Create a `.env` file or use Flutter build flags:

```bash
flutter run \
  --dart-define=OPENWEATHER_API_KEY=your_key \
  --dart-define=GOOGLE_MAPS_API_KEY=your_key \
  --dart-define=LLM_API_KEY=your_key \
  --dart-define=LLM_MODEL=gpt-4o-mini \
  --dart-define=LLM_ENDPOINT=https://api.openai.com/v1/chat/completions
```

### 2. Platform-Specific Setup

#### Android (`android/app/build.gradle.kts`)
```kotlin
android {
    ...
    defaultConfig {
        ...
        resValue "string", "google_maps_key", "YOUR_GOOGLE_MAPS_API_KEY"
    }
}
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>GoogleMapsAPIKey</key>
<string>YOUR_GOOGLE_MAPS_API_KEY</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs your location to show weather and navigation</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs your location to show weather and navigation</string>
```

#### Web (`web/index.html`)
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>
```

### 3. Initialize in main.dart

```dart
import 'package:provider/provider.dart';
import 'services/weather_service.dart';
import 'services/local_reminder_service.dart';
import 'services/local_storage_service.dart';
import 'providers/map_provider.dart';
import 'providers/environment_provider.dart';
import 'providers/ai_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final localStorage = LocalStorageService();
  await localStorage.init();
  
  final reminderService = LocalReminderService();
  await reminderService.ensureInitialized();
  
  final weatherService = WeatherService(storage: localStorage);

  runApp(
    MultiProvider(
      providers: [
        Provider<WeatherService>(create: (_) => weatherService),
        Provider<LocalReminderService>(create: (_) => reminderService),
        ChangeNotifierProvider(
          create: (_) => MapProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => EnvironmentProvider(
            weatherService: weatherService,
            reminderService: reminderService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AIProvider(weatherService: weatherService),
        ),
      ],
      child: const SmartLifeApp(),
    ),
  );
}
```

## Usage Examples

### 1. Display Weather in UI

```dart
Consumer<EnvironmentProvider>(
  builder: (context, envProvider, _) {
    final weather = envProvider.currentWeather;
    return Column(
      children: [
        Text('Temperature: ${weather?.temperature}°C'),
        Text('AQI: ${weather?.aqi} - ${weather?.aqiDescription}'),
        if (weather?.isBadAQI ?? false)
          Text('⚠️ ${envProvider.getStudyRecommendation()}'),
      ],
    );
  },
)
```

### 2. Navigate to Campus Locations

```dart
final mapProvider = context.read<MapProvider>();

// Select a location
mapProvider.selectLocation(nearbyLibrary);

// Start navigation
await mapProvider.startNavigation(nearbyLibrary);

// Stop navigation
mapProvider.stopNavigation();
```

### 3. Get AI Suggestions

```dart
final aiProvider = context.read<AIProvider>();

await aiProvider.generateSuggestions(
  currentWeather: currentWeather,
  todaysTasks: studyProvider.tasks,
  walletBalance: financeProvider.balance,
  nearbyLocations: mapProvider.getNearbyLocations('cafeteria'),
);

// Display top 3 suggestions
for (final suggestion in aiProvider.getTopSuggestions(count: 3)) {
  print('${suggestion.emoji} ${suggestion.title}');
  print(suggestion.description);
}
```

### 4. Get Nearby Locations

```dart
final mapProvider = context.read<MapProvider>();

// Get cafeterias within 500m
final nearbyFood = mapProvider.getNearbyLocations('cafeteria', radiusMeters: 500);

// Get libraries within 1km
final nearbyStudy = mapProvider.getNearbyLocations('library', radiusMeters: 1000);
```

## Data Models

### WeatherSnapshot
```dart
class WeatherSnapshot {
  final String city;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int aqi;
  final String summary;
  
  // Helpers
  bool get isBadAQI => aqi >= 4;
  bool get isOutdoorSafe => !isBadAQI && temperature >= 5 && temperature <= 35;
  AQISeverity get aqiSeverity;
  String get aqiDescription;
}
```

### LocationSuggestion
```dart
class LocationSuggestion {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String type; // library, cafeteria, classroom, facility, current
}
```

### SmartSuggestion
```dart
class SmartSuggestion {
  final String title;
  final String description;
  final String category; // weather, study, finance, navigation
  final int priority; // 1-10
  final String emoji;
  final String actionUrl;
}
```

## Fallback Mechanisms

### Weather Service
1. Try fetching from OpenWeather API
2. If API fails and network available → try again with timeout
3. If all fails → get last cached weather from Hive (up to 3 hours old)
4. If no cache → return error state with sensible defaults

### Location Services
1. Try getting actual GPS position
2. If GPS disabled or permission denied → default to Hanoi Water University coordinates
3. Nearby locations are calculated using Haversine formula

### LLM Suggestions
1. Try calling LLM API (Gemini/OpenAI)
2. If LLM fails or times out → fall back to rule-based suggestions
3. Combine both for comprehensive coverage

## Key Features

### Environmental Awareness
- ✅ Real-time weather with 30-minute auto-refresh
- ✅ AQI severity classification (Good/Fair/Moderate/Poor/Very Poor)
- ✅ Context-aware recommendations (dress code, outdoor safety, etc.)
- ✅ Local cache fallback for offline use
- ✅ Beautiful Material 3 UI with dark mode support

### Smart Navigation
- ✅ 10+ pre-defined campus locations
- ✅ Real-time marker display with custom icons
- ✅ Route visualization with estimated duration
- ✅ Haversine distance calculation
- ✅ Bottom sheet UI for location details

### AI Suggestions
- ✅ LLM-powered (OpenAI/Gemini) smart suggestions
- ✅ Rule-based fallback for reliability
- ✅ Category-based filtering (weather, study, finance, navigation)
- ✅ Priority scoring for relevance
- ✅ Context from: weather, schedule, wallet, location

## Testing

### Mock Data
Use pre-defined test locations and weather:

```dart
// Test with mock weather
final mockWeather = WeatherSnapshot(
  city: 'Hà Nội',
  temperature: 28.5,
  feelsLike: 30.0,
  humidity: 75,
  windSpeed: 2.5,
  aqi: 3,
  summary: 'Partly cloudy',
);

// Test navigation
await mapProvider.selectLocation(
  LocationSuggestion.defaultLocations[0]
);
```

### API Testing
```bash
# Test OpenWeather API
curl "https://api.openweathermap.org/data/2.5/weather?lat=20.8883&lon=106.7009&appid=YOUR_KEY&units=metric&lang=vi"

# Test OpenWeather AQI
curl "https://api.openweathermap.org/data/2.5/air_pollution?lat=20.8883&lon=106.7009&appid=YOUR_KEY"
```

## Troubleshooting

### Weather Data Not Loading
- Check OpenWeather API key in build flags
- Verify internet connection
- Check device location permissions
- Review Hive cache in debugger

### Maps Not Displaying
- Ensure Google Maps API key is set for all platforms
- Clear app cache: `flutter clean`
- Check AndroidManifest.xml has location permissions

### AI Suggestions Not Generated
- Verify LLM API key and endpoint
- Check network connectivity
- Review rule-based fallback is working
- Check API quota and rate limits

## Performance Considerations

1. **Weather Refresh**: Auto-refreshes every 30 minutes (configurable)
2. **Cache Duration**: Weather cached for 3 hours maximum
3. **Map Markers**: 10+ markers loaded on map initialization
4. **API Timeouts**: All API calls have 10-30 second timeouts
5. **LLM Caching**: Suggestions cached in memory during session

## Future Enhancements

- [ ] Real-time public transport directions via Google Directions API
- [ ] Historical weather analytics
- [ ] Personalized location recommendations
- [ ] Weather-based study schedule suggestions
- [ ] Integration with campus event calendar
- [ ] Multi-language support for all suggestions
- [ ] Offline map caching with Mapbox
- [ ] Advanced AQI visualization heatmap

## Dependencies

```yaml
# Core
flutter: sdk
provider: ^6.1.2

# Maps & Location
google_maps_flutter: ^2.12.3
geolocator: ^14.0.2

# Weather & APIs
http: ^1.2.2
intl: ^0.20.2

# Storage
hive: ^2.2.3
hive_flutter: ^1.1.0
sqflite: ^2.4.1

# Notifications
flutter_local_notifications: ^18.0.1
timezone: ^0.10.1
```

## License

This module is part of the SmartLife application. All rights reserved.
