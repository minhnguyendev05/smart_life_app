import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const _boxName = 'smart_life_box';
  Box<dynamic>? _box;

  Future<void> init() async {
    if (_box != null) {
      return;
    }
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> value) async {
    await init();
    await _box!.put(key, value);
  }

  Future<List<Map<dynamic, dynamic>>> readList(String key) async {
    await init();
    final dynamic raw = _box!.get(key, defaultValue: <Map<String, dynamic>>[]);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => Map<dynamic, dynamic>.from(entry))
          .toList();
    }
    return [];
  }

  Future<void> saveBool(String key, bool value) async {
    await init();
    await _box!.put(key, value);
  }

  Future<bool> readBool(String key, {bool defaultValue = false}) async {
    await init();
    return _box!.get(key, defaultValue: defaultValue) as bool;
  }
}
