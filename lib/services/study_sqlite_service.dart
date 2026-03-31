import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/study_task.dart';

class StudySqliteService {
  static const _dbName = 'smartlife.db';
  static const _table = 'study_tasks';
  static const _version = 1;

  Database? _db;
  bool _initFailed = false;

  bool get _isSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  Future<void> init() async {
    if (_db != null || _initFailed || !_isSupported) return;
    try {
      final dbPath = await getDatabasesPath();
      final fullPath = path.join(dbPath, _dbName);
      _db = await openDatabase(
        fullPath,
        version: _version,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE $_table ('
            'id TEXT PRIMARY KEY, '
            'title TEXT NOT NULL, '
            'subject TEXT NOT NULL, '
            'deadline TEXT NOT NULL, '
            'status TEXT NOT NULL, '
            'estimated_minutes INTEGER NOT NULL, '
            'recurrence TEXT NOT NULL, '
            'reminder_minutes_before INTEGER'
            ')',
          );
        },
      );
    } catch (_) {
      _initFailed = true;
      _db = null;
    }
  }

  Future<List<StudyTask>> fetchAllTasks() async {
    if (!_isSupported || _initFailed) return [];
    await init();
    final db = _db;
    if (db == null) return [];
    final rows = await db.query(_table);
    return rows.map(_fromRow).toList();
  }

  Future<void> upsertTask(StudyTask task) async {
    if (!_isSupported || _initFailed) return;
    await init();
    final db = _db;
    if (db == null) return;
    await db.insert(
      _table,
      _toRow(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertTasks(List<StudyTask> tasks) async {
    if (tasks.isEmpty) return;
    if (!_isSupported || _initFailed) return;
    await init();
    final db = _db;
    if (db == null) return;
    final batch = db.batch();
    for (final task in tasks) {
      batch.insert(
        _table,
        _toRow(task),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteTask(String id) async {
    if (!_isSupported || _initFailed) return;
    await init();
    final db = _db;
    if (db == null) return;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceAll(List<StudyTask> tasks) async {
    if (!_isSupported || _initFailed) return;
    await init();
    final db = _db;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete(_table);
      final batch = txn.batch();
      for (final task in tasks) {
        batch.insert(
          _table,
          _toRow(task),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Map<String, Object?> _toRow(StudyTask task) {
    return {
      'id': task.id,
      'title': task.title,
      'subject': task.subject,
      'deadline': task.deadline.toIso8601String(),
      'status': task.status.name,
      'estimated_minutes': task.estimatedMinutes,
      'recurrence': task.recurrence.name,
      'reminder_minutes_before': task.reminderMinutesBefore,
    };
  }

  StudyTask _fromRow(Map<String, Object?> row) {
    final statusName = row['status'] as String? ?? TaskStatus.todo.name;
    final recurrenceName =
        row['recurrence'] as String? ?? RecurrencePattern.none.name;

    return StudyTask(
      id: row['id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      subject: row['subject'] as String? ?? '',
      deadline:
          DateTime.tryParse(row['deadline'] as String? ?? '') ?? DateTime.now(),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => TaskStatus.todo,
      ),
      estimatedMinutes: (row['estimated_minutes'] as num?)?.toInt() ?? 60,
      recurrence: RecurrencePattern.values.firstWhere(
        (e) => e.name == recurrenceName,
        orElse: () => RecurrencePattern.none,
      ),
      reminderMinutesBefore:
          (row['reminder_minutes_before'] as num?)?.toInt() ?? 30,
    );
  }
}
