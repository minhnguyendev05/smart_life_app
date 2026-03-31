enum TaskStatus { todo, doing, done }
enum RecurrencePattern { none, daily, weekly }

class StudyTask {
  StudyTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.deadline,
    this.status = TaskStatus.todo,
    this.estimatedMinutes = 60,
    this.recurrence = RecurrencePattern.none,
    this.reminderMinutesBefore = 30,
  });

  final String id;
  final String title;
  final String subject;
  final DateTime deadline;
  final TaskStatus status;
  final int estimatedMinutes;
  final RecurrencePattern recurrence;
  final int? reminderMinutesBefore;

  bool get isOverdue =>
      status != TaskStatus.done && deadline.isBefore(DateTime.now());

  StudyTask copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? deadline,
    TaskStatus? status,
    int? estimatedMinutes,
    RecurrencePattern? recurrence,
    int? reminderMinutesBefore,
  }) {
    return StudyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      recurrence: recurrence ?? this.recurrence,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'deadline': deadline.toIso8601String(),
      'status': status.name,
      'estimatedMinutes': estimatedMinutes,
      'recurrence': recurrence.name,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  factory StudyTask.fromMap(Map<dynamic, dynamic> map) {
    return StudyTask(
      id: map['id'] as String,
      title: map['title'] as String,
      subject: map['subject'] as String,
      deadline: DateTime.parse(map['deadline'] as String),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.todo,
      ),
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 60,
      recurrence: RecurrencePattern.values.firstWhere(
        (e) => e.name == map['recurrence'],
        orElse: () => RecurrencePattern.none,
      ),
      reminderMinutesBefore:
          (map['reminderMinutesBefore'] as num?)?.toInt() ?? 30,
    );
  }
}
