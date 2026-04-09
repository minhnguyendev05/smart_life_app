import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'google_sign_in_bootstrap.dart';

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

  Future<void> _ensureInitialized() async {
    await GoogleSignInBootstrap.ensureInitialized();
  }

  Future<List<GoogleCalendarEvent>> fetchUpcomingEvents({
    Duration window = const Duration(days: 14),
  }) async {
    await _ensureInitialized();
    final headers = await _buildAuthHeaders(
      scopes: const [_calendarReadonlyScope],
      deniedMessage:
          'Chưa cấp quyền Google Calendar. Hãy đăng nhập lại và cho phép truy cập lịch.',
    );
    if (headers == null) {
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
      throw StateError(
        'Google Calendar API lỗi: ${_extractGoogleApiError(response)}',
      );
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
    final headers = await _buildAuthHeaders(
      scopes: const [_calendarWriteScope],
      deniedMessage:
          'Chưa cấp quyền ghi Google Calendar. Hãy đăng nhập lại và cho phép truy cập lịch.',
    );
    if (headers == null) {
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Google Calendar API lỗi: ${_extractGoogleApiError(response)}',
      );
    }

    return true;
  }

  Future<Map<String, String>?> _buildAuthHeaders({
    required List<String> scopes,
    required String deniedMessage,
  }) async {
    if (kIsWeb) {
      final headers =
          await GoogleSignIn.instance.authorizationClient.authorizationHeaders(
        scopes,
        promptIfNecessary: true,
      );
      if (headers == null || !headers.containsKey('Authorization')) {
        throw StateError(deniedMessage);
      }
      return headers;
    }

    final user = await _authenticate(scopeHint: scopes);
    if (user == null) {
      return null;
    }

    Map<String, String>? headers =
        await user.authorizationClient.authorizationHeaders(
      scopes,
      promptIfNecessary: true,
    );

    if (headers == null || !headers.containsKey('Authorization')) {
      await _resetGoogleSession();
      final refreshedUser = await _authenticate(scopeHint: scopes);
      if (refreshedUser == null) {
        return null;
      }
      headers = await refreshedUser.authorizationClient.authorizationHeaders(
        scopes,
        promptIfNecessary: true,
      );
    }

    if (headers == null || !headers.containsKey('Authorization')) {
      throw StateError(deniedMessage);
    }

    return headers;
  }

  String _extractGoogleApiError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final message = (error['message'] as String?)?.trim();
        final status = (error['status'] as String?)?.trim();
        if (message != null && message.isNotEmpty) {
          if (status != null && status.isNotEmpty) {
            return '$status - $message';
          }
          return message;
        }
      }
    } catch (_) {}
    return 'HTTP ${response.statusCode}';
  }

  Future<GoogleSignInAccount?> _authenticate({
    required List<String> scopeHint,
  }) async {
    GoogleSignInAccount? user;
    try {
      user = await GoogleSignIn.instance.authenticate(scopeHint: scopeHint);
    } on GoogleSignInException catch (e) {
      final isCanceled = e.code == GoogleSignInExceptionCode.canceled;
      final isReauth = e.toString().toLowerCase().contains('reauth');
      if (isCanceled && isReauth) {
        await _resetGoogleSession();
        try {
          user =
              await GoogleSignIn.instance.authenticate(scopeHint: scopeHint);
        } on GoogleSignInException catch (retryError) {
          if (retryError.code == GoogleSignInExceptionCode.canceled) {
            return null;
          }
          rethrow;
        }
      } else if (isCanceled) {
        return null;
      } else {
        rethrow;
      }
    }
    return user;
  }

  Future<void> _resetGoogleSession() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }
}
