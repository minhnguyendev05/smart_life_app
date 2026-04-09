import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  CalendarFormat _calendarFormat = CalendarFormat.month;
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
        : tasks.where((e) => isSameDay(e.deadline, _selectedDay)).toList();
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
          calendarFormat: _calendarFormat,
          headerStyle: const HeaderStyle(formatButtonShowsNext: false),
          availableCalendarFormats: const {
            CalendarFormat.month: 'Tháng',
            CalendarFormat.twoWeeks: '2 tuần',
            CalendarFormat.week: '1 tuần',
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() => _calendarFormat = format);
            }
          },
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
              return d.year == day.year &&
                  d.month == day.month &&
                  d.day == day.day;
            }).toList();
          },
          calendarStyle: const CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Danh sách nhiệm vụ',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () =>
                  _showAddTaskSheet(context, initialDay: _selectedDay),
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
                        LinearProgressIndicator(
                          value: provider.sessionProgress,
                        ),
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
                              icon: Icon(
                                provider.sessionPaused
                                    ? Icons.play_arrow_outlined
                                    : Icons.pause_outlined,
                              ),
                              label: Text(
                                provider.sessionPaused
                                    ? 'Tiếp tục'
                                    : 'Tạm dừng',
                              ),
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
        ...filteredTasks.map((task) {
          final now = DateTime.now();
          final isDone = task.status == TaskStatus.done;
          final isOverdue = task.isOverdue;
          final isDueSoon =
              !isDone && !isOverdue && task.deadline.difference(now).inHours <= 24;
          final titleColor = isDone
              ? Colors.teal
              : isOverdue
              ? Colors.redAccent
              : isDueSoon
              ? Colors.amber.shade700
              : null;
          final tileColor = isDone
              ? Colors.teal.withOpacity(0.12)
              : isOverdue
              ? Colors.redAccent.withOpacity(0.12)
              : isDueSoon
              ? Colors.amber.withOpacity(0.15)
              : null;
          final iconColor = isDone
              ? Colors.teal
              : isOverdue
              ? Colors.redAccent
              : isDueSoon
              ? Colors.amber.shade700
              : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              tween: Tween(begin: 0.98, end: 1),
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
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
                  color: tileColor,
                  child: ListTile(
                    title: Text(
                      task.title,
                      style: TextStyle(
                        color: titleColor,
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
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
                          child: Text(
                            provider.activeSessionTaskId == task.id
                                ? 'Phiên học đang chạy'
                                : 'Bắt đầu phiên học',
                          ),
                        ),
                      ],
                      child: Icon(
                        isDone
                            ? Icons.check_circle
                            : isOverdue
                            ? Icons.warning_amber_rounded
                            : Icons.schedule,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showAddTaskSheet(
    BuildContext context, {
    StudyTask? existing,
    DateTime? initialDay,
  }) async {
    final isEditing = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final subjectCtrl = TextEditingController(text: existing?.subject ?? '');
    final minuteCtrl = TextEditingController(
      text: '${existing?.estimatedMinutes ?? 60}',
    );
    final subjectOptions = <String>[
      'Học bài',
      'Đi chơi',
      'Shopping',
      'Làm việc',
      'Tập gym',
      'Đọc sách',
      'Gia đình',
      'Nghỉ ngơi',
      'Khác',
    ];
    final existingSubject = subjectCtrl.text.trim();
    if (existingSubject.isNotEmpty &&
        !subjectOptions.contains(existingSubject)) {
      subjectOptions.insert(0, existingSubject);
    }
    final initialSubject = existingSubject.isNotEmpty
        ? existingSubject
        : subjectOptions.first;
    subjectCtrl.text = initialSubject;
    String subjectValue = initialSubject;
    int? reminderMinutes = existing?.reminderMinutesBefore ?? 30;

    final baseTime =
        existing?.deadline ?? DateTime.now().add(const Duration(hours: 2));
    DateTime deadline = baseTime;
    if (!isEditing && initialDay != null) {
      deadline = DateTime(
        initialDay.year,
        initialDay.month,
        initialDay.day,
        baseTime.hour,
        baseTime.minute,
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final viewInsets = MediaQuery.of(ctx).viewInsets;
            final theme = Theme.of(ctx);
            final scheme = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;
            final fieldFill = scheme.surfaceVariant.withOpacity(
              isDark ? 0.35 : 0.7,
            );
            final borderColor = scheme.outlineVariant.withOpacity(
              isDark ? 0.5 : 0.7,
            );

            InputDecoration inputDecoration(String label, IconData icon) {
              return InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                filled: true,
                fillColor: fieldFill,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
              );
            }

            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withOpacity(0.08),
                      scheme.surface,
                      scheme.surface,
                    ],
                  ),
                ),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 120),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    viewInsets.bottom + 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: scheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit_note_outlined,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'Cập nhật công việc'
                                        : 'Tạo công việc mới',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sắp xếp lịch học gọn gàng hơn',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Đóng',
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: titleCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: inputDecoration(
                            'Tiêu đề task',
                            Icons.title_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: subjectValue,
                          decoration: inputDecoration(
                            'Danh mục',
                            Icons.category_outlined,
                          ),
                          isExpanded: true,
                          items: subjectOptions.map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setModalState(() {
                              subjectValue = value;
                              subjectCtrl.text = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: minuteCtrl,
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration(
                            'Thời gian dự kiến (phút)',
                            Icons.timer_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int?>(
                          value: reminderMinutes,
                          decoration: inputDecoration(
                            'Nhắc trước',
                            Icons.notifications_none_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Không nhắc'),
                            ),
                            DropdownMenuItem(value: 10, child: Text('10 phút')),
                            DropdownMenuItem(value: 30, child: Text('30 phút')),
                            DropdownMenuItem(value: 60, child: Text('60 phút')),
                            DropdownMenuItem(value: 120, child: Text('120 phút')),
                          ],
                          onChanged: (value) {
                            setModalState(() => reminderMinutes = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: fieldFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event_outlined,
                                color: scheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Deadline: ${Formatters.dayTime(deadline)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: ctx,
                                  firstDate: DateTime.now().subtract(
                                    const Duration(days: 7),
                                  ),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
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
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: const Text('Chọn ngày'),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                final time = await showTimePicker(
                                  context: ctx,
                                  initialTime: TimeOfDay.fromDateTime(deadline),
                                );
                                if (time != null) {
                                  setModalState(() {
                                    deadline = DateTime(
                                      deadline.year,
                                      deadline.month,
                                      deadline.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              },
                              icon: const Icon(Icons.access_time_outlined),
                              label: const Text('Chọn giờ'),
                            ),
                            if (!isEditing && initialDay != null)
                              OutlinedButton.icon(
                                onPressed: () {
                                  setModalState(() {
                                    deadline = DateTime(
                                      initialDay.year,
                                      initialDay.month,
                                      initialDay.day,
                                      deadline.hour,
                                      deadline.minute,
                                    );
                                  });
                                },
                                icon: const Icon(Icons.today_outlined),
                                label: const Text('Dùng ngày đang chọn'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty ||
                                  subjectCtrl.text.trim().isEmpty) {
                                return;
                              }
                              if (isEditing) {
                                final updated = existing.copyWith(
                                  title: titleCtrl.text.trim(),
                                  subject: subjectCtrl.text.trim(),
                                  deadline: deadline,
                                  estimatedMinutes:
                                      int.tryParse(minuteCtrl.text.trim()) ??
                                          60,
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
                                  id:
                                      'task-${DateTime.now().microsecondsSinceEpoch}',
                                  title: titleCtrl.text.trim(),
                                  subject: subjectCtrl.text.trim(),
                                  deadline: deadline,
                                  recurrence: RecurrencePattern.none,
                                  estimatedMinutes:
                                      int.tryParse(minuteCtrl.text.trim()) ??
                                          60,
                                  reminderMinutesBefore: reminderMinutes,
                                );
                                context.read<StudyProvider>().addTask(
                                  task,
                                  repeatCount: 1,
                                );
                                context.read<SyncProvider>().queueAction(
                                  entity: 'study',
                                  entityId: task.id,
                                  payload: {
                                    'operation': 'upsert',
                                    'repeatCount': 1,
                                    'task': task.toMap(),
                                  },
                                );
                              }
                              Navigator.pop(ctx);
                            },
                            icon: Icon(
                              isEditing
                                  ? Icons.save_outlined
                                  : Icons.check_circle_outline,
                            ),
                            label: Text(isEditing ? 'Cập nhật' : 'Lưu task'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _importFromGoogleCalendar() async {
    final studyProvider = context.read<StudyProvider>();
    final syncProvider = context.read<SyncProvider>();
    List<GoogleCalendarEvent> events;
    try {
      events = await _calendarOAuthService.fetchUpcomingEvents();
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    } on GoogleSignInException catch (e, stack) {
      debugPrint(
        'Google Sign-In loi (GCal import): ${e.code} ${e.description ?? ''}',
      );
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In lỗi: ${e.code}.')),
      );
      return;
    } catch (e, stack) {
      debugPrint('Import Google Calendar loi: $e');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import Google Calendar thất bại: $e')),
      );
      return;
    }
    if (!mounted) return;

    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có sự kiện Google Calendar để nhập.'),
        ),
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
    for (final task in mapped) {
      syncProvider.queueAction(
        entity: 'study',
        entityId: task.id,
        payload: {
          'operation': 'upsert',
          'source': 'google_calendar',
          'task': task.toMap(),
        },
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã import $imported sự kiện mới từ Google Calendar.'),
      ),
    );
  }

  Future<void> _exportTaskToGoogleCalendar(StudyTask task) async {
    bool ok;
    try {
      ok = await _calendarOAuthService.createEventFromTask(
        title: task.title,
        description: 'Môn học: ${task.subject}',
        startAt: task.deadline,
        endAt: task.deadline.add(Duration(minutes: task.estimatedMinutes)),
        appTaskId: task.id,
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Push Google Calendar thất bại.')),
      );
      return;
    }

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
