# Quick Reference - SmartLife Module Integration

## 📁 Files at a Glance

```
lib/
├── services/
│   └── weather_service.dart          ← Enhanced (now with Hive caching)
├── providers/
│   ├── map_provider.dart             ← NEW
│   ├── environment_provider.dart      ← NEW
│   └── ai_provider.dart              ← NEW
└── screens/
    └── smart_dashboard.dart           ← NEW

docs/
├── MODULE_INTEGRATION_GUIDE.md        ← Comprehensive guide
└── DELIVERY_SUMMARY.md                ← This file
```

---

## ⚡ 5-Minute Setup

### Step 1: Add API Keys
```bash
flutter run \
  --dart-define=OPENWEATHER_API_KEY=your_openweather_key \
  --dart-define=GOOGLE_MAPS_API_KEY=your_maps_key \
  --dart-define=LLM_API_KEY=your_llm_key
```

### Step 2: Initialize in main.dart
```dart
import 'services/weather_service.dart';
import 'providers/map_provider.dart';
import 'providers/environment_provider.dart';
import 'providers/ai_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localStorage = LocalStorageService();
  final weatherService = WeatherService(storage: localStorage);

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => weatherService),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(
          create: (_) => EnvironmentProvider(
            weatherService: weatherService,
            reminderService: LocalReminderService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AIProvider(weatherService: weatherService),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

### Step 3: Add Navigation (optional)
```dart
// In your app drawer or menu
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SmartDashboard()),
  ),
  child: const Text('SmartLife Dashboard'),
),
```

---

## 🔥 Common Usage Patterns

### 1. Show Current Weather
```dart
Consumer<EnvironmentProvider>(
  builder: (_, env, __) => Text(
    '${env.currentWeather?.temperature.toStringAsFixed(1)}°C'
  ),
)
```

### 2. Get Smart Suggestions
```dart
final suggestions = context.read<AIProvider>()
    .getTopSuggestions(count: 3);
```

### 3. Navigate to a Location
```dart
await context.read<MapProvider>().startNavigation(
  LocationSuggestion.defaultLocations[0]
);
```

### 4. Check if Outdoor is Safe
```dart
final isSafe = context.read<EnvironmentProvider>()
    .currentWeather?.isOutdoorSafe ?? false;
```

---

## 🎨 UI Components Ready-to-Use

### Weather Card
```dart
Card(
  child: Text('${env.currentWeather?.temperature}°C'),
)
```

### Suggestion List
```dart
ListView.builder(
  itemCount: aiProvider.suggestions.length,
  itemBuilder: (_, i) {
    final s = aiProvider.suggestions[i];
    return ListTile(
      leading: Text(s.emoji),
      title: Text(s.title),
      subtitle: Text(s.description),
    );
  },
)
```

### Location Markers
```dart
GoogleMap(
  markers: mapProvider.markers,
  polylines: mapProvider.polylines,
)
```

---

## ⚠️ Error Handling

All three modules include intelligent fallback mechanisms:

```dart
try {
  // Uses cached data if API fails
  final weather = await weatherService.fetchToday();
  
  // Returns rule-based suggestions if LLM fails
  await aiProvider.generateSuggestions(...);
  
  // Falls back to Hanoi Water University if GPS disabled
  final position = mapProvider.currentPosition;
} catch (e) {
  print('Error: $e');
  // UI shows fallback state automatically
}
```

---

## 🔧 Configuration

### Change Auto-Refresh Interval
`environment_provider.dart` line 16:
```dart
static const _refreshIntervalMinutes = 30; // Change to your interval
```

### Add More Campus Locations
`map_provider.dart` line 36-82:
```dart
static final defaultLocations = <LocationSuggestion>[
  LocationSuggestion(
    id: 'my_location',
    name: 'My Location',
    latitude: 20.8883,
    longitude: 106.7009,
    type: 'classroom',
  ),
  // Add more...
];
```

### Customize Suggestion Rules
`ai_provider.dart` method `_generateRuleBasedSuggestions()`:
```dart
if (walletBalance < 50000) {
  suggestions.add(SmartSuggestion(
    title: 'Your title',
    description: 'Your description',
    // ...
  ));
}
```

---

## 🧪 Testing

### Test Weather API
```dart
final weather = await weatherService.fetchToday();
print('Temp: ${weather.temperature}°C');
print('AQI: ${weather.aqi} (${weather.aqiDescription})');
```

### Test Navigation
```dart
final map = context.read<MapProvider>();
await map.initializeMap();
await map.startNavigation(LocationSuggestion.defaultLocations[0]);
```

### Test Suggestions
```dart
final ai = context.read<AIProvider>();
await ai.generateSuggestions(
  currentWeather: WeatherSnapshot(...),
  todaysTasks: [],
  walletBalance: 100000,
  nearbyLocations: [],
);
print(ai.suggestions.length); // Should have suggestions
```

---

## 📊 Data Models Quick Reference

### WeatherSnapshot
```dart
weather.temperature         // °C
weather.aqi                 // 1-5
weather.aqiDescription      // "Tốt", "Xấu", etc
weather.isBadAQI            // bool
weather.isOutdoorSafe       // bool
weather.summary             // "Partly cloudy"
weather.humidity            // 0-100 %
weather.windSpeed           // m/s
weather.fromCache           // bool
```

### LocationSuggestion
```dart
location.id                 // Unique ID
location.name               // "Thư viện A"
location.latitude           // 20.8890
location.longitude          // 106.7010
location.type               // "library", "cafeteria"
location.description        // "Chi tiết"
```

### SmartSuggestion
```dart
suggestion.title            // "Gợi ý tiêu đề"
suggestion.description      // "Chi tiết"
suggestion.emoji            // "💡"
suggestion.priority         // 1-10
suggestion.category         // "weather", "study"
suggestion.actionUrl        // "app://..."
```

---

## 🚀 Performance Tips

1. **Weather**: Caches for 3 hours, refreshes every 30 min
2. **Maps**: Loads all markers at init, lazy-load details
3. **AI**: Generates suggestions once on demand
4. **Cache**: Uses Hive (fast), expires old entries
5. **API**: All calls have 10-30 second timeouts

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| Weather not loading | Check API key, internet, permissions |
| Maps showing blank | Check Google Maps API key, rebuild |
| Suggestions all generic | Check LLM API key, verify internet |
| Markers not showing | Verify lat/long in defaultLocations |
| Cache not working | Check Hive initialization |

---

## 📚 Full Docs
See `MODULE_INTEGRATION_GUIDE.md` for complete documentation.

## 💬 Questions?
Review the code comments in each provider and service for detailed explanations.

---

**Status**: ✅ Production Ready  
**Last Updated**: April 2026  
**Tested**: Android, iOS, Web
