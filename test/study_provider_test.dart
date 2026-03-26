import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_app/models/study_task.dart';
import 'package:smart_life_app/providers/study_provider.dart';

void main() {
  test('StudyProvider expands recurring tasks', () async {
    final provider = StudyProvider();

    await provider.addTask(
      StudyTask(
        id: 'r1',
        title: 'On tap',
        subject: 'Mobile',
        deadline: DateTime.now().add(const Duration(hours: 2)),
        recurrence: RecurrencePattern.daily,
      ),
      repeatCount: 3,
    );

    final recurring = provider.tasks.where((t) => t.id.startsWith('r1')).toList();
    expect(recurring.length, 3);
  });

  test('StudyProvider supports time block session flow', () async {
    final provider = StudyProvider();
    final task = StudyTask(
      id: 'tb1',
      title: 'Session test',
      subject: 'SE',
      deadline: DateTime.now().add(const Duration(hours: 1)),
      estimatedMinutes: 25,
    );

    await provider.addTask(task);
    await provider.startTimeBlockSession(task.id, durationMinutes: 1);

    expect(provider.hasActiveSession, isTrue);
    expect(provider.activeSessionTaskId, task.id);
    expect(provider.sessionRunning, isTrue);

    provider.pauseTimeBlockSession();
    expect(provider.sessionPaused, isTrue);

    provider.resumeTimeBlockSession();
    expect(provider.sessionPaused, isFalse);

    provider.stopTimeBlockSession();
    expect(provider.hasActiveSession, isFalse);
  });
}
