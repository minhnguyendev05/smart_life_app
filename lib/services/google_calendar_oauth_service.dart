import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

class GoogleCalendarEvent {
  GoogleCalendarEvent({
    required this.id,
    required this.summary,
    required this.startAt,
  });

  final String id;
  final String summary;
  final DateTime startAt;
}

class GoogleCalendarOAuthService {
  static const _calendarReadonlyScope = 'https://www.googleapis.com/auth/calendar.readonly';
  static const _calendarWriteScope = 'https://www.googleapis.com/auth/calendar.events';
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: AppSecrets.googleWebClientId.isEmpty ? null : AppSecrets.googleWebClientId,
      serverClientId: AppSecrets.googleServerClientId.isEmpty
          ? null
          : AppSecrets.googleServerClientId,
    );
    _initialized = true;
  }

  Future<List<GoogleCalendarEvent>> fetchUpcomingEvents({
    Duration window = const Duration(days: 14),
  }) async {
    await _ensureInitialized();
    final user = await _authenticate(scopeHint: const [_calendarReadonlyScope]);
    if (user == null) {
      return [];
    }

    final headers = await user.authorizationClient.authorizationHeaders(
      const [_calendarReadonlyScope],
      promptIfNecessary: true,
    );
    if (headers == null || !headers.containsKey('Authorization')) {
      return [];
    }

    final now = DateTime.now().toUtc();
    final timeMin = now.toIso8601String();
    final timeMax = now.add(window).toIso8601String();
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events',
      {
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'timeMin': timeMin,
        'timeMax': timeMax,
        'maxResults': '80',
      },
    );

    final response = await http
        .get(
          uri,
          headers: headers,
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return [];
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (body['items'] as List?) ?? const [];

    return items.map((row) {
      final map = row as Map<String, dynamic>;
      final id = map['id'] as String? ?? '';
      final summary = (map['summary'] as String?)?.trim();
      final start = map['start'] as Map<String, dynamic>? ?? const {};
      final dateTimeStr = start['dateTime'] as String?;
      final dateStr = start['date'] as String?;

      final startAt = dateTimeStr != null
          ? DateTime.tryParse(dateTimeStr) ?? DateTime.now()
          : DateTime.tryParse(dateStr ?? '') ?? DateTime.now();

      return GoogleCalendarEvent(
        id: id,
        summary: summary == null || summary.isEmpty ? 'Google Calendar Event' : summary,
        startAt: startAt,
      );
    }).where((e) => e.id.isNotEmpty).toList();
  }

  Future<bool> createEventFromTask({
    required String title,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
    String? appTaskId,
  }) async {
    await _ensureInitialized();
    final user = await _authenticate(scopeHint: const [_calendarWriteScope]);
    if (user == null) {
      return false;
    }

    final headers = await user.authorizationClient.authorizationHeaders(
      const [_calendarWriteScope],
      promptIfNecessary: true,
    );
    if (headers == null || !headers.containsKey('Authorization')) {
      return false;
    }

    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events',
    );

    final payload = <String, dynamic>{
      'summary': title,
      'description': description,
      'start': {
        'dateTime': startAt.toUtc().toIso8601String(),
      },
      'end': {
        'dateTime': endAt.toUtc().toIso8601String(),
      },
      if (appTaskId != null)
        'extendedProperties': {
          'private': {
            'smartlifeTaskId': appTaskId,
          },
        },
    };

    final response = await http
        .post(
          uri,
          headers: {
            ...headers,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 12));

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<GoogleSignInAccount?> _authenticate({
    required List<String> scopeHint,
  }) async {
    GoogleSignInAccount? user;
    final light = GoogleSignIn.instance.attemptLightweightAuthentication();
    if (light != null) {
      user = await light;
    }
    user ??= await GoogleSignIn.instance.authenticate(scopeHint: scopeHint);
    return user;
  }
}
