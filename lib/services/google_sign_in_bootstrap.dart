import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_secrets.dart';

class GoogleSignInBootstrap {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }

    final webClientId = AppSecrets.googleWebClientId.trim();
    final serverClientId = AppSecrets.googleServerClientId.trim();
    final effectiveServerClientId = serverClientId.isNotEmpty
        ? serverClientId
        : (!kIsWeb ? webClientId : '');

    if (!kIsWeb && effectiveServerClientId.isEmpty) {
      throw StateError(
        'Thieu GOOGLE_SERVER_CLIENT_ID (hoac GOOGLE_WEB_CLIENT_ID) cho Android. '
        'Hay cung cap Web OAuth client ID tu Google Cloud va build lai.',
      );
    }

    try {
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb && webClientId.isNotEmpty ? webClientId : null,
        serverClientId: !kIsWeb && effectiveServerClientId.isNotEmpty
            ? effectiveServerClientId
            : null,
      );
    } on AssertionError catch (e) {
      final msg = e.toString();
      if (!msg.contains('init() has already been called')) {
        rethrow;
      }
      // Web hot-restart can keep JS state; treat double init as safe no-op.
    }
    _initialized = true;
  }
}
