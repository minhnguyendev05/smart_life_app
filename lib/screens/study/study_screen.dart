import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/study_task.dart';
import '../../providers/sync_provider.dart';
import '../../providers/study_provider.dart';
import '../../services/google_calendar_oauth_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/metric_card.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _calendarOAuthService = GoogleCalendarOAuthService();

  String _formatCountdown(int seconds) {
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyProvider>();
    final tasks = provider.tasks;
    final filteredTasks = _selectedDay == null
        ? tasks
        : tasks
            .where((e) => isSameDay(e.deadline, _selectedDay))
            .toList();
    final emptyText = _selectedDay == null
        ? 'Không có nhiệm vụ nào. Hãy tạo nhiệm vụ đầu tiên.'
        : 'Không có nhiệm vụ trong ngày đã chọn.';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.insights_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Báo cáo tuần: ${provider.weeklyCompletedCount()}/${provider.weeklyTotalCount()} task hoàn thành',
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Điểm năng suất',
                value: '${provider.productivityScore}/100',
                icon: Icons.trending_up,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Học hôm nay',
                value: '${provider.todayStudyMinutes} phút',
                icon: Icons.timer_outlined,
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TableCalendar<StudyTask>(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2032, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) {
            return tasks.where((e) {
              final d = e.deadline;
              return d.year == day.year && d.month == day.month && d.day == day.day;
            }).toList();
          },
          calendarStyle: const CalendarStyle(markerDecoration: BoxDecoration(color: Colors.teal, shape: BoxShape.circle)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Deadline & Time Blocking',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _showAddTaskSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _importFromGoogleCalendar,
              icon: const Icon(Icons.sync_outlined),
              label: const Text('Import GCal'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: provider.hasActiveSession
              ? Card(
                  key: const ValueKey('active-session'),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phiên học: ${provider.activeSessionTask?.title ?? 'Đang học tập'}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: provider.sessionProgress),
                        const SizedBox(height: 8),
                        Text(
                          'Còn lại: ${_formatCountdown(provider.sessionRemainingSeconds)}',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: provider.sessionPaused
                                  ? provider.resumeTimeBlockSession
                                  : provider.pauseTimeBlockSession,
                              icon: Icon(provider.sessionPaused
                                  ? Icons.play_arrow_outlined
                                  : Icons.pause_outlined),
                              label: Text(provider.sessionPaused ? 'Tiếp tục' : 'Tạm dừng'),
                            ),
                            OutlinedButton.icon(
                              onPressed: provider.stopTimeBlockSession,
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('Dừng'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (filteredTasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(emptyText),
            ),
          ),
        ...filteredTasks.map(
          (task) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              tween: Tween(begin: 0.98, end: 1),
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Slidable(
              key: ValueKey(task.id),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) {
                      provider.removeTask(task.id);
                      context.read<SyncProvider>().queueAction(
                            entity: 'study',
                            entityId: task.id,
                            payload: {
                              'operation': 'delete',
                              'taskId': task.id,
                              'deleted': true,
                            },
                          );
                    },
                    icon: Icons.delete_outline,
                    backgroundColor: Colors.redAccent,
                  ),
                ],
              ),
              startActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (_) {
                      final next = task.status == TaskStatus.done
                          ? TaskStatus.todo
                          : TaskStatus.done;
                      provider.updateStatus(task.id, next);
                      context.read<SyncProvider>().queueAction(
                            entity: 'study',
                            entityId: task.id,
                            payload: {
                              'operation': 'statusUpdate',
                              'task': task.copyWith(status: next).toMap(),
                            },
                          );
                    },
                    icon: task.status == TaskStatus.done
                        ? Icons.undo_outlined
                        : Icons.check,
                    backgroundColor: Colors.teal,
                  ),
                ],
              ),
              child: Card(
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Text(
                    '${task.subject} • ${Formatters.dayTime(task.deadline)} • ${task.estimatedMinutes} phút',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showAddTaskSheet(context, existing: task);
                      }
                      if (value == 'calendar') {
                        await _exportTaskToGoogleCalendar(task);
                      }
                      if (value == 'start-session') {
                        await provider.startTimeBlockSession(task.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Chỉnh sửa'),
                      ),
                      const PopupMenuItem(
                        value: 'calendar',
                        child: Text('Đẩy lên Google Calendar'),
                      ),
                      PopupMenuItem(
                        value: 'start-session',
                        child: Text(provider.activeSessionTaskId == task.id
                            ? 'Phiên học đang chạy'
                            : 'Bắt đầu phiên học'),
                      ),
                    ],
                    child: Icon(
                      task.status == TaskStatus.done
                          ? Icons.check_circle
                          : task.isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.schedule,
                      color: task.status == TaskStatus.done
                          ? Colors.teal
                          : task.isOverdue
                              ? Colors.redAccent
                              : null,
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddTaskSheet(
    BuildContext context, {
    StudyTask? existing,
  }) async {
    final isEditing = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final minuteCtrl = TextEditingController(
      text: '${existing?.estimatedMinutes ?? 60}',
    );
    int occurrences = 4;
    RecurrencePattern recurrence = existing?.recurrence ?? RecurrencePattern.none;
    int? reminderMinutes = existing?.reminderMinutesBefore ?? 30;

    DateTime deadline = existing?.deadline ?? DateTime.now().add(const Duration(hours: 2));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Tiêu đề task'),
                ),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Môn học'),
                ),
                TextField(
                  controller: minuteCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Thời gian dự kiến (phút)'),
                ),
                const SizedBox(height: 10),
                if (!isEditing) ...[
                  SegmentedButton<RecurrencePattern>(
                    segments: const [
                      ButtonSegment(value: RecurrencePattern.none, label: Text('1 lần')),
                      ButtonSegment(value: RecurrencePattern.daily, label: Text('Hằng ngày')),
                      ButtonSegment(value: RecurrencePattern.weekly, label: Text('Hằng tuần')),
                    ],
                    selected: {recurrence},
                    onSelectionChanged: (value) {
                      setModalState(() {
                        recurrence = value.first;
                      });
                    },
                  ),
                  if (recurrence != RecurrencePattern.none)
                    Row(
                      children: [
                        const Text('Số lần lặp:'),
                        const SizedBox(width: 10),
                        DropdownButton<int>(
                          value: occurrences,
                          items: [2, 3, 4].map((e) {
                            return DropdownMenuItem(value: e, child: Text('$e'));
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setModalState(() => occurrences = v);
                            }
                          },
                        ),
                      ],
                    ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Nhắc trước:'),
                    const SizedBox(width: 12),
                    DropdownButton<int?>(
                      value: reminderMinutes,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Không nhắc')),
                        DropdownMenuItem(value: 10, child: Text('10 phút')),
                        DropdownMenuItem(value: 30, child: Text('30 phút')),
                        DropdownMenuItem(value: 60, child: Text('60 phút')),
                        DropdownMenuItem(value: 120, child: Text('120 phút')),
                      ],
                      onChanged: (value) {
                        setModalState(() => reminderMinutes = value);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text('Deadline: ${Formatters.dayTime(deadline)}')),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: deadline,
                        );
                        if (date != null) {
                          setModalState(() {
                            deadline = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              deadline.hour,
                              deadline.minute,
                            );
                          });
                        }
                      },
                      child: const Text('Chọn ngày'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty ||
                          subjectCtrl.text.trim().isEmpty) {
                        return;
                      }
                      if (isEditing) {
                        final updated = existing!.copyWith(
                          title: titleCtrl.text.trim(),
                          subject: subjectCtrl.text.trim(),
                          deadline: deadline,
                          estimatedMinutes:
                              int.tryParse(minuteCtrl.text.trim()) ?? 60,
                          reminderMinutesBefore: reminderMinutes,
                        );
                        context.read<StudyProvider>().updateTask(updated);
                        context.read<SyncProvider>().queueAction(
                          entity: 'study',
                          entityId: updated.id,
                          payload: {
                            'operation': 'upsert',
                            'repeatCount': 1,
                            'task': updated.toMap(),
                          },
                        );
                      } else {
                        final task = StudyTask(
                          id: 'task-${DateTime.now().microsecondsSinceEpoch}',
                          title: titleCtrl.text.trim(),
                          subject: subjectCtrl.text.trim(),
                          deadline: deadline,
                          recurrence: recurrence,
                          estimatedMinutes:
                              int.tryParse(minuteCtrl.text.trim()) ?? 60,
                          reminderMinutesBefore: reminderMinutes,
                        );
                        context.read<StudyProvider>().addTask(
                          task,
                          repeatCount:
                              recurrence == RecurrencePattern.none ? 1 : occurrences,
                        );
                        context.read<SyncProvider>().queueAction(
                          entity: 'study',
                          entityId: task.id,
                          payload: {
                            'operation': 'upsert',
                            'repeatCount':
                                recurrence == RecurrencePattern.none ? 1 : occurrences,
                            'task': task.toMap(),
                          },
                        );
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(isEditing ? 'Cập nhật' : 'Lưu task'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _importFromGoogleCalendar() async {
    final studyProvider = context.read<StudyProvider>();
    final syncProvider = context.read<SyncProvider>();
    final events = await _calendarOAuthService.fetchUpcomingEvents();
    if (!mounted) return;

    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có sự kiện Google Calendar để nhập.')),
      );
      return;
    }

    final mapped = events
        .map(
          (e) => StudyTask(
            id: 'gcal-${e.id}',
            title: e.summary,
            subject: 'Google Calendar',
            deadline: e.startAt,
            estimatedMinutes: 60,
          ),
        )
        .toList();

    final imported = await studyProvider.importExternalTasks(mapped);
    if (!mounted) return;
    syncProvider.queueAction(
      entity: 'study',
      entityId: 'google-calendar-import-${DateTime.now().millisecondsSinceEpoch}',
      payload: {
        'operation': 'bulkImport',
        'source': 'google_calendar',
        'importedCount': imported,
        'tasks': mapped.map((e) => e.toMap()).toList(),
      },
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã import $imported sự kiện mới từ Google Calendar.')),
    );
  }

  Future<void> _exportTaskToGoogleCalendar(StudyTask task) async {
    final ok = await _calendarOAuthService.createEventFromTask(
      title: task.title,
      description: 'Môn học: ${task.subject}',
      startAt: task.deadline,
      endAt: task.deadline.add(Duration(minutes: task.estimatedMinutes)),
      appTaskId: task.id,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã push task lên Google Calendar qua OAuth API.'
              : 'Push Calendar thất bại. Kiểm tra đăng nhập Google và scope.',
        ),
      ),
    );
  }
}
