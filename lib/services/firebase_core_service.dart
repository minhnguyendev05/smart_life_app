import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseCoreService {
  static bool _ready = false;
  static String? _lastError;

  static bool get isReady => _ready;
  static String? get lastError => _lastError;

  static Future<void> ensureInitialized() async {
    if (_ready) {
      return;
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _ready = true;
      _lastError = null;
    } catch (e) {
      _ready = false;
      _lastError = e.toString();
    }
  }
}
