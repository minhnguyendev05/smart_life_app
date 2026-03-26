import '../models/smart_suggestion.dart';
import '../models/study_task.dart';
import '../providers/finance_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/study_provider.dart';

class SmartSuggestionService {
  SmartSuggestionService({
    required this.studyProvider,
    required this.financeProvider,
    required this.notesProvider,
  });

  final StudyProvider studyProvider;
  final FinanceProvider financeProvider;
  final NotesProvider notesProvider;

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
}
