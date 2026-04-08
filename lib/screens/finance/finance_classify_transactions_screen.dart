part of 'finance_screen.dart';

class _CategoryPickerResult {
  const _CategoryPickerResult({this.category, required this.includedInReports});

  final String? category;
  final bool includedInReports;

  bool get hasCategory => (category != null) && category!.trim().isNotEmpty;
}

class _ClassifyTransactionsScreen extends StatefulWidget {
  const _ClassifyTransactionsScreen({
    required this.iconForIncomeCategory,
    required this.iconForExpenseCategory,
  });

  final IconData Function(String category) iconForIncomeCategory;
  final IconData Function(String category) iconForExpenseCategory;

  @override
  State<_ClassifyTransactionsScreen> createState() =>
      _ClassifyTransactionsScreenState();
}

class _ClassifyTransactionsScreenState
    extends State<_ClassifyTransactionsScreen> {
  static const Set<String> _uncategorizedAliases = {
    '',
    'chua phan loai',
    'chưa phân loại',
    'khong phan loai',
    'không phân loại',
    'uncategorized',
    'unclassified',
    'khac',
    'khác',
    'other',
  };

  static const List<String> _incomeTemplateCategories = [
    'Thu hồi nợ',
    'Kinh doanh',
    'Lợi nhuận',
    'Thưởng',
    'Trợ cấp',
    'Lương',
  ];

  static const List<_CategoryGroup> _expenseTemplateGroups = [
    _CategoryGroup(
      title: 'Chi tiêu - sinh hoạt',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFFF8E2D),
      categories: ['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'],
    ),
    _CategoryGroup(
      title: 'Chi phí phát sinh',
      icon: Icons.layers_outlined,
      color: Color(0xFFF5BE2E),
      categories: ['Mua sắm', 'Giải trí', 'Làm đẹp', 'Sức khỏe', 'Từ thiện'],
    ),
    _CategoryGroup(
      title: 'Chi phí cố định',
      icon: Icons.home_work_outlined,
      color: Color(0xFF2C8AEE),
      categories: ['Hóa đơn', 'Nhà cửa', 'Người thân'],
    ),
    _CategoryGroup(
      title: 'Đầu tư - tiết kiệm',
      icon: Icons.savings_outlined,
      color: Color(0xFF46C7B8),
      categories: ['Đầu tư', 'Học tập'],
    ),
  ];

  bool _selectMode = false;
  final Set<String> _selectedTransactionIds = <String>{};

  List<FinanceTransaction> _pendingTransactions(FinanceProvider provider) {
    return provider.transactions.where((item) {
      if (!item.includedInReports) {
        return false;
      }
      final normalized = item.category.trim().toLowerCase();
      return _uncategorizedAliases.contains(normalized);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    final provider = context.read<FinanceProvider>();
    final custom = provider.customCategories;

    final usedExpense = custom
        .where((item) => item.type == TransactionType.expense)
        .map((item) => item.icon)
        .toSet()
        .toList();
    final usedIncome = custom
        .where((item) => item.type == TransactionType.income)
        .map((item) => item.icon)
        .toSet()
        .toList();

    final result = await Navigator.of(context).push<_CreateCategoryResult>(
      MaterialPageRoute<_CreateCategoryResult>(
        builder: (_) => _CreateCategoryScreen(
          initialType: initialType,
          parentOptions: _TransactionEntryScreenState._expenseParentOptions,
          expenseIcons:
              _TransactionEntryScreenState._expenseCreateCategoryIcons,
          incomeIcons: _TransactionEntryScreenState._incomeCreateCategoryIcons,
          usedExpenseIcons: usedExpense,
          usedIncomeIcons: usedIncome,
          iconPalette: _TransactionEntryScreenState._createIconPalette,
        ),
      ),
    );

    if (result == null) {
      return null;
    }

    final normalizedName = result.name.trim();
    final model = FinanceCategory(
      id: FinanceCategory.buildStableId(
        type: result.type,
        name: normalizedName,
      ),
      type: result.type,
      name: normalizedName,
      group: result.group,
      iconCodePoint: result.icon.codePoint,
      iconFontFamily: result.icon.fontFamily,
      iconFontPackage: result.icon.fontPackage,
      iconMatchTextDirection: result.icon.matchTextDirection,
      colorValue: result.color.toARGB32(),
      updatedAt: DateTime.now(),
    );

    await provider.addOrUpdateCustomCategory(model);
    if (!mounted) {
      return normalizedName;
    }

    context.read<SyncProvider>().queueAction(
      entity: 'finance_category',
      entityId: model.id,
      payload: {'operation': 'upsert', 'category': model.toMap()},
    );

    return normalizedName;
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

  List<_CategoryGroup> _expenseCategories({
    required List<FinanceCategory> customCategories,
    required String query,
  }) {
    final merged = _expenseTemplateGroups
        .map(
          (group) => _CategoryGroup(
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
          const _CategoryGroup(
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

    final filtered = <_CategoryGroup>[];
    for (final group in merged) {
      final matchByTitle = group.title.toLowerCase().contains(normalizedQuery);
      final matchedCategories = group.categories.where((name) {
        return name.toLowerCase().contains(normalizedQuery);
      }).toList();

      if (!matchByTitle && matchedCategories.isEmpty) {
        continue;
      }

      filtered.add(
        _CategoryGroup(
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

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.82,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F3F8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 52,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D7DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
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
                            color: const Color(0xFF3D3D45),
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
                                    final created =
                                        await _openCreateCategoryFlow(
                                          initialType: transaction.type,
                                        );
                                    if (created == null || !mounted) {
                                      return;
                                    }
                                    customCategories =
                                        List<FinanceCategory>.from(
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
                                        color: Color(0xFF9E9EA6),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                                    final created =
                                        await _openCreateCategoryFlow(
                                          initialType: transaction.type,
                                        );
                                    if (created == null || !mounted) {
                                      return;
                                    }
                                    customCategories =
                                        List<FinanceCategory>.from(
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
                              color: Colors.white,
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
                                iconForCategory: widget.iconForIncomeCategory,
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
                                iconForCategory: widget.iconForExpenseCategory,
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
          color: Colors.white,
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
          final avatarSize = isNarrow ? 62.0 : 74.0;
          final iconContainerSize = isNarrow ? 36.0 : 42.0;
          final amountMaxWidth = isNarrow ? 90.0 : 112.0;

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
                      color: Colors.white,
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
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: _CategorySelectButton(
                                label: 'Chưa phân loại',
                                maxWidth: innerConstraints.maxWidth,
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
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: amountMaxWidth),
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
        color: Colors.white,
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
      backgroundColor: FinanceColors.background,
      appBar: AppBar(
        backgroundColor: FinanceColors.appBarTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: FinanceColors.textStrong,
        ),
        title: const _FittedLabel(
          'Phân loại giao dịch',
          height: 30,
          style: TextStyle(
            color: FinanceColors.textStrong,
            fontWeight: FontWeight.w900,
            fontSize: 31 / 1.15,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.support_agent_rounded, color: Color(0xFF4F4F58)),
                SizedBox(width: 8),
                Icon(Icons.home_outlined, color: Color(0xFF4F4F58)),
              ],
            ),
          ),
        ],
      ),
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
                    color: Colors.white,
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
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle_outline, size: 30),
      label: const _FittedLabel(
        'Tạo mới',
        height: 24,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: FinanceColors.textStrong,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: FinanceColors.textStrong,
        side: const BorderSide(color: Color(0xFFE2DFE8), width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
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
    const horizontalPadding = 14.0;
    const iconSize = 18.0;
    const iconGap = 8.0;
    const arrowGap = 10.0;
    const arrowSize = 18.0;
    const compactArrowGap = 6.0;
    const compactHorizontalPadding = 12.0;
    const widthSafetyBuffer = 12.0;
    const visualMaxWidth = 240.0;
    const labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF74737C),
    );

    final painter = TextPainter(
      text: TextSpan(text: label, style: labelStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    final fullWidthNeeded =
        (horizontalPadding * 2) +
        iconSize +
        iconGap +
        painter.width +
        arrowGap +
        arrowSize +
        widthSafetyBuffer;
    final compactWidth =
        (compactHorizontalPadding * 2) + iconSize + compactArrowGap + arrowSize;

    final allowedMaxWidth = maxWidth < visualMaxWidth
        ? maxWidth
        : visualMaxWidth;
    final showText = allowedMaxWidth >= fullWidthNeeded;
    final resolvedWidth = showText
        ? fullWidthNeeded
        : compactWidth.clamp(36.0, allowedMaxWidth).toDouble();

    return SizedBox(
      width: resolvedWidth,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF6E6D76),
          side: const BorderSide(
            color: FinanceColors.accentPrimary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: showText ? horizontalPadding : compactHorizontalPadding,
            vertical: 10,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(0, 40),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7A2D2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.question_mark_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
              if (showText) ...[
                const SizedBox(width: iconGap),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
                const SizedBox(width: arrowGap),
              ] else ...[
                const SizedBox(width: compactArrowGap),
              ],
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: arrowSize,
                color: Color(0xFF74737C),
              ),
            ],
          ),
        ),
      ),
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
    required this.enabled,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final IconData Function(String category) iconForCategory;
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
        color: Colors.white,
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
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          return _FinanceCategoryChoiceTile(
            label: category,
            icon: iconForCategory(category),
            selected: category.toLowerCase() == selectedCategory.toLowerCase(),
            enabled: enabled,
            onTap: () => onSelected(category),
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
    required this.enabled,
    required this.onSelected,
  });

  final List<_CategoryGroup> groups;
  final String selectedCategory;
  final IconData Function(String category) iconForCategory;
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: group.color.withValues(alpha: 0.13),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(group.icon, color: group.color, size: 22),
                    const SizedBox(width: 8),
                    _FittedLabel(
                      group.title,
                      height: 28,
                      style: TextStyle(
                        color: group.color,
                        fontSize: 21 / 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, categoryIndex) {
                  final category = group.categories[categoryIndex];
                  return _FinanceCategoryChoiceTile(
                    label: category,
                    icon: iconForCategory(category),
                    selected:
                        category.toLowerCase() ==
                        selectedCategory.toLowerCase(),
                    enabled: enabled,
                    onTap: () => onSelected(category),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FinanceCategoryChoiceTile extends StatelessWidget {
  const _FinanceCategoryChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = enabled && selected;
    final color = !enabled
        ? const Color(0xFF9E9EA6)
        : effectiveSelected
        ? FinanceColors.accentPrimary
        : FinanceColors.textStrong;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: effectiveSelected
              ? const Color(0xFFFFEEF8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: effectiveSelected
                ? FinanceColors.accentPrimary
                : Colors.transparent,
            width: effectiveSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: Center(
                child: _FittedLabel(
                  label,
                  alignment: Alignment.center,
                  height: 34,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
