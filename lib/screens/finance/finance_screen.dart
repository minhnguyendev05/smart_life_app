import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_transaction.dart';
import '../../providers/finance_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/receipt_ocr_service.dart';
import '../../utils/formatters.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  static const List<String> _expenseCategories = [
    'Ăn uống',
    'Di chuyển',
    'Học tập',
    'Mua sắm',
    'Hóa đơn',
    'Giải trí',
    'Sức khỏe',
    'Khác',
  ];

  static const List<String> _incomeCategories = [
    'Lương',
    'Thưởng',
    'Freelance',
    'Hỗ trợ gia đình',
    'Khác',
  ];

  TransactionType? _filterType;
  DateTime? _filterMonth;
  final _ocrService = ReceiptOcrService();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final filtered = provider.filterTransactions(
      type: _filterType,
      month: _filterMonth,
    );
    final byCategory = provider.expenseByCategory(month: _filterMonth);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Quản lý tài chính',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _showAddTransactionSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm giao dịch'),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _importFromImage,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Nhập ảnh'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _FinanceInfoCard(
                label: 'Số dư',
                value: Formatters.currency(provider.balance),
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FinanceInfoCard(
                label: 'Đã chi',
                value: Formatters.currency(provider.totalExpense),
                color: provider.isOverBudget ? Colors.redAccent : Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: _filterType == null,
              onSelected: (_) => setState(() => _filterType = null),
            ),
            ChoiceChip(
              label: const Text('Thu'),
              selected: _filterType == TransactionType.income,
              onSelected: (_) => setState(() => _filterType = TransactionType.income),
            ),
            ChoiceChip(
              label: const Text('Chi'),
              selected: _filterType == TransactionType.expense,
              onSelected: (_) => setState(() => _filterType = TransactionType.expense),
            ),
            FilledButton.tonal(
              onPressed: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filterMonth ?? now,
                  firstDate: DateTime(now.year - 2, 1, 1),
                  lastDate: DateTime(now.year + 1, 12, 31),
                );
                if (date != null) {
                  setState(() => _filterMonth = DateTime(date.year, date.month));
                }
              },
              child: Text(
                _filterMonth == null
                    ? 'Lọc theo tháng'
                    : 'Tháng ${_filterMonth!.month}/${_filterMonth!.year}',
              ),
            ),
            if (_filterMonth != null)
              TextButton(
                onPressed: () => setState(() => _filterMonth = null),
                child: const Text('Bỏ lọc tháng'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê thu/chi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 35,
                      sectionsSpace: 4,
                      sections: [
                        PieChartSectionData(
                          value: provider.totalIncome <= 0 ? 1 : provider.totalIncome,
                          color: Colors.teal,
                          title: 'Thu',
                        ),
                        PieChartSectionData(
                          value:
                              provider.totalExpense <= 0 ? 1 : provider.totalExpense,
                          color: Colors.orange,
                          title: 'Chi',
                        ),
                      ],
                    ),
                  ),
                ),
                if (provider.isOverBudget)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Cảnh báo: bạn đã vượt ngân sách tháng!',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (byCategory.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Báo cáo chi tiêu theo danh mục',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...byCategory.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text(Formatters.currency(entry.value)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        ...filtered.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: Icon(
                  item.type == TransactionType.income
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: item.type == TransactionType.income
                      ? Colors.teal
                      : Colors.orange,
                ),
                title: Text(item.title),
                subtitle: Text('${item.category} • ${Formatters.dayTime(item.createdAt)}'),
                trailing: Text(
                  '${item.type == TransactionType.income ? '+' : '-'}${Formatters.currency(item.amount)}',
                  style: TextStyle(
                    color: item.type == TransactionType.income
                        ? Colors.teal
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddTransactionSheet(
    BuildContext context, {
    String? initialTitle,
    double? initialAmount,
    String? initialCategory,
    String? initialNote,
    TransactionType initialType = TransactionType.expense,
  }) async {
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    final amountCtrl = TextEditingController(
      text: initialAmount == null ? '' : initialAmount.toStringAsFixed(0),
    );
    TransactionType type = initialType;
    String category = _resolveInitialCategory(initialCategory, initialType);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    decoration: const InputDecoration(labelText: 'Nội dung'),
                  ),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số tiền'),
                  ),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: _categoryOptions(type)
                        .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        category = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Chi'),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Thu'),
                      ),
                    ],
                    selected: {type},
                    onSelectionChanged: (value) {
                      setState(() {
                        type = value.first;
                        final options = _categoryOptions(type);
                        if (!options.contains(category)) {
                          category = options.first;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final amount = double.tryParse(amountCtrl.text.trim());
                        if (titleCtrl.text.trim().isEmpty || amount == null) {
                          return;
                        }
                        final tx = FinanceTransaction(
                          id: 'trx-${DateTime.now().microsecondsSinceEpoch}',
                          title: titleCtrl.text.trim(),
                          amount: amount,
                          category: category,
                          type: type,
                          createdAt: DateTime.now(),
                          note: initialNote,
                        );
                        context.read<FinanceProvider>().addTransaction(tx);
                        context.read<SyncProvider>().queueAction(
                              entity: 'finance',
                              entityId: tx.id,
                              payload: {
                                'operation': 'upsert',
                                'transaction': tx.toMap(),
                              },
                            );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Lưu giao dịch'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<String> _categoryOptions(TransactionType type) {
    return type == TransactionType.income
        ? _incomeCategories
        : _expenseCategories;
  }

  String _resolveInitialCategory(String? raw, TransactionType type) {
    final options = _categoryOptions(type);
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return options.first;

    for (final option in options) {
      if (option.toLowerCase() == normalized) {
        return option;
      }
    }

    if (type == TransactionType.expense) {
      if (normalized.contains('ăn') || normalized.contains('uong') || normalized.contains('uống')) {
        return 'Ăn uống';
      }
      if (normalized.contains('xe') || normalized.contains('di chuyển') || normalized.contains('grab')) {
        return 'Di chuyển';
      }
      if (normalized.contains('hoc') || normalized.contains('học') || normalized.contains('book')) {
        return 'Học tập';
      }
    }
    return 'Khác';
  }

  Future<void> _importFromImage() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return;
    }

    final result = await _ocrService.parseReceipt(
      imageBytes: bytes,
      filename: file.name,
    );

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OCR không trả về dữ liệu. Kiểm tra OCR_API_KEY hoặc thử ảnh rõ hơn.'),
        ),
      );
      return;
    }

    await _showAddTransactionSheet(
      context,
      initialTitle: result.title,
      initialAmount: result.amount,
      initialCategory: result.category,
      initialNote: 'OCR: ${result.rawText.substring(0, result.rawText.length > 200 ? 200 : result.rawText.length)}',
    );
  }
}

class _FinanceInfoCard extends StatelessWidget {
  const _FinanceInfoCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
