import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_category.dart';
import '../../models/finance_transaction.dart';
import '../../providers/finance_provider.dart';
import '../../providers/sync_provider.dart';
import '../../utils/formatters.dart';
import 'finance_screen.dart';
import 'finance_shared_widgets.dart';
import 'finance_styles.dart';
import 'finance_transaction_entry_screen.dart';

class _CategoryPickerResult {
  const _CategoryPickerResult({this.category, required this.includedInReports});

  final String? category;
  final bool includedInReports;

  bool get hasCategory => (category != null) && category!.trim().isNotEmpty;
}

class FinanceClassifyTransactionsScreen extends StatefulWidget {
  const FinanceClassifyTransactionsScreen({
    super.key,
    required this.iconForIncomeCategory,
    required this.iconForExpenseCategory,
  });

  final IconData Function(String category) iconForIncomeCategory;
  final IconData Function(String category) iconForExpenseCategory;

  @override
  State<FinanceClassifyTransactionsScreen> createState() =>
      _FinanceClassifyTransactionsScreenState();
}

class _FinanceClassifyTransactionsScreenState
    extends State<FinanceClassifyTransactionsScreen> {
  static const List<String> _incomeTemplateCategories = [
    'Thu hồi nợ',
    'Kinh doanh',
    'Lợi nhuận',
    'Thưởng',
    'Trợ cấp',
    'Lương',
  ];

  static const List<FinanceCategoryGroup> _expenseTemplateGroups = [
    FinanceCategoryGroup(
      title: 'Chi tiêu - sinh hoạt',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFFF8E2D),
      categories: ['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'],
    ),
    FinanceCategoryGroup(
      title: 'Chi phí phát sinh',
      icon: Icons.layers_outlined,
      color: Color(0xFFF5BE2E),
      categories: ['Mua sắm', 'Giải trí', 'Làm đẹp', 'Sức khỏe', 'Từ thiện'],
    ),
    FinanceCategoryGroup(
      title: 'Chi phí cố định',
      icon: Icons.home_work_outlined,
      color: Color(0xFF2C8AEE),
      categories: ['Hóa đơn', 'Nhà cửa', 'Người thân'],
    ),
    FinanceCategoryGroup(
      title: 'Đầu tư - tiết kiệm',
      icon: Icons.savings_outlined,
      color: Color(0xFF46C7B8),
      categories: ['Đầu tư', 'Học tập'],
    ),
  ];

  bool _selectMode = false;
  final Set<String> _selectedTransactionIds = <String>{};

  List<FinanceTransaction> _pendingTransactions(FinanceProvider provider) {
    return FinanceClassifyHelper.pendingTransactions(provider.transactions);
  }

  Map<DateTime, List<FinanceTransaction>> _groupByDate(
    List<FinanceTransaction> source,
  ) {
    final grouped = <DateTime, List<FinanceTransaction>>{};
    for (final tx in source) {
      final day = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      grouped.putIfAbsent(day, () => <FinanceTransaction>[]).add(tx);
    }
    return grouped;
  }

  String _formatDateHeader(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }

  String _money(double amount) {
    final raw = Formatters.currency(
      amount,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  Color _amountColor(TransactionType type) {
    return type == TransactionType.income
        ? const Color(0xFF1E9C48)
        : const Color(0xFFE15252);
  }

  IconData _leadingIcon(TransactionType type) {
    return type == TransactionType.income
        ? Icons.south_rounded
        : Icons.north_rounded;
  }

  Color _leadingColor(TransactionType type) {
    return type == TransactionType.income
        ? const Color(0xFF25C9A6)
        : const Color(0xFFFF8A5B);
  }

  FinanceCategory? _findCustomCategory({
    required List<FinanceCategory> customCategories,
    required String category,
    required TransactionType type,
  }) {
    final normalizedName = category.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      return null;
    }

    for (final item in customCategories) {
      if (item.type != type) {
        continue;
      }
      if (item.name.trim().toLowerCase() == normalizedName) {
        return item;
      }
    }
    return null;
  }

  IconData _pickerCategoryIconData({
    required String category,
    required TransactionType type,
    required List<FinanceCategory> customCategories,
  }) {
    final customCategory = _findCustomCategory(
      customCategories: customCategories,
      category: category,
      type: type,
    );
    if (customCategory != null) {
      return customCategory.icon;
    }

    return type == TransactionType.expense
        ? widget.iconForExpenseCategory(category)
        : widget.iconForIncomeCategory(category);
  }

  Color _pickerCategoryIconColor(
    String category,
    TransactionType type, {
    List<FinanceCategory> customCategories = const <FinanceCategory>[],
  }) {
    final customCategory = _findCustomCategory(
      customCategories: customCategories,
      category: category,
      type: type,
    );
    if (customCategory != null) {
      return customCategory.color;
    }

    return FinanceCategoryVisualCatalog.colorFor(
      category,
      isExpense: type == TransactionType.expense,
      fallbackColor: type == TransactionType.expense
          ? const Color(0xFF47C7A8)
          : const Color(0xFF8F7CFF),
    );
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onPickCategory(FinanceTransaction tx) async {
    final picked = await _openCategoryPicker(transaction: tx);
    if (!mounted || picked == null) {
      return;
    }

    await _applyClassificationToTransactions([tx], picked);
  }

  Future<void> _applyClassificationToTransactions(
    List<FinanceTransaction> transactions,
    _CategoryPickerResult picked,
  ) async {
    if (transactions.isEmpty) {
      return;
    }

    if (picked.includedInReports && !picked.hasCategory) {
      return;
    }

    final provider = context.read<FinanceProvider>();
    final syncProvider = context.read<SyncProvider>();

    for (final tx in transactions) {
      final updated = await provider.updateTransactionClassification(
        transactionId: tx.id,
        category: picked.category,
        includedInReports: picked.includedInReports,
      );

      if (updated == null) {
        continue;
      }

      syncProvider.queueAction(
        entity: 'finance',
        entityId: updated.id,
        payload: {'operation': 'upsert', 'transaction': updated.toMap()},
      );
    }

    if (!mounted || _selectedTransactionIds.isEmpty) {
      return;
    }

    final selectedIds = transactions.map((tx) => tx.id).toSet();
    setState(() {
      _selectedTransactionIds.removeWhere((id) => selectedIds.contains(id));
    });
  }

  Future<String?> _openCreateCategoryFlow({
    required TransactionType initialType,
  }) async {
    final created = await showFinanceCreateCategoryFlow(
      context: context,
      initialType: initialType,
    );
    return created?.name;
  }

  List<String> _incomeCategories({
    required List<FinanceCategory> customCategories,
    required String query,
  }) {
    final categories = <String>[..._incomeTemplateCategories];

    for (final item in customCategories.where(
      (entry) => entry.type == TransactionType.income,
    )) {
      final exists = categories.any(
        (name) => name.toLowerCase() == item.name.toLowerCase(),
      );
      if (!exists) {
        categories.add(item.name);
      }
    }

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return categories;
    }

    return categories
        .where((name) => name.toLowerCase().contains(normalizedQuery))
        .toList();
  }

  List<FinanceCategoryGroup> _expenseCategories({
    required List<FinanceCategory> customCategories,
    required String query,
  }) {
    final merged = _expenseTemplateGroups
        .map(
          (group) => FinanceCategoryGroup(
            title: group.title,
            icon: group.icon,
            color: group.color,
            categories: <String>[...group.categories],
          ),
        )
        .toList();

    for (final item in customCategories.where(
      (entry) => entry.type == TransactionType.expense,
    )) {
      final normalizedGroup = item.group.trim().toLowerCase();
      final index = merged.indexWhere(
        (group) => group.title.trim().toLowerCase() == normalizedGroup,
      );

      if (index >= 0) {
        final exists = merged[index].categories.any(
          (name) => name.toLowerCase() == item.name.toLowerCase(),
        );
        if (!exists) {
          merged[index].categories.add(item.name);
        }
        continue;
      }

      var fallbackIndex = merged.indexWhere(
        (group) => group.title.toLowerCase() == 'khác',
      );
      if (fallbackIndex < 0) {
        merged.add(
          const FinanceCategoryGroup(
            title: 'Khác',
            icon: Icons.grid_view_rounded,
            color: Color(0xFF8E8EA0),
            categories: <String>[],
          ),
        );
        fallbackIndex = merged.length - 1;
      }

      final exists = merged[fallbackIndex].categories.any(
        (name) => name.toLowerCase() == item.name.toLowerCase(),
      );
      if (!exists) {
        merged[fallbackIndex].categories.add(item.name);
      }
    }

    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return merged.where((group) => group.categories.isNotEmpty).toList();
    }

    final filtered = <FinanceCategoryGroup>[];
    for (final group in merged) {
      final matchByTitle = group.title.toLowerCase().contains(normalizedQuery);
      final matchedCategories = group.categories.where((name) {
        return name.toLowerCase().contains(normalizedQuery);
      }).toList();

      if (!matchByTitle && matchedCategories.isEmpty) {
        continue;
      }

      filtered.add(
        FinanceCategoryGroup(
          title: group.title,
          icon: group.icon,
          color: group.color,
          categories: matchByTitle ? [...group.categories] : matchedCategories,
        ),
      );
    }
    return filtered;
  }

  Future<_CategoryPickerResult?> _openCategoryPicker({
    required FinanceTransaction transaction,
  }) {
    final provider = context.read<FinanceProvider>();
    var customCategories = List<FinanceCategory>.from(
      provider.customCategories,
    );
    final searchController = TextEditingController();

    return showModalBottomSheet<_CategoryPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        var query = '';
        var includeInReport = transaction.includedInReports;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final isIncome = transaction.type == TransactionType.income;
            final incomeOptions = _incomeCategories(
              customCategories: customCategories,
              query: query,
            );
            final expenseOptions = _expenseCategories(
              customCategories: customCategories,
              query: query,
            );

            return FinanceSheetScaffold(
              heightFactor: 0.82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 10, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: _FittedLabel(
                              'Chọn danh mục',
                              alignment: Alignment.center,
                              height: 32,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: FinanceColors.textStrong,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (!includeInReport) {
                              Navigator.pop(
                                ctx,
                                const _CategoryPickerResult(
                                  includedInReports: false,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.close_rounded, size: 36),
                          color: FinanceColors.sheetCloseIcon,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: isIncome
                        ? Row(
                            children: [
                              Expanded(
                                child: _FittedLabel(
                                  'Không có danh mục bạn cần?',
                                  style: const TextStyle(
                                    color: Color(0xFF6C6C75),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              _CreateCategoryButton(
                                onPressed: () async {
                                  final created = await _openCreateCategoryFlow(
                                    initialType: transaction.type,
                                  );
                                  if (created == null || !mounted) {
                                    return;
                                  }
                                  customCategories = List<FinanceCategory>.from(
                                    this.context
                                        .read<FinanceProvider>()
                                        .customCategories,
                                  );
                                  if (!ctx.mounted) {
                                    return;
                                  }
                                  Navigator.pop(
                                    ctx,
                                    _CategoryPickerResult(
                                      category: includeInReport
                                          ? created
                                          : null,
                                      includedInReports: includeInReport,
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  onChanged: (value) => setModalState(() {
                                    query = value;
                                  }),
                                  decoration: InputDecoration(
                                    hintText: 'Tìm kiếm',
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: FinanceColors.textMuted,
                                    ),
                                    filled: true,
                                    fillColor: FinanceTheme.surface(context),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _CreateCategoryButton(
                                onPressed: () async {
                                  final created = await _openCreateCategoryFlow(
                                    initialType: transaction.type,
                                  );
                                  if (created == null || !mounted) {
                                    return;
                                  }
                                  customCategories = List<FinanceCategory>.from(
                                    this.context
                                        .read<FinanceProvider>()
                                        .customCategories,
                                  );
                                  if (!ctx.mounted) {
                                    return;
                                  }
                                  Navigator.pop(
                                    ctx,
                                    _CategoryPickerResult(
                                      category: includeInReport
                                          ? created
                                          : null,
                                      includedInReports: includeInReport,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCE4FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E9F6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: FinanceTheme.surface(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.bar_chart_rounded,
                            color: const Color(0xFF27C3B3),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FittedLabel(
                            isIncome
                                ? 'Tính vào thu nhập'
                                : 'Tính khoản này vào Chi tiêu',
                            style: const TextStyle(
                              fontSize: 19 / 1.1,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2F2F37),
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: includeInReport,
                          onChanged: (value) =>
                              setModalState(() => includeInReport = value),
                          activeThumbColor: const Color(0xFF32CC59),
                          activeTrackColor: const Color(0xFFB9F2C8),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: includeInReport ? 1 : 0.45,
                      duration: const Duration(milliseconds: 180),
                      child: isIncome
                          ? _IncomeCategoryGrid(
                              categories: incomeOptions,
                              selectedCategory: transaction.category,
                              iconForCategory: (category) =>
                                  _pickerCategoryIconData(
                                    category: category,
                                    type: TransactionType.income,
                                    customCategories: customCategories,
                                  ),
                              iconColorForCategory: (category) =>
                                  _pickerCategoryIconColor(
                                    category,
                                    TransactionType.income,
                                    customCategories: customCategories,
                                  ),
                              enabled: includeInReport,
                              onSelected: (category) => Navigator.pop(
                                ctx,
                                _CategoryPickerResult(
                                  category: category,
                                  includedInReports: includeInReport,
                                ),
                              ),
                            )
                          : _ExpenseCategoryGroups(
                              groups: expenseOptions,
                              selectedCategory: transaction.category,
                              iconForCategory: (category) =>
                                  _pickerCategoryIconData(
                                    category: category,
                                    type: TransactionType.expense,
                                    customCategories: customCategories,
                                  ),
                              iconColorForCategory: (category) =>
                                  _pickerCategoryIconColor(
                                    category,
                                    TransactionType.expense,
                                    customCategories: customCategories,
                                  ),
                              enabled: includeInReport,
                              onSelected: (category) => Navigator.pop(
                                ctx,
                                _CategoryPickerResult(
                                  category: category,
                                  includedInReports: includeInReport,
                                ),
                              ),
                            ),
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

  void _toggleTransactionSelection(String transactionId) {
    if (!_selectMode) {
      return;
    }

    setState(() {
      if (!_selectedTransactionIds.add(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
      }
    });
  }

  List<FinanceTransaction> _selectedPendingTransactions(
    List<FinanceTransaction> pending,
  ) {
    return pending
        .where((tx) => _selectedTransactionIds.contains(tx.id))
        .toList();
  }

  Future<void> _onClassifySelected(List<FinanceTransaction> selected) async {
    if (selected.isEmpty) {
      _showSnack('Hãy chọn giao dịch cần phân loại.');
      return;
    }

    final firstType = selected.first.type;
    final hasMixedTypes = selected.any((tx) => tx.type != firstType);
    if (hasMixedTypes) {
      _showSnack('Chỉ phân loại cùng lúc các giao dịch cùng loại.');
      return;
    }

    final picked = await _openCategoryPicker(transaction: selected.first);
    if (!mounted || picked == null) {
      return;
    }

    await _applyClassificationToTransactions(selected, picked);
  }

  Widget _buildSelectButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          if (_selectMode) {
            _selectMode = false;
            _selectedTransactionIds.clear();
          } else {
            _selectMode = true;
          }
        });
      },
      icon: Icon(
        _selectMode ? Icons.check_circle_rounded : Icons.check_circle_outline,
        size: 24,
      ),
      label: _FittedLabel(
        _selectMode ? 'Xong' : 'Chọn',
        height: 20,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: FinanceColors.accentPrimary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: FinanceColors.accentPrimary,
        side: const BorderSide(color: FinanceColors.accentPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildBulkActionBar(List<FinanceTransaction> selectedTransactions) {
    final selectedCount = selectedTransactions.length;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: FinanceTheme.surface(context),
          border: const Border(top: BorderSide(color: FinanceColors.border)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: _FittedLabel(
                selectedCount == 0
                    ? 'Chưa chọn giao dịch'
                    : 'Đã chọn $selectedCount giao dịch',
                height: 24,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3A3A42),
                ),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: selectedCount == 0
                  ? null
                  : () => setState(() => _selectedTransactionIds.clear()),
              child: const _FittedLabel(
                'Bỏ chọn',
                height: 22,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: selectedCount == 0
                  ? null
                  : () => _onClassifySelected(selectedTransactions),
              style: FilledButton.styleFrom(
                backgroundColor: FinanceColors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _FittedLabel(
                selectedCount == 0 ? 'Phân loại' : 'Phân loại ($selectedCount)',
                height: 22,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(FinanceTransaction tx) {
    final amountText =
        '${tx.type == TransactionType.income ? '+' : '-'}${_money(tx.amount)}';
    final isSelected = _selectedTransactionIds.contains(tx.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 360;
          final isWide = constraints.maxWidth >= 430;
          final avatarSize = isNarrow ? 62.0 : 74.0;
          final iconContainerSize = isNarrow ? 36.0 : 42.0;
          final amountSlotWidth = isNarrow ? 72.0 : 96.0;
          final chipTargetWidth = isNarrow ? 146.0 : (isWide ? 176.0 : 154.0);

          return InkWell(
            onTap: _selectMode
                ? () => _toggleTransactionSelection(tx.id)
                : null,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _selectMode && isSelected
                    ? const Color(0xFFF2F8FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: _selectMode && isSelected
                    ? Border.all(color: const Color(0xFFD3E6FF))
                    : null,
              ),
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_selectMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? FinanceColors.accentPrimary
                            : const Color(0xFFB5B4BC),
                        size: 25,
                      ),
                    ),
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: FinanceTheme.surface(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4E1EA)),
                    ),
                    child: Center(
                      child: Container(
                        width: iconContainerSize,
                        height: iconContainerSize,
                        decoration: BoxDecoration(
                          color: _leadingColor(tx.type).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(
                            isNarrow ? 10 : 12,
                          ),
                        ),
                        child: Icon(
                          _leadingIcon(tx.type),
                          color: _leadingColor(tx.type),
                          size: isNarrow ? 24 : 28,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isNarrow ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isNarrow ? 17 : 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF34343C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, innerConstraints) {
                            final chipMaxWidth =
                                innerConstraints.maxWidth < chipTargetWidth
                                ? innerConstraints.maxWidth
                                : chipTargetWidth;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: _CategorySelectButton(
                                label: 'Chưa phân loại',
                                maxWidth: chipMaxWidth,
                                onPressed: _selectMode
                                    ? null
                                    : () => _onPickCategory(tx),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: amountSlotWidth,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _FittedLabel(
                        amountText,
                        alignment: Alignment.centerRight,
                        height: isNarrow ? 24 : 26,
                        style: TextStyle(
                          fontSize: isNarrow ? 17 : (20 / 1.1),
                          fontWeight: FontWeight.w900,
                          color: _amountColor(tx.type),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: FinanceTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinanceColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
      child: Column(
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6CD3F8).withValues(alpha: 0.25),
                  const Color(0xFFFFE37B).withValues(alpha: 0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                width: 118,
                height: 136,
                decoration: BoxDecoration(
                  color: const Color(0xFFB7F4E9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF26C4B4), width: 4),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: Color(0xFF17B9A8),
                  size: 66,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _FittedLabel(
            'Đã phân loại giao dịch xong',
            alignment: Alignment.center,
            height: 36,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26 / 1.1,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F2F37),
            ),
          ),
          const SizedBox(height: 10),
          const _FittedLabel(
            'Bạn không còn giao dịch nào cần phân loại.',
            alignment: Alignment.center,
            height: 24,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Color(0xFF3E3E47),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: FinanceColors.accentPrimary,
              side: const BorderSide(color: FinanceColors.accentPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const _FittedLabel(
              'Xem báo cáo',
              height: 24,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final pending = _pendingTransactions(provider);
    final grouped = _groupByDate(pending);
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final selectedTransactions = _selectedPendingTransactions(pending);
    final listBottomPadding = _selectMode ? 108.0 : 18.0;

    if (pending.isEmpty && _selectMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _selectMode = false;
          _selectedTransactionIds.clear();
        });
      });
    }

    return Scaffold(
      backgroundColor: FinanceTheme.pageBackground(context),
      appBar: const FinanceGradientAppBar(title: 'Phân loại giao dịch'),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(14, 10, 14, listBottomPadding),
          children: [
            if (pending.isEmpty)
              _buildEmptyState()
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _FittedLabel(
                      'Phân loại nhiều giao dịch cùng lúc',
                      height: 31,
                      style: const TextStyle(
                        color: Color(0xFF3A3A42),
                        fontWeight: FontWeight.w900,
                        fontSize: 24 / 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSelectButton(),
                ],
              ),
              const SizedBox(height: 12),
              ...sortedDates.map((date) {
                final items = grouped[date] ?? const <FinanceTransaction>[];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: FinanceTheme.surface(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FinanceColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEBF1F7),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: _FittedLabel(
                          _formatDateHeader(date),
                          height: 25,
                          style: const TextStyle(
                            fontSize: 20 / 1.1,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4B4B53),
                          ),
                        ),
                      ),
                      ...List.generate(items.length, (index) {
                        return Column(
                          children: [
                            _buildTransactionRow(items[index]),
                            if (index < items.length - 1)
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFEAE7EF),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _selectMode && pending.isNotEmpty
          ? _buildBulkActionBar(selectedTransactions)
          : null,
    );
  }
}

class _CreateCategoryButton extends StatelessWidget {
  const _CreateCategoryButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FinanceCreateCategoryButton(onPressed: onPressed);
  }
}

class _CategorySelectButton extends StatelessWidget {
  const _CategorySelectButton({
    required this.label,
    required this.maxWidth,
    this.onPressed,
  });

  final String label;
  final double maxWidth;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FinanceCategorySelectChip(
      label: label,
      icon: Icons.question_mark_rounded,
      iconColor: FinanceColors.accentPrimary,
      borderColor: FinanceColors.accentPrimary,
      onTap: onPressed,
      maxWidth: maxWidth,
      maxVisualWidth: 240,
      minTextModeWidth: 82,
      showChevron: false,
      backgroundColor: FinanceTheme.surface(context),
      labelColor: const Color(0xFF74737C),
      labelFontSize: 14,
    );
  }
}

class _FittedLabel extends StatelessWidget {
  const _FittedLabel(
    this.text, {
    required this.style,
    this.alignment = Alignment.centerLeft,
    this.height,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Alignment alignment;
  final double? height;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final lineHeight =
        height ?? (((style.fontSize ?? 14) * (style.height ?? 1.35)) + 2);
    return SizedBox(
      height: lineHeight,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(text, textAlign: textAlign, style: style),
      ),
    );
  }
}

class _IncomeCategoryGrid extends StatelessWidget {
  const _IncomeCategoryGrid({
    required this.categories,
    required this.selectedCategory,
    required this.iconForCategory,
    required this.iconColorForCategory,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final IconData Function(String category) iconForCategory;
  final Color Function(String category) iconColorForCategory;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: _FittedLabel(
          'Không có danh mục phù hợp',
          alignment: Alignment.center,
          style: TextStyle(
            color: Color(0xFF8D8D95),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: FinanceTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinanceColors.border),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 10,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          final iconColor = iconColorForCategory(category);
          return FinanceCategoryChoiceTile(
            label: category,
            icon: iconForCategory(category),
            selected: category.toLowerCase() == selectedCategory.toLowerCase(),
            enabled: enabled,
            onTap: () => onSelected(category),
            iconSize: 34,
            labelFontSize: 14,
            labelHeight: 34,
            labelMaxLines: 2,
            iconToLabelSpacing: 8,
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
            backgroundColor: Colors.transparent,
            selectedBackgroundColor: const Color(0xFFFFEEF8),
            unselectedBorderColor: Colors.transparent,
            selectedBorderColor: FinanceColors.accentPrimary,
            borderWidth: 1,
            selectedBorderWidth: 2,
            showSelectedIconBadge: false,
            unselectedIconColor: iconColor,
            selectedIconColor: iconColor,
          );
        },
      ),
    );
  }
}

class _ExpenseCategoryGroups extends StatelessWidget {
  const _ExpenseCategoryGroups({
    required this.groups,
    required this.selectedCategory,
    required this.iconForCategory,
    required this.iconColorForCategory,
    required this.enabled,
    required this.onSelected,
  });

  final List<FinanceCategoryGroup> groups;
  final String selectedCategory;
  final IconData Function(String category) iconForCategory;
  final Color Function(String category) iconColorForCategory;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(
        child: _FittedLabel(
          'Không tìm thấy danh mục phù hợp',
          alignment: Alignment.center,
          style: TextStyle(
            color: Color(0xFF8D8D95),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return FinanceCategoryGroupSection(
          group: group,
          selectedCategory: selectedCategory,
          iconForCategory: iconForCategory,
          iconColorForCategory: iconColorForCategory,
          enabled: enabled,
          onSelect: onSelected,
        );
      },
    );
  }
}
