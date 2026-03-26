import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_app/models/study_task.dart';

void main() {
  test('StudyTask toMap/fromMap roundtrip', () {
    final task = StudyTask(
      id: 'm1',
      title: 'Model test',
      subject: 'QA',
      deadline: DateTime(2026, 3, 26, 10, 30),
      status: TaskStatus.doing,
      estimatedMinutes: 45,
      recurrence: RecurrencePattern.weekly,
    );

    final map = task.toMap();
    final restored = StudyTask.fromMap(map);

    expect(restored.id, task.id);
    expect(restored.title, task.title);
    expect(restored.subject, task.subject);
    expect(restored.status, task.status);
    expect(restored.estimatedMinutes, task.estimatedMinutes);
    expect(restored.recurrence, task.recurrence);
    expect(restored.deadline, task.deadline);
  });
}
