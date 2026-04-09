import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/finance_transaction.dart';
import '../models/study_task.dart';
import '../services/local_storage_service.dart';
import '../services/local_reminder_service.dart';
import 'finance_provider.dart';
import 'study_provider.dart';

class NotificationProvider extends ChangeNotifier {
  static const _behaviorModelKey = 'behavior_model_v1';
  static const _storageVersion = 'v2';

  StudyProvider? _study;
  FinanceProvider? _finance;
  LocalStorageService? _storage;
  LocalReminderService? _reminders;
  bool _modelLoaded = false;
  String _userScope = 'guest';

  final Map<int, double> _studyHourWeights = <int, double>{};
  final Map<String, double> _spendingCategoryWeights = <String, double>{};
  final Map<String, double> _categoryFeedbackWeights = <String, double>{};
  final Map<int, double> _hourFeedbackWeights = <int, double>{};
  final Map<String, double> _notificationFeedback = <String, double>{};
  DateTime? _lastModelTrainingAt;
  int _trainingEpoch = 0;

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications {
    final sorted = List<AppNotification>.from(_notifications)
      ..sort((a, b) {
        final scoreB = relevanceScoreOf(b.id);
        final scoreA = relevanceScoreOf(a.id);
        final delta = scoreB.compareTo(scoreA);
        if (delta != 0) {
          return delta;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    return List.unmodifiable(sorted);
  }

  int get unreadCount => _notifications.where((e) => !e.read).length;

  double relevanceScoreOf(String notificationId) {
    final found = _notifications.where((n) => n.id == notificationId);
    if (found.isEmpty) return 0;
    final n = found.first;

    final categoryKey = n.category.name;
    final categoryWeight = _categoryFeedbackWeights[categoryKey] ?? 0;
    final hourWeight = _hourFeedbackWeights[n.createdAt.hour] ?? 0;
    final direct = _notificationFeedback[n.id] ?? 0;
    final recencyHours = DateTime.now()
        .difference(n.createdAt)
        .inHours
        .clamp(0, 72);
    final recencyBoost = 1 - (recencyHours / 72);

    return categoryWeight * 0.45 +
        hourWeight * 0.25 +
        direct * 0.2 +
        recencyBoost * 0.1;
  }

  Future<void> attachStorage(LocalStorageService storage) async {
    _storage = storage;
    if (!_modelLoaded) {
      await _loadBehaviorModel();
    }
  }

  void bindUser(String userId) {
    final normalized = userId.trim().isEmpty ? 'guest' : userId.trim();
    if (_userScope == normalized) {
      return;
    }
    _userScope = normalized;
    _modelLoaded = false;
    _studyHourWeights.clear();
    _spendingCategoryWeights.clear();
    _categoryFeedbackWeights.clear();
    _hourFeedbackWeights.clear();
    _notificationFeedback.clear();
    _lastModelTrainingAt = null;
    _trainingEpoch = 0;
    if (_storage != null) {
      unawaited(_loadBehaviorModel());
    }
  }

  String _scopedBehaviorModelKey() {
    return 'u:$_userScope:$_behaviorModelKey:$_storageVersion';
  }

  void attachReminderService(LocalReminderService reminders) {
    _reminders = reminders;
    unawaited(_reminders!.ensureInitialized());
  }

  void bind(StudyProvider study, FinanceProvider finance) {
    _study = study;
    _finance = finance;
    unawaited(_trainBehaviorModel());
    _rebuildNotifications();
    unawaited(_scheduleSystemReminders());
  }

  void markAllRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(read: true);
    }
    notifyListeners();
  }

  Future<void> rateNotification({
    required String id,
    required bool useful,
  }) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index < 0) return;

    final target = _notifications[index];
    final signal = useful ? 1.0 : -1.0;
    final categoryKey = target.category.name;

    _categoryFeedbackWeights[categoryKey] =
        (_categoryFeedbackWeights[categoryKey] ?? 0) * 0.8 + signal * 0.2;
    _hourFeedbackWeights[target.createdAt.hour] =
        (_hourFeedbackWeights[target.createdAt.hour] ?? 0) * 0.8 + signal * 0.2;
    _notificationFeedback[target.id] =
        (_notificationFeedback[target.id] ?? 0) * 0.6 + signal * 0.4;

