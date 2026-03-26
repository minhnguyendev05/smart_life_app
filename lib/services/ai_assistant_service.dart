import '../providers/finance_provider.dart';
import '../providers/study_provider.dart';
import 'llm_api_service.dart';

class AIAssistantService {
  AIAssistantService({
    required this.studyProvider,
    required this.financeProvider,
    required this.llmApiService,
  });

  final StudyProvider studyProvider;
  final FinanceProvider financeProvider;
  final LlmApiService llmApiService;

  static const Map<String, Set<String>> _intentLexicon = {
    'study': {
      'hoc', 'deadline', 'task', 'on', 'thi', 'mon', 'ke-hoach', 'pomodoro', 'time', 'blocking'
    },
    'finance': {
      'chi', 'tieu', 'tai', 'chinh', 'tien', 'ngan', 'sach', 'thu', 'vi', 'balance'
    },
    'planning': {
      'goi', 'y', 'ke', 'hoach', 'sap', 'xep', 'uu', 'tien', 'toi', 'nay', 'hom'
    },
  };

  static const Set<String> _stopWords = {
    'la', 'va', 'cua', 'cho', 'de', 'toi', 'ban', 'minh', 'the', 'nao', 'gi', 'nhe',
    'please', 'help', 'với', 'đi', 'được', 'không', 'anh', 'chị', 'em', 'ơi',
  };

  Future<String> reply(String prompt) async {
    final llm = await llmApiService.generateReply(prompt);
    if (llm != null && llm.isNotEmpty) {
      return llm;
    }

    final input = prompt.toLowerCase().trim();
    final tokens = _tokenize(input);
    final intent = _detectIntent(tokens);

    if (intent == 'study') {
      final upcoming = studyProvider.tasks.where((e) => !e.isOverdue).take(3).toList();
      if (upcoming.isEmpty) {
        return 'Bạn không có deadline gần. Có thể dành 45 phút để ôn tập môn khó nhất hôm nay.';
      }
      final first = upcoming.first;
      final urgentCount = studyProvider.tasks.where((e) => !e.isOverdue && e.deadline.difference(DateTime.now()).inHours <= 24).length;
      return 'Deadline gần nhất: ${first.title}. Gợi ý: dùng chu kỳ 25-5 trong ${first.estimatedMinutes} phút. Bạn đang có $urgentCount task cần ưu tiên trong 24h.';
    }

    if (intent == 'finance') {
      if (financeProvider.isOverBudget) {
        return 'Bạn đang vượt ngân sách. Nên ưu tiên các khoản bắt buộc và giới hạn mức chi mới trong 3 ngày tới.';
      }
      return 'Số dư hiện tại là ${financeProvider.balance.toStringAsFixed(0)} VND. Bạn có thể phân bổ ngân sách học tập khoảng 20%.';
    }

    if (intent == 'planning') {
      return 'Gợi ý nhanh: 1) Hoàn tất 1 deadline trong 2 giờ tới. 2) Ghi lại 3 ý chính buổi học. 3) Kiểm tra chi tiêu trước 22h.';
    }

    // Hook point for external AI API.
    return 'Mình đã ghi nhận câu hỏi. Bạn có thể hỏi về deadline, kế hoạch học, hoặc quản lý chi tiêu để nhận gợi ý cụ thể.';
  }

  Set<String> _tokenize(String input) {
    final normalized = input
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return const <String>{};
    final raw = normalized.split(' ');
    return raw
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty && !_stopWords.contains(e))
        .toSet();
  }

  String _detectIntent(Set<String> tokens) {
    if (tokens.isEmpty) {
      return 'planning';
    }

    var bestIntent = 'planning';
    var bestScore = -1.0;
    for (final entry in _intentLexicon.entries) {
      final overlap = tokens.intersection(entry.value).length.toDouble();
      final denom = (tokens.length + entry.value.length - overlap);
      final jaccard = denom <= 0 ? 0 : overlap / denom;
      final score = overlap * 0.8 + jaccard * 0.2;
      if (score > bestScore) {
        bestScore = score;
        bestIntent = entry.key;
      }
    }
    return bestIntent;
  }
}
