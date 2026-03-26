import 'dart:async';

import 'package:flutter/material.dart';

import '../models/study_task.dart';
import '../services/local_storage_service.dart';

class StudyProvider extends ChangeNotifier {
  static const _storageKey = 'study_tasks';

  LocalStorageService? _storage;
  final List<StudyTask> _tasks = [];
  bool _loaded = false;
  Timer? _sessionTicker;
  String? _activeSessionTaskId;
  int _sessionTotalSeconds = 0;
  int _sessionRemainingSeconds = 0;
  bool _sessionPaused = false;

  List<StudyTask> get tasks {
    final sorted = List<StudyTask>.from(_tasks)
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    return List.unmodifiable(sorted);
  }

  String? get activeSessionTaskId => _activeSessionTaskId;
  int get sessionTotalSeconds => _sessionTotalSeconds;
  int get sessionRemainingSeconds => _sessionRemainingSeconds;
  bool get hasActiveSession => _activeSessionTaskId != null;
  bool get sessionPaused => _sessionPaused;
  bool get sessionRunning => hasActiveSession && !_sessionPaused;
  double get sessionProgress {
    if (_sessionTotalSeconds <= 0) return 0;
    final done = _sessionTotalSeconds - _sessionRemainingSeconds;
    return (done / _sessionTotalSeconds).clamp(0, 1);
  }

  StudyTask? get activeSessionTask {
    final id = _activeSessionTaskId;
    if (id == null) return null;
    for (final task in _tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  Future<void> attachStorage(LocalStorageService storage) async {
    _storage = storage;
    if (!_loaded) {
      await load();
    }
  }

  Future<void> load() async {
    if (_storage == null) return;
    final raw = await _storage!.readList(_storageKey);
    _tasks
      ..clear()
      ..addAll(raw.map(StudyTask.fromMap));

    _loaded = true;
    notifyListeners();
  }

  Future<void> addTask(StudyTask task, {int repeatCount = 4}) async {
    final generated = _expandRecurring(task, repeatCount: repeatCount);
    _tasks.addAll(generated);
    await _persist();
    notifyListeners();
  }

  Future<int> importExternalTasks(List<StudyTask> externalTasks) async {
    var imported = 0;
    for (final task in externalTasks) {
      final index = _tasks.indexWhere((e) => e.id == task.id);
      if (index >= 0) {
        _tasks[index] = task;
      } else {
        _tasks.add(task);
        imported += 1;
      }
    }
    if (externalTasks.isNotEmpty) {
      await _persist();
      notifyListeners();
    }
    return imported;
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    final index = _tasks.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _tasks[index] = _tasks[index].copyWith(status: status);
    await _persist();
    notifyListeners();
  }

  Future<void> removeTask(String id) async {
    _tasks.removeWhere((e) => e.id == id);
    if (_activeSessionTaskId == id) {
      stopTimeBlockSession();
    }
    await _persist();
    notifyListeners();
  }

  Future<void> startTimeBlockSession(
    String taskId, {
    int? durationMinutes,
  }) async {
    final index = _tasks.indexWhere((e) => e.id == taskId);
    if (index < 0) return;

    final task = _tasks[index];
    final minutes = (durationMinutes ?? task.estimatedMinutes).clamp(1, 240);
    _sessionTicker?.cancel();

    _activeSessionTaskId = taskId;
    _sessionTotalSeconds = minutes * 60;
    _sessionRemainingSeconds = _sessionTotalSeconds;
    _sessionPaused = false;

    if (task.status != TaskStatus.done) {
      _tasks[index] = task.copyWith(status: TaskStatus.doing);
      await _persist();
    }

    _sessionTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionPaused) {
        return;
      }

      _sessionRemainingSeconds -= 1;
      if (_sessionRemainingSeconds <= 0) {
        timer.cancel();
        _sessionRemainingSeconds = 0;
        unawaited(_completeSession());
      }
      notifyListeners();
    });

    notifyListeners();
  }

  void pauseTimeBlockSession() {
    if (!hasActiveSession || _sessionPaused) return;
    _sessionPaused = true;
    notifyListeners();
  }

  void resumeTimeBlockSession() {
    if (!hasActiveSession || !_sessionPaused) return;
    _sessionPaused = false;
    notifyListeners();
  }

  void stopTimeBlockSession() {
    _sessionTicker?.cancel();
    _sessionTicker = null;
    _activeSessionTaskId = null;
    _sessionTotalSeconds = 0;
    _sessionRemainingSeconds = 0;
    _sessionPaused = false;
    notifyListeners();
  }

  Future<void> _completeSession() async {
    final id = _activeSessionTaskId;
    if (id != null) {
      final index = _tasks.indexWhere((e) => e.id == id);
      if (index >= 0) {
        _tasks[index] = _tasks[index].copyWith(status: TaskStatus.done);
        await _persist();
      }
    }
    stopTimeBlockSession();
  }

  int get productivityScore {
    if (_tasks.isEmpty) return 0;
    final done = _tasks.where((e) => e.status == TaskStatus.done).length;
    final overdue = _tasks.where((e) => e.isOverdue).length;
    final completionRatio = (done / _tasks.length) * 100;
    final penalty = overdue * 8;
    final score = (completionRatio - penalty).clamp(0, 100);
    return score.round();
  }

  int get todayStudyMinutes {
    final now = DateTime.now();
    return _tasks
        .where((e) =>
            e.status == TaskStatus.done &&
            e.deadline.year == now.year &&
            e.deadline.month == now.month &&
            e.deadline.day == now.day)
        .fold<int>(0, (sum, item) => sum + item.estimatedMinutes);
  }

  int weeklyCompletedCount({DateTime? from}) {
    final pivot = from ?? DateTime.now();
    final weekStart = pivot.subtract(Duration(days: pivot.weekday - 1));
    return _tasks.where((e) {
      return e.status == TaskStatus.done &&
          !e.deadline.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day));
    }).length;
  }

  int weeklyTotalCount({DateTime? from}) {
    final pivot = from ?? DateTime.now();
    final weekStart = pivot.subtract(Duration(days: pivot.weekday - 1));
    return _tasks.where((e) {
      return !e.deadline.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day));
    }).length;
  }

  Future<void> _persist() async {
    if (_storage == null) return;
    final mapped = _tasks.map((e) => e.toMap()).toList();
    await _storage!.saveList(_storageKey, mapped);
  }

  List<StudyTask> _expandRecurring(StudyTask task, {required int repeatCount}) {
    if (task.recurrence == RecurrencePattern.none) {
      return [task];
    }

    final copies = <StudyTask>[task];
    for (var i = 1; i < repeatCount; i++) {
      final nextDeadline = task.recurrence == RecurrencePattern.daily
          ? task.deadline.add(Duration(days: i))
          : task.deadline.add(Duration(days: 7 * i));
      copies.add(
        task.copyWith(
          id: '${task.id}-$i',
          deadline: nextDeadline,
        ),
      );
    }
    return copies;
  }

  @override
  void dispose() {
    _sessionTicker?.cancel();
    super.dispose();
  }
}
