import 'package:url_launcher/url_launcher.dart';

import '../models/study_task.dart';

class GoogleCalendarLinkService {
  Future<bool> openCreateEvent(StudyTask task) async {
    final start = task.deadline;
    final end = task.deadline.add(Duration(minutes: task.estimatedMinutes));

    final startUtc = _toGCalDate(start.toUtc());
    final endUtc = _toGCalDate(end.toUtc());

    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': task.title,
      'details': 'Mon hoc: ${task.subject}',
      'dates': '$startUtc/$endUtc',
    });

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _toGCalDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y$m${d}T$hh$mm${ss}Z';
  }
}