    _notifications[index] = target.copyWith(read: true);
    await _persistBehaviorModel();
    notifyListeners();
  }

  void addSystemNotice(String title, String body) {
    _notifications.add(
      AppNotification(
        id: 'sys-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        body: body,
        category: NotificationCategory.system,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void addWeatherNotice({required String title, required String body}) {
    final key =
        '${title.toLowerCase()}-${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    if (_notifications.any((n) => n.id == key)) {
      return;
    }
    _notifications.add(
      AppNotification(
        id: key,
        title: title,
        body: body,
        category: NotificationCategory.weather,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void _rebuildNotifications() {
    if (_study == null || _finance == null) return;

    final next = <AppNotification>[];
    final now = DateTime.now();

    final overdue = _study!.tasks.where((e) => e.isOverdue).toList();
    if (overdue.isNotEmpty) {
      next.add(
        AppNotification(
          id: 'deadline-overdue',
          title: 'Nhắc deadline',
          body:
              'Bạn có ${overdue.length} deadline đã quá hạn. Ưu tiên xử lý ngay.',
          category: NotificationCategory.deadline,
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
      );
    }

    final soon = _study!.tasks
        .where((e) => !e.isOverdue)
        .where((e) => e.deadline.difference(now).inHours <= 24)
        .length;
    if (soon > 0) {
      next.add(
        AppNotification(
          id: 'deadline-soon',
          title: 'Deadline sắp đến',
          body: 'Có $soon deadline trong vòng 24h tới.',
          category: NotificationCategory.study,
          createdAt: now.subtract(const Duration(minutes: 12)),
        ),
      );
    }

    if (_finance!.isOverBudget) {
      next.add(
        AppNotification(
          id: 'finance-overbudget',
          title: 'Cảnh báo chi tiêu',
          body:
              'Bạn đã vượt ngân sách tháng. Cần điều chỉnh kế hoạch chi tiêu.',
          category: NotificationCategory.finance,
          createdAt: now.subtract(const Duration(minutes: 20)),
        ),
      );
    }

    final focusHour = _detectFocusHour();
    if (focusHour != null) {
      next.add(
        AppNotification(
          id: 'habit-focus-hour',
          title: 'Khung giờ học hiệu quả',
          body:
              'Mô hình hành vi cho thấy bạn học hiệu quả nhất vào ${focusHour.toString().padLeft(2, '0')}:00. Hãy đặt task khó vào khung này.',
          category: NotificationCategory.study,
          createdAt: now.subtract(const Duration(minutes: 16)),
        ),
      );
    }

    final spendTrend = _detectSpendingTrend();
    if (spendTrend != null) {
      next.add(
        AppNotification(
          id: 'habit-spending-trend',
          title: 'Xu hướng chi tiêu',
          body: spendTrend,
          category: NotificationCategory.finance,
          createdAt: now.subtract(const Duration(minutes: 22)),
        ),
      );
    }

    if (next.isEmpty) {
      next.add(
        AppNotification(
          id: 'system-healthy',
          title: 'Trạng thái tốt',
          body: 'Hôm nay bạn đang quản lý học tập và tài chính khá ổn định.',
          category: NotificationCategory.system,
          createdAt: now,
        ),
      );
    }

    final existingRead = <String, bool>{
      for (final item in _notifications) item.id: item.read,
    };

    _notifications
      ..clear()
      ..addAll(
        next.map(
          (item) => item.copyWith(read: existingRead[item.id] ?? item.read),
        ),
      );
    unawaited(_scheduleSystemReminders());
    notifyListeners();
  }

  int? _detectFocusHour() {
    if (_studyHourWeights.isNotEmpty) {
      final sorted = _studyHourWeights.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.first.key;
    }

    if (_study == null) return null;
    final now = DateTime.now();
    final threshold = now.subtract(const Duration(days: 30));
    final done = _study!.tasks
        .where((e) => e.status == TaskStatus.done)
        .where((e) => e.deadline.isAfter(threshold))
        .toList();
    if (done.length < 3) return null;

    final buckets = <int, int>{};
    for (final t in done) {
      buckets[t.deadline.hour] = (buckets[t.deadline.hour] ?? 0) + 1;
    }
    final sorted = buckets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String? _detectSpendingTrend() {
    if (_finance == null) return null;
    final now = DateTime.now();
    final currentWindowStart = now.subtract(const Duration(days: 7));
    final previousWindowStart = now.subtract(const Duration(days: 14));

    final recent = _finance!.transactions.where((t) {
      return t.type == TransactionType.expense &&
          t.createdAt.isAfter(currentWindowStart);
    });
    final previous = _finance!.transactions.where((t) {
      return t.type == TransactionType.expense &&
          t.createdAt.isAfter(previousWindowStart) &&
          t.createdAt.isBefore(currentWindowStart);
    });

    final recentByCategory = <String, double>{};
    for (final tx in recent) {
      recentByCategory[tx.category] =
          (recentByCategory[tx.category] ?? 0) + tx.amount;
    }
    if (recentByCategory.isEmpty) return null;

    final previousByCategory = <String, double>{};
    for (final tx in previous) {
      previousByCategory[tx.category] =
          (previousByCategory[tx.category] ?? 0) + tx.amount;
    }

    String? topCategory;
    var maxIncrease = 0.0;
    for (final entry in recentByCategory.entries) {
      final before = previousByCategory[entry.key] ?? 0;
      final increase = entry.value - before;
      if (increase > maxIncrease) {
        maxIncrease = increase;
        topCategory = entry.key;
      }
    }

    if (topCategory == null || maxIncrease <= 0) {
      return null;
    }

    return '7 ngày qua, chi tiêu nhóm $topCategory tăng ${maxIncrease.toStringAsFixed(0)} VND so với 7 ngày trước.';
  }

  Future<void> _trainBehaviorModel() async {
    if (_study == null || _finance == null) return;

    final now = DateTime.now();
    if (_lastModelTrainingAt != null &&
        now.difference(_lastModelTrainingAt!).inHours < 8) {
      return;
    }

    final recentDone = _study!.tasks.where((t) {
      return t.status == TaskStatus.done &&
          t.deadline.isAfter(now.subtract(const Duration(days: 120)));
    });
    final freshHourWeights = <int, double>{};
    for (final task in recentDone) {
      freshHourWeights[task.deadline.hour] =
          (freshHourWeights[task.deadline.hour] ?? 0) + 1;
    }

    final recentExpenses = _finance!.transactions.where((t) {
      return t.type == TransactionType.expense &&
          t.createdAt.isAfter(now.subtract(const Duration(days: 120)));
    });
    final freshCategoryWeights = <String, double>{};
    for (final tx in recentExpenses) {
      freshCategoryWeights[tx.category] =
          (freshCategoryWeights[tx.category] ?? 0) + tx.amount;
    }

    const alpha = 0.35;
    for (final entry in freshHourWeights.entries) {
      final prev = _studyHourWeights[entry.key] ?? 0;
      _studyHourWeights[entry.key] = prev * (1 - alpha) + entry.value * alpha;
    }
    for (final entry in freshCategoryWeights.entries) {
      final prev = _spendingCategoryWeights[entry.key] ?? 0;
      _spendingCategoryWeights[entry.key] =
          prev * (1 - alpha) + entry.value * alpha;
    }

    _lastModelTrainingAt = now;
    _trainingEpoch += 1;
    await _persistBehaviorModel();
  }

  Future<void> _loadBehaviorModel() async {
    if (_storage == null) return;
    final raw = await _storage!.readList(_scopedBehaviorModelKey());
    if (raw.isEmpty) {
      _modelLoaded = true;
      return;
    }

    final row = raw.first;
    final hourRaw = Map<dynamic, dynamic>.from(
      row['studyHourWeights'] as Map? ?? {},
    );
    final categoryRaw = Map<dynamic, dynamic>.from(
      row['spendingCategoryWeights'] as Map? ?? {},
    );
    final categoryFeedbackRaw = Map<dynamic, dynamic>.from(
      row['categoryFeedbackWeights'] as Map? ?? {},
    );
    final hourFeedbackRaw = Map<dynamic, dynamic>.from(
      row['hourFeedbackWeights'] as Map? ?? {},
    );
    final notificationFeedbackRaw = Map<dynamic, dynamic>.from(
      row['notificationFeedback'] as Map? ?? {},
    );

    _studyHourWeights
      ..clear()
      ..addAll(
        hourRaw.map(
          (k, v) => MapEntry(int.tryParse('$k') ?? 0, (v as num).toDouble()),
        ),
      );
    _spendingCategoryWeights
      ..clear()
      ..addAll(
        categoryRaw.map((k, v) => MapEntry('$k', (v as num).toDouble())),
      );
    _categoryFeedbackWeights
      ..clear()
      ..addAll(
        categoryFeedbackRaw.map(
          (k, v) => MapEntry('$k', (v as num).toDouble()),
        ),
      );
    _hourFeedbackWeights
      ..clear()
      ..addAll(
        hourFeedbackRaw.map(
          (k, v) => MapEntry(int.tryParse('$k') ?? 0, (v as num).toDouble()),
        ),
      );
    _notificationFeedback
      ..clear()
      ..addAll(
        notificationFeedbackRaw.map(
          (k, v) => MapEntry('$k', (v as num).toDouble()),
        ),
      );
    _lastModelTrainingAt = DateTime.tryParse(
      row['lastTrainingAt'] as String? ?? '',
    );
    _trainingEpoch = (row['trainingEpoch'] as num?)?.toInt() ?? 0;
    _modelLoaded = true;
  }

  Future<void> _persistBehaviorModel() async {
    if (_storage == null) return;
    await _storage!.saveList(_scopedBehaviorModelKey(), [
      {
        'studyHourWeights': _studyHourWeights.map(
          (key, value) => MapEntry('$key', value),
        ),
        'spendingCategoryWeights': _spendingCategoryWeights,
        'categoryFeedbackWeights': _categoryFeedbackWeights,
        'hourFeedbackWeights': _hourFeedbackWeights.map(
          (k, v) => MapEntry('$k', v),
        ),
        'notificationFeedback': _notificationFeedback,
        'lastTrainingAt': _lastModelTrainingAt?.toIso8601String(),
        'trainingEpoch': _trainingEpoch,
      },
    ]);
  }

  Future<void> _scheduleSystemReminders() async {
    final reminder = _reminders;
    if (reminder == null) {
      return;
    }

    final focusHour = _detectFocusHour() ?? 20;
    await reminder.scheduleDailyReminder(
      id: 1001,
      hour: focusHour,
      minute: 0,
      title: 'SmartLife nhắc học tập',
      body: 'Đến giờ học hiệu quả của bạn. Bắt đầu một session 25 phút nhé.',
    );

    await reminder.scheduleDailyReminder(
      id: 1002,
      hour: 21,
      minute: 30,
      title: 'SmartLife nhắc tài chính',
      body: 'Kiểm tra chi tiêu hôm nay trước khi kết thúc ngày.',
    );
  }
}
