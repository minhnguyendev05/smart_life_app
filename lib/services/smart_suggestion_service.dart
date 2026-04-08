import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/smart_suggestion.dart';
import '../models/study_task.dart';
import '../providers/environment_provider.dart';
import '../providers/finance_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/study_provider.dart';
import '../services/local_reminder_service.dart';

class SmartSuggestionService {
  SmartSuggestionService({
    required this.studyProvider,
    required this.financeProvider,
    required this.notesProvider,
    required this.environmentProvider,
    required this.reminderService,
  });

  final StudyProvider studyProvider;
  final FinanceProvider financeProvider;
  final NotesProvider notesProvider;
  final EnvironmentProvider environmentProvider;
  final LocalReminderService reminderService;

  List<SmartSuggestion> buildSuggestions() {
    final suggestions = <SmartSuggestion>[];

    final overdueTasks = studyProvider.tasks.where((e) => e.isOverdue).length;
    if (overdueTasks > 0) {
      suggestions.add(
        SmartSuggestion(
          title: 'Hoàn thành deadline gấp',
          description:
              'Bạn có $overdueTasks deadline quá hạn. Ưu tiên Time Blocking cho 2 giờ tới.',
          priority: 10,
        ),
      );
    }

    if (financeProvider.isOverBudget) {
      suggestions.add(
        SmartSuggestion(
          title: 'Cảnh báo vượt ngân sách',
          description:
              'Chi tiêu hôm nay đã qua mức ngân sách. Nên tạm dừng các giao dịch không cần thiết.',
          priority: 9,
        ),
      );
    }

    final currentWeather = environmentProvider.currentWeather;
    if (currentWeather != null) {
      if (currentWeather.isBadAQI) {
        suggestions.add(
          SmartSuggestion(
            title: 'Không khí kém, hạn chế đi lại',
            description:
                'AQI hiện tại ${currentWeather.aqiDescription}. Nên đeo khẩu trang khi ra ngoài và ưu tiên làm việc trong nhà.',
            priority: 10,
          ),
        );
      }

      if (!environmentProvider.isOutdoorSafe()) {
        suggestions.add(
          SmartSuggestion(
            title: 'Điều kiện ngoài trời không tốt',
            description:
                'Thời tiết hiện tại có thể chưa an toàn cho hoạt động ngoài trời. Hãy chọn phương án ở nhà hoặc vào phòng học trong nhà.',
            priority: 9,
          ),
        );
      }
    }

    final todoTasks = studyProvider.tasks
        .where((e) => e.status != TaskStatus.done)
        .length;
    if (todoTasks > 0) {
      suggestions.add(
        SmartSuggestion(
          title: 'Chia nhỏ kế hoạch học tập',
          description:
              'Còn $todoTasks việc đang chờ. Hãy chia thành từng block 25 phút để tăng focus.',
          priority: 7,
        ),
      );
    }

    if (notesProvider.notes.isEmpty) {
      suggestions.add(
        SmartSuggestion(
          title: 'Khởi tạo hệ thống ghi chú',
          description:
              'Bạn chưa có ghi chú nào. Tạo nhanh 1 note tổng hợp bài học hôm nay.',
          priority: 5,
        ),
      );
    }

    suggestions.sort((a, b) => b.priority.compareTo(a.priority));
    return suggestions;
  }

  Future<void> sendSmartAlerts() async {
    final currentWeather = environmentProvider.currentWeather;
    if (currentWeather == null) return;

    final position = await _resolveCurrentPosition();
    final onCampus = position != null && _isWithinThuyLoiCampus(position);

    if (currentWeather.isBadAQI || !environmentProvider.isOutdoorSafe()) {
      final title = onCampus
          ? 'Cảnh báo AQI trong khuôn viên Thủy Lợi'
          : 'Cảnh báo điều kiện môi trường';
      final body = currentWeather.isBadAQI
          ? 'AQI ${currentWeather.aqiDescription} hiện tại. Nên đeo khẩu trang khi ra ngoài.'
          : 'Thời tiết hiện tại không thích hợp cho hoạt động ngoài trời. Hãy cân nhắc ở trong nhà.';

      final scheduledAt = DateTime.now().add(const Duration(seconds: 10));
      await reminderService.scheduleDeadlineReminder(
        id: 910,
        scheduledAt: scheduledAt,
        title: title,
        body: body,
      );
    }
  }

  Future<Position?> _resolveCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  bool _isWithinThuyLoiCampus(Position position) {
    const campusLatitude = 21.007;
    const campusLongitude = 105.825;
    const campusRadiusMeters = 1500.0;

    final latDistance = _metersBetween(
      position.latitude,
      position.longitude,
      campusLatitude,
      position.longitude,
    );
    final lngDistance = _metersBetween(
      campusLatitude,
      position.longitude,
      campusLatitude,
      campusLongitude,
    );

    final distance = math.sqrt(
      latDistance * latDistance + lngDistance * lngDistance,
    );
    return distance <= campusRadiusMeters;
  }

  double _metersBetween(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = _radians(lat2 - lat1);
    final dLng = _radians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(lat1)) *
            math.cos(_radians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _radians(double degree) => degree * (math.pi / 180);
}
