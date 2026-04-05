part of 'finance_screen.dart';

class _BudgetOverviewData {
  const _BudgetOverviewData({
    required this.cards,
    required this.periodBudget,
    required this.periodLabel,
    required this.timeRange,
    required this.periodStart,
    required this.periodEnd,
    required this.totalMonthlyBudget,
    required this.customMonthlyBudgets,
  });

  final List<_BudgetCardInfo> cards;
  final double periodBudget;
  final String periodLabel;
  final _FinanceTimeRange timeRange;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalMonthlyBudget;
  final Map<String, double> customMonthlyBudgets;
}

bool _showMobileKeyboardMoneySuggestions(BuildContext context) {
  final platform = Theme.of(context).platform;
  final isMobile =
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
  return isMobile && keyboardVisible;
}

class _BudgetSortChoiceTile extends StatelessWidget {
  const _BudgetSortChoiceTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 28, color: const Color(0xFF33333B)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22 / 1.2,
                    color: FinanceColors.textStrong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? FinanceColors.accentPrimary
                        : const Color(0xFF33333B),
                    width: 2.6,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: FinanceColors.accentPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetEditScreen extends StatefulWidget {
  const _BudgetEditScreen({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.initialMonthlyBudget,
    required this.hideAmounts,
    required this.points,
    required this.average,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final double initialMonthlyBudget;
  final bool hideAmounts;
  final List<_CategoryPeriodPoint> points;
  final double average;

  @override
  State<_BudgetEditScreen> createState() => _BudgetEditScreenState();
}

class _BudgetEditScreenState extends State<_BudgetEditScreen> {
  late final TextEditingController _amountController;
  late int _selectedHistoryIndex;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _inputMoney(widget.initialMonthlyBudget),
    );
    _selectedHistoryIndex = widget.points.isEmpty
        ? -1
        : widget.points.length - 1;
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  double _parseAmount(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return 0;
    }
    return double.tryParse(digits) ?? 0;
  }

  String _inputMoney(double value) {
    if (value <= 0) {
      return '0';
    }
    return Formatters.currency(value)
        .replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '')
        .replaceAll('đ', '')
        .trim();
  }

  void _handleAmountChanged(String raw) {
    final amount = _parseAmount(raw);
    final formatted = _inputMoney(amount);
    if (formatted != raw) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _applyAmountSuggestion(double amount) {
    final formatted = _inputMoney(amount);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _confirmDeleteInEditScreen() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xác nhận xóa ngân sách',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E2E36),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bạn có thể điều chỉnh hạn mức thay vì xóa nó, nếu kế hoạch chi tiêu này không khả thi.',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.33,
                    color: Color(0xFF4B4B54),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          foregroundColor: FinanceColors.accentPrimary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: FinanceColors.accentPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop(const _BudgetEditResult(monthlyBudget: 0, deleteRequested: true));
  }

  bool get _canUpdate {
    final current = _parseAmount(_amountController.text);
    if (current <= 0) {
      return false;
    }
    return (current - widget.initialMonthlyBudget).abs() >= 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinanceColors.background,
      appBar: AppBar(
        backgroundColor: FinanceColors.appBarTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Chỉnh sửa ngân sách',
          style: TextStyle(
            color: FinanceColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: FinanceColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F6F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 42,
                        color: widget.iconColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Danh mục',
                            style: TextStyle(
                              color: Color(0xFF6B6B73),
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Color(0xFF2E2E36),
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: _handleAmountChanged,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D2D35),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Ngân sách chi tiêu trong tháng*',
                    labelStyle: const TextStyle(fontSize: 16),
                    suffixText: 'đ',
                    suffixStyle: const TextStyle(
                      color: Color(0xFF2D2D35),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE0DDE8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE0DDE8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFF3D3D44),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 26,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Tham khảo thống kê chi tiêu của bạn',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: FinanceColors.textStrong,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CategoryHistoryChart(
            points: widget.points,
            average: widget.average,
            hideAmounts: widget.hideAmounts,
            highlightColor: const Color(0xFF9FC3E7),
            caption: 'Trung bình 5 tháng gần nhất, chỉ tính tháng có chi tiêu',
            selectedIndex: _selectedHistoryIndex,
            onSelectIndex: (index) {
              if (index == _selectedHistoryIndex) {
                return;
              }
              setState(() {
                _selectedHistoryIndex = index;
              });
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Xu hướng chi tiêu ${widget.title} 6 tháng gần đây',
            style: const TextStyle(
              fontSize: 18,
              color: FinanceColors.textStrong,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: _confirmDeleteInEditScreen,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text(
                'Xóa ngân sách',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              style: TextButton.styleFrom(
                foregroundColor: FinanceColors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: FinanceBottomBarSurface(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _showMobileKeyboardMoneySuggestions(context)
                ? Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE3E1EA)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FinanceMoneySuggestionChips(
                          suggestions: const [100000, 1000000, 10000000],
                          onSelected: _applyAmountSuggestion,
                          topPadding: 0,
                          expanded: true,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: FinanceOutlineActionButton(
                                  label: 'Hủy',
                                  borderRadius: 14,
                                  sideColor: const Color(0xFFD7D6DE),
                                  foregroundColor: const Color(0xFF2F2F37),
                                  textStyle: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FinancePrimaryActionButton(
                                label: 'Cập nhật',
                                height: 54,
                                borderRadius: 14,
                                textStyle: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                                onPressed: _canUpdate
                                    ? () {
                                        final amount = _parseAmount(
                                          _amountController.text,
                                        );
                                        Navigator.of(context).pop(
                                          _BudgetEditResult(
                                            monthlyBudget: amount,
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FinanceOutlineActionButton(
                            label: 'Hủy',
                            borderRadius: 14,
                            sideColor: const Color(0xFFD7D6DE),
                            foregroundColor: const Color(0xFF2F2F37),
                            textStyle: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FinancePrimaryActionButton(
                          label: 'Cập nhật',
                          height: 56,
                          borderRadius: 14,
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          onPressed: _canUpdate
                              ? () {
                                  final amount = _parseAmount(
                                    _amountController.text,
                                  );
                                  Navigator.of(context).pop(
                                    _BudgetEditResult(monthlyBudget: amount),
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

enum _BudgetSortOption { byName, byStatus }

class _BudgetEditResult {
  const _BudgetEditResult({
    required this.monthlyBudget,
    this.deleteRequested = false,
  });

  final double monthlyBudget;
  final bool deleteRequested;
}

class _BudgetOverviewScreen extends StatefulWidget {
  const _BudgetOverviewScreen({
    required this.cards,
    required this.periodBudget,
    required this.periodLabel,
    required this.timeRange,
    required this.periodStart,
    required this.periodEnd,
    required this.totalMonthlyBudget,
    required this.customMonthlyBudgets,
    required this.hideAmounts,
    required this.onCreateBudget,
    required this.onOpenCategory,
    required this.onMutateBudget,
  });

  final List<_BudgetCardInfo> cards;
  final double periodBudget;
  final String periodLabel;
  final _FinanceTimeRange timeRange;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalMonthlyBudget;
  final Map<String, double> customMonthlyBudgets;
  final bool hideAmounts;
  final Future<void> Function() onCreateBudget;
  final ValueChanged<_BudgetCardInfo> onOpenCategory;
  final Future<_BudgetOverviewData> Function({
    required _BudgetCardInfo info,
    double? monthlyBudget,
    required bool delete,
    required DateTime periodStart,
    required DateTime periodEnd,
  })
  onMutateBudget;

  @override
  State<_BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<_BudgetOverviewScreen> {
  late List<_BudgetCardInfo> _cards;
  late double _periodBudget;
  late String _periodLabel;
  late DateTime _periodStart;
  late DateTime _periodEnd;
  late double _totalMonthlyBudget;
  late Map<String, double> _customMonthlyBudgets;

  _BudgetSortOption _sortOption = _BudgetSortOption.byName;
  bool _processingAction = false;

  @override
  void initState() {
    super.initState();
    _cards = List<_BudgetCardInfo>.from(widget.cards);
    _periodBudget = widget.periodBudget;
    _periodLabel = widget.periodLabel;
    _periodStart = widget.periodStart;
    _periodEnd = widget.periodEnd;
    _totalMonthlyBudget = widget.totalMonthlyBudget;
    _customMonthlyBudgets = Map<String, double>.from(
      widget.customMonthlyBudgets,
    );
  }

  String _money(double value) {
    if (widget.hideAmounts) {
      return '******';
    }
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  String _sortLabel() {
    switch (_sortOption) {
      case _BudgetSortOption.byName:
        return 'Xếp theo tên';
      case _BudgetSortOption.byStatus:
        return 'Xếp theo trạng thái';
    }
  }

  String _normalizeVietnameseForSort(String raw) {
    const map = {
      'à': 'a',
      'á': 'a',
      'ả': 'a',
      'ã': 'a',
      'ạ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'ặ': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ậ': 'a',
      'è': 'e',
      'é': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ẹ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ệ': 'e',
      'ì': 'i',
      'í': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ị': 'i',
      'ò': 'o',
      'ó': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ọ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ộ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ợ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ụ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ự': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'ỵ': 'y',
      'đ': 'd',
    };

    var value = raw.toLowerCase().trim();
    for (final entry in map.entries) {
      value = value.replaceAll(entry.key, entry.value);
    }

    return value
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _headerPeriodLabel() {
    if (widget.timeRange != _FinanceTimeRange.month) {
      return _periodLabel;
    }
    return 'Tháng ${_periodStart.month} ${_periodStart.year}';
  }

  int _remainingDaysInMonth() {
    if (widget.timeRange != _FinanceTimeRange.month) {
      return _periodEnd.difference(_periodStart).inDays;
    }

    final now = DateTime.now();
    final monthStart = DateTime(_periodStart.year, _periodStart.month, 1);
    final monthDays = DateTime(
      _periodStart.year,
      _periodStart.month + 1,
      0,
    ).day;

    if (monthStart.year == now.year && monthStart.month == now.month) {
      return (monthDays - now.day).clamp(0, monthDays).toInt();
    }

    final selectedMonth = DateTime(monthStart.year, monthStart.month);
    final currentMonth = DateTime(now.year, now.month);
    if (selectedMonth.isAfter(currentMonth)) {
      return monthDays;
    }
    return 0;
  }

  _BudgetCardInfo get _totalCard {
    if (_cards.isEmpty) {
      return const _BudgetCardInfo(
        title: 'Ngân sách tổng',
        allocated: 0,
        spent: 0,
        icon: Icons.account_balance_wallet_outlined,
        accentColor: Color(0xFF1BB7B8),
        isTotal: true,
      );
    }
    final index = _cards.indexWhere((item) => item.isTotal);
    if (index >= 0) {
      return _cards[index];
    }
    return _cards.first;
  }

  List<_BudgetCardInfo> _sortedCategories() {
    final categories = _cards.where((item) => !item.isTotal).toList();
    switch (_sortOption) {
      case _BudgetSortOption.byName:
        categories.sort((a, b) {
          final left = _normalizeVietnameseForSort(a.title);
          final right = _normalizeVietnameseForSort(b.title);
          final normalizedCompare = left.compareTo(right);
          if (normalizedCompare != 0) {
            return normalizedCompare;
          }
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        return categories;
      case _BudgetSortOption.byStatus:
        categories.sort((a, b) {
          final aRank = a.isOverBudget ? 0 : 1;
          final bRank = b.isOverBudget ? 0 : 1;
          if (aRank != bRank) {
            return aRank.compareTo(bRank);
          }
          final remainingCompare = a.remaining.compareTo(b.remaining);
          if (remainingCompare != 0) {
            return remainingCompare;
          }
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        return categories;
    }
  }

  double _monthlyBudgetFromRange(double rangeBudget) {
    switch (widget.timeRange) {
      case _FinanceTimeRange.week:
        return rangeBudget * 4;
      case _FinanceTimeRange.month:
        return rangeBudget;
      case _FinanceTimeRange.year:
        return rangeBudget / 12;
    }
  }

  double _monthlyBudgetForCard(_BudgetCardInfo info) {
    if (info.isTotal) {
      return _totalMonthlyBudget;
    }
    final custom = _customMonthlyBudgets[info.title];
    if (custom != null) {
      return custom;
    }
    return _monthlyBudgetFromRange(info.allocated);
  }

  List<_CategoryPeriodPoint> _historyPointsFor(_BudgetCardInfo info) {
    final transactions = context.read<FinanceProvider>().transactions;
    final points = <_CategoryPeriodPoint>[];
    final now = DateTime.now();

    for (var offset = -5; offset <= 0; offset++) {
      final base = DateTime(now.year, now.month + offset, 1);
      final start = DateTime(base.year, base.month, 1);
      final end = DateTime(base.year, base.month + 1, 1);
      final amount = transactions
          .where((tx) {
            final inRange =
                !tx.createdAt.isBefore(start) && tx.createdAt.isBefore(end);
            if (!inRange || tx.type != TransactionType.expense) {
              return false;
            }
            if (info.isTotal) {
              return true;
            }
            return tx.category.toLowerCase() == info.title.toLowerCase();
          })
          .fold(0.0, (sum, tx) => sum + tx.amount);

      final label = base.month == 1
          ? '${base.month}/${base.year}'
          : '${base.month}';
      points.add(
        _CategoryPeriodPoint(
          label: label,
          amount: amount,
          start: start,
          end: end,
        ),
      );
    }

    return points;
  }

  double _averageForPoints(List<_CategoryPeriodPoint> points) {
    final nonZero = points.where((item) => item.amount > 0).toList();
    if (nonZero.isEmpty) {
      return 0;
    }
    return nonZero.fold(0.0, (sum, item) => sum + item.amount) / nonZero.length;
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reloadOverviewData() async {
    if (_processingAction) {
      return;
    }

    await _mutateBudget(info: _totalCard, delete: false, successMessage: '');
  }

  Future<void> _handleCreateBudget() async {
    if (_processingAction) {
      return;
    }

    await widget.onCreateBudget();
    if (!mounted) {
      return;
    }

    await _reloadOverviewData();
  }

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<_BudgetSortOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F6FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Sắp xếp ngân sách',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: FinanceColors.textStrong,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 36),
                        color: const Color(0xFF3D3D45),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FinanceColors.border),
                  ),
                  child: Column(
                    children: [
                      _BudgetSortChoiceTile(
                        icon: Icons.sort_by_alpha_rounded,
                        title: 'Theo tên A-Z',
                        selected: _sortOption == _BudgetSortOption.byName,
                        onTap: () =>
                            Navigator.pop(ctx, _BudgetSortOption.byName),
                      ),
                      const Divider(height: 1, color: Color(0xFFEAE6EE)),
                      _BudgetSortChoiceTile(
                        icon: Icons.category_outlined,
                        title: 'Theo trạng thái',
                        selected: _sortOption == _BudgetSortOption.byStatus,
                        onTap: () =>
                            Navigator.pop(ctx, _BudgetSortOption.byStatus),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == _sortOption) {
      return;
    }

    setState(() {
      _sortOption = selected;
    });
  }

  Future<void> _showBudgetMenu(_BudgetCardInfo info) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F6FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Tùy chỉnh',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF303038),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 40),
                        color: const Color(0xFF33333B),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: FinanceColors.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text(
                          'Chỉnh sửa ngân sách',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, 'edit'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_outline_rounded),
                        title: const Text(
                          'Xóa ngân sách',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, 'delete'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'edit') {
      await _openEditBudget(info);
      return;
    }

    if (action == 'delete') {
      await _confirmDeleteBudget(info);
    }
  }

  Future<void> _openEditBudget(_BudgetCardInfo info) async {
    final points = _historyPointsFor(info);
    final average = _averageForPoints(points);
    final initialMonthlyBudget = _monthlyBudgetForCard(info);

    final result = await Navigator.of(context).push<_BudgetEditResult>(
      MaterialPageRoute<_BudgetEditResult>(
        builder: (_) => _BudgetEditScreen(
          title: info.isTotal ? 'Tổng chi tiêu trong tháng' : info.title,
          icon: info.icon,
          iconColor: info.accentColor,
          initialMonthlyBudget: initialMonthlyBudget,
          hideAmounts: widget.hideAmounts,
          points: points,
          average: average,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    if (result.deleteRequested) {
      await _mutateBudget(
        info: info,
        delete: true,
        successMessage: 'Đã xóa ngân sách.',
      );
      return;
    }

    if ((result.monthlyBudget - initialMonthlyBudget).abs() < 1) {
      return;
    }

    await _mutateBudget(
      info: info,
      monthlyBudget: result.monthlyBudget,
      delete: false,
      successMessage: 'Cập nhật ngân sách thành công.',
    );
  }

  Future<void> _confirmDeleteBudget(_BudgetCardInfo info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xác nhận xóa ngân sách',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2E2E36),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bạn có thể điều chỉnh hạn mức thay vì xóa nó, nếu kế hoạch chi tiêu này không khả thi.',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.33,
                    color: Color(0xFF4B4B54),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: TextButton.styleFrom(
                          foregroundColor: FinanceColors.accentPrimary,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: FinanceColors.accentPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Xóa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _mutateBudget(
      info: info,
      delete: true,
      successMessage: 'Đã xóa ngân sách.',
    );
  }

  Future<void> _mutateBudget({
    required _BudgetCardInfo info,
    double? monthlyBudget,
    required bool delete,
    required String successMessage,
  }) async {
    if (_processingAction) {
      return;
    }

    setState(() {
      _processingAction = true;
    });

    try {
      final data = await widget.onMutateBudget(
        info: info,
        monthlyBudget: monthlyBudget,
        delete: delete,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _cards = List<_BudgetCardInfo>.from(data.cards);
        _periodBudget = data.periodBudget;
        _periodLabel = data.periodLabel;
        _periodStart = data.periodStart;
        _periodEnd = data.periodEnd;
        _totalMonthlyBudget = data.totalMonthlyBudget;
        _customMonthlyBudgets = Map<String, double>.from(
          data.customMonthlyBudgets,
        );
      });

      if (successMessage.isNotEmpty) {
        _showHint(successMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingAction = false;
        });
      }
    }
  }

  Future<void> _showTotalMenu() async {
    await _showBudgetMenu(_totalCard);
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalCard;
    final categories = _sortedCategories();
    final hasConfiguredBudget = total.allocated > 0;
    final overBudget = hasConfiguredBudget && total.isOverBudget;

    return Scaffold(
      backgroundColor: FinanceColors.background,
      appBar: AppBar(
        backgroundColor: FinanceColors.appBarTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Ngân sách',
          style: TextStyle(
            color: FinanceColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: FinanceColors.textPrimary),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: FinanceColors.surface,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headerPeriodLabel(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF303038),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chi ${_remainingDaysInMonth()} ngày tới',
                      style: const TextStyle(
                        color: FinanceColors.textSecondary,
                        fontSize: 18 / 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              FinanceOutlineActionButton(
                label: 'Thêm mới',
                icon: Icons.add_rounded,
                onPressed: _processingAction ? null : _handleCreateBudget,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ngân sách tổng',
                        style: TextStyle(
                          fontSize: 24 / 1.2,
                          fontWeight: FontWeight.w900,
                          color: FinanceColors.textStrong,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: !hasConfiguredBudget
                            ? const Color(0xFFF1F2F5)
                            : overBudget
                            ? const Color(0xFFFFF1EA)
                            : const Color(0xFFEAF8EF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !hasConfiguredBudget
                                ? Icons.pending_outlined
                                : overBudget
                                ? Icons.local_fire_department_rounded
                                : Icons.verified_user_rounded,
                            size: 16,
                            color: !hasConfiguredBudget
                                ? const Color(0xFF5E5E67)
                                : overBudget
                                ? const Color(0xFFFF6A2A)
                                : const Color(0xFF18A957),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            !hasConfiguredBudget
                                ? 'Chưa đặt'
                                : overBudget
                                ? 'Đã vượt'
                                : 'Tốt',
                            style: TextStyle(
                              color: !hasConfiguredBudget
                                  ? const Color(0xFF5E5E67)
                                  : overBudget
                                  ? const Color(0xFFFF6A2A)
                                  : const Color(0xFF18A957),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _processingAction ? null : _showTotalMenu,
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: FinanceColors.textStrong,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _BudgetHalfGauge(
                  ratio: total.safeRatio,
                  color: !hasConfiguredBudget
                      ? const Color(0xFF9A9AA4)
                      : overBudget
                      ? const Color(0xFFFF6A2A)
                      : const Color(0xFF1BB7B8),
                ),
                const SizedBox(height: 4),
                Text(
                  !hasConfiguredBudget
                      ? 'Chưa thiết lập'
                      : overBudget
                      ? 'Đã vượt'
                      : 'Còn lại',
                  style: const TextStyle(
                    color: Color(0xFF6F6F78),
                    fontSize: 22 / 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(hasConfiguredBudget ? total.remaining.abs() : 0),
                  style: TextStyle(
                    color: !hasConfiguredBudget
                        ? const Color(0xFF7B7B85)
                        : overBudget
                        ? const Color(0xFFFF5B27)
                        : const Color(0xFF1BB7B8),
                    fontSize: 42 / 1.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F4F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Đã chi',
                              style: TextStyle(color: Color(0xFF6D6D76)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _money(total.spent),
                              style: const TextStyle(
                                fontSize: 18 / 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 54,
                        color: const Color(0xFFD9D7DF),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Ngân sách',
                              style: TextStyle(color: Color(0xFF6D6D76)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _money(
                                total.allocated > 0
                                    ? total.allocated
                                    : _periodBudget,
                              ),
                              style: const TextStyle(
                                fontSize: 18 / 1.1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FinanceSectionHeader(
            title: 'Danh mục',
            trailing: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _openSortSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sortLabel(),
                      style: const TextStyle(
                        fontSize: 20 / 1.2,
                        fontWeight: FontWeight.w700,
                        color: FinanceColors.textStrong,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.tune_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (categories.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FinanceColors.border),
              ),
              child: const Text(
                'Chưa có danh mục ngân sách. Nhấn "Thêm mới" để tạo hạn mức đầu tiên.',
                style: TextStyle(
                  color: Color(0xFF5F5F69),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...categories.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BudgetCategoryListTile(
                  info: item,
                  hideAmounts: widget.hideAmounts,
                  onTap: () => widget.onOpenCategory(item),
                  onMenuTap: _processingAction
                      ? null
                      : () => _showBudgetMenu(item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetHalfGauge extends StatelessWidget {
  const _BudgetHalfGauge({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(
        painter: _BudgetHalfGaugePainter(ratio: ratio, color: color),
      ),
    );
  }
}

class _BudgetHalfGaugePainter extends CustomPainter {
  const _BudgetHalfGaugePainter({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 26.0;
    final radius = math.min(size.width * 0.42, size.height - stroke / 2);
    final center = Offset(size.width / 2, size.height);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFEAE8EF);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    final safe = ratio.clamp(0.0, 1.0).toDouble();

    canvas.drawArc(rect, math.pi, math.pi, false, track);
    if (safe > 0) {
      canvas.drawArc(rect, math.pi, math.pi * safe, false, progress);
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetHalfGaugePainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.color != color;
  }
}

class _BudgetCategoryListTile extends StatelessWidget {
  const _BudgetCategoryListTile({
    required this.info,
    required this.hideAmounts,
    required this.onTap,
    this.onMenuTap,
  });

  final _BudgetCardInfo info;
  final bool hideAmounts;
  final VoidCallback onTap;
  final VoidCallback? onMenuTap;

  String _money(double value) {
    if (hideAmounts) {
      return '******';
    }
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  @override
  Widget build(BuildContext context) {
    final overBudget = info.isOverBudget;
    final stateBg = overBudget
        ? const Color(0xFFFFF1EA)
        : const Color(0xFFEAF8EF);
    final stateColor = overBudget
        ? const Color(0xFFFF6A2A)
        : const Color(0xFF18A957);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: info.accentColor, width: 8),
                ),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF4FAFA),
                  ),
                  child: Icon(info.icon, size: 30, color: info.accentColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            info.title,
                            style: const TextStyle(
                              fontSize: 36 / 1.6,
                              fontWeight: FontWeight.w800,
                              color: FinanceColors.textStrong,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onMenuTap,
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: Color(0xFF303038),
                          ),
                          splashRadius: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hạn mức: ${_money(info.allocated)}',
                      style: const TextStyle(
                        color: Color(0xFF6D6D76),
                        fontSize: 20 / 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            overBudget
                                ? 'Vượt ${_money(info.remaining.abs())}'
                                : 'Còn lại ${_money(info.remaining)}',
                            style: TextStyle(
                              color: overBudget
                                  ? const Color(0xFFFF5B27)
                                  : const Color(0xFF18AFAE),
                              fontSize: 22 / 1.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: stateBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                overBudget
                                    ? Icons.local_fire_department_rounded
                                    : Icons.verified_user_rounded,
                                size: 16,
                                color: stateColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                overBudget ? 'Đã vượt' : 'Tốt',
                                style: TextStyle(
                                  color: stateColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCreateResult {
  const _BudgetCreateResult({
    required this.category,
    required this.monthlyBudget,
  });

  final String category;
  final double monthlyBudget;
}

class _BudgetCreateSuggestion {
  const _BudgetCreateSuggestion({required this.category, required this.amount});

  final String category;
  final double amount;
}

class _BudgetCreateScreen extends StatefulWidget {
  const _BudgetCreateScreen({
    required this.categories,
    required this.existingCategories,
    required this.transactions,
    required this.iconForCategory,
  });

  final List<String> categories;
  final Set<String> existingCategories;
  final List<FinanceTransaction> transactions;
  final IconData Function(String category) iconForCategory;

  @override
  State<_BudgetCreateScreen> createState() => _BudgetCreateScreenState();
}

class _BudgetCreateScreenState extends State<_BudgetCreateScreen> {
  static const String _totalBudgetCategory = 'Tổng chi tiêu trong tháng';

  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;
  int _selectedHistoryIndex = -1;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double _parseAmount(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return 0;
    }
    return double.tryParse(digits) ?? 0;
  }

  String _money(double value) {
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  String _inputMoney(double value) {
    if (value <= 0) {
      return '0';
    }
    return Formatters.currency(value)
        .replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '')
        .replaceAll('đ', '')
        .trim();
  }

  double _normalizedSuggestion(double value) {
    if (value <= 0) {
      return 0;
    }
    return ((value / 1000).round() * 1000).toDouble();
  }

  Map<String, double> _averageMonthlyByCategory() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5, 1);
    final sums = <String, double>{};

    for (final tx in widget.transactions) {
      if (tx.type != TransactionType.expense) {
        continue;
      }
      if (tx.createdAt.isBefore(start)) {
        continue;
      }
      sums[tx.category] = (sums[tx.category] ?? 0) + tx.amount;
    }

    return sums.map((key, value) => MapEntry(key, value / 6));
  }

  double _averageMonthlyTotalExpense() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 5, 1);

    final total = widget.transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              !tx.createdAt.isBefore(start),
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return total / 6;
  }

  double _suggestionFor(String category) {
    if (category == _totalBudgetCategory) {
      final totalAvg = _averageMonthlyTotalExpense();
      if (totalAvg > 0) {
        return _normalizedSuggestion(totalAvg);
      }
      return 1000000;
    }

    final avg = _averageMonthlyByCategory()[category] ?? 0;
    if (avg > 0) {
      return _normalizedSuggestion(avg);
    }
    if (category == 'Hóa đơn' || category == 'Ăn uống') {
      return 1000000;
    }
    return 0;
  }

  List<_BudgetCreateSuggestion> _recommendations() {
    final averages = _averageMonthlyByCategory();
    final available = widget.categories
        .where((item) => !widget.existingCategories.contains(item))
        .toList();

    final prioritized = <_BudgetCreateSuggestion>[];
    if (available.contains(_totalBudgetCategory)) {
      prioritized.add(
        _BudgetCreateSuggestion(
          category: _totalBudgetCategory,
          amount: _suggestionFor(_totalBudgetCategory),
        ),
      );
    }

    final items =
        available
            .where((category) => category != _totalBudgetCategory)
            .map(
              (category) => _BudgetCreateSuggestion(
                category: category,
                amount: _normalizedSuggestion(averages[category] ?? 0),
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    if (items.where((item) => item.amount > 0).isNotEmpty) {
      final nonZero = items.where((item) => item.amount > 0).toList();
      final maxOthers = prioritized.isEmpty ? 2 : 1;
      return [...prioritized, ...nonZero.take(maxOthers)].take(2).toList();
    }

    final fallback = <_BudgetCreateSuggestion>[...prioritized];
    for (final category in ['Hóa đơn', 'Ăn uống']) {
      if (fallback.length >= 2) {
        break;
      }
      if (available.contains(category) && category != _totalBudgetCategory) {
        fallback.add(
          _BudgetCreateSuggestion(category: category, amount: 1000000),
        );
      }
    }
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return items.take(2).toList();
  }

  List<_CategoryPeriodPoint> _historyPoints(String category) {
    final points = <_CategoryPeriodPoint>[];
    final now = DateTime.now();
    for (var offset = -5; offset <= 0; offset++) {
      final base = DateTime(now.year, now.month + offset, 1);
      final start = DateTime(base.year, base.month, 1);
      final end = DateTime(base.year, base.month + 1, 1);
      final amount = widget.transactions
          .where(
            (tx) =>
                tx.type == TransactionType.expense &&
                (category == _totalBudgetCategory || tx.category == category) &&
                !tx.createdAt.isBefore(start) &&
                tx.createdAt.isBefore(end),
          )
          .fold(0.0, (sum, tx) => sum + tx.amount);
      final label = base.month == 1
          ? '${base.month}/${base.year}'
          : '${base.month}';
      points.add(
        _CategoryPeriodPoint(
          label: label,
          amount: amount,
          start: start,
          end: end,
        ),
      );
    }
    return points;
  }

  void _selectCategory(String category) {
    if (widget.existingCategories.contains(category)) {
      return;
    }
    final suggestion = _suggestionFor(category);
    final formatted = _inputMoney(suggestion);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {
      _selectedCategory = category;
      _selectedHistoryIndex = 5;
    });
  }

  void _applyAmountSuggestion(double amount) {
    final formatted = _inputMoney(amount);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  void _handleAmountChanged(String raw) {
    final amount = _parseAmount(raw);
    final formatted = _inputMoney(amount);
    if (formatted != raw) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  void _onBack() {
    if (_selectedCategory != null) {
      setState(() {
        _selectedCategory = null;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  Widget _buildCategoryList() {
    final recommendations = _recommendations();
    final recommendationNames = recommendations
        .map((item) => item.category)
        .toSet();
    final others = widget.categories
        .where((item) => !recommendationNames.contains(item))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      children: [
        if (recommendations.isNotEmpty) ...[
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: Color(0xFFF557BF)),
              SizedBox(width: 8),
              Text(
                'Đề xuất',
                style: TextStyle(
                  fontSize: 38 / 1.5,
                  fontWeight: FontWeight.w900,
                  color: FinanceColors.textStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Đề xuất dựa trên chi tiêu trung bình của bạn',
            style: TextStyle(color: Color(0xFF505059), fontSize: 30 / 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEBC9F1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: List.generate(recommendations.length, (index) {
                final item = recommendations[index];
                return _BudgetCreateCategoryRow(
                  icon: widget.iconForCategory(item.category),
                  title: item.category,
                  subtitle: 'Đề xuất ${_money(item.amount)}',
                  showDivider: index != recommendations.length - 1,
                  onTap: () => _selectCategory(item.category),
                );
              }),
            ),
          ),
          const SizedBox(height: 18),
        ],
        const Text(
          'Chọn danh mục khác',
          style: TextStyle(
            fontSize: 42 / 1.55,
            fontWeight: FontWeight.w900,
            color: FinanceColors.textStrong,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Column(
            children: List.generate(others.length, (index) {
              final category = others[index];
              final created = widget.existingCategories.contains(category);
              return _BudgetCreateCategoryRow(
                icon: widget.iconForCategory(category),
                title: category,
                disabled: created,
                created: created,
                showDivider: index != others.length - 1,
                onTap: created ? null : () => _selectCategory(category),
              );
            }),
          ),
        ),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 34),
          label: const Text(
            'Thêm danh mục',
            style: TextStyle(fontSize: 38 / 1.6, fontWeight: FontWeight.w900),
          ),
          style: TextButton.styleFrom(
            foregroundColor: FinanceColors.accentPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetForm() {
    final category = _selectedCategory!;
    final amount = _parseAmount(_amountController.text);
    final canSubmit = amount > 0;
    final points = _historyPoints(category);
    final selectedHistoryIndex = points.isEmpty
        ? -1
        : (_selectedHistoryIndex >= 0 && _selectedHistoryIndex < points.length
              ? _selectedHistoryIndex
              : points.length - 1);
    final avgSource = points
        .take(points.length - 1)
        .where((item) => item.amount > 0);
    final average = avgSource.isEmpty
        ? 0.0
        : avgSource.fold(0.0, (sum, item) => sum + item.amount) /
              avgSource.length;
    final trendTitle = category == _totalBudgetCategory
        ? 'Xu hướng tổng chi tiêu 6 tháng gần đây'
        : 'Xu hướng chi tiêu $category 6 tháng gần đây';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FinanceColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            widget.iconForCategory(category),
                            size: 42,
                            color: const Color(0xFF8E8ED4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Danh mục',
                                style: TextStyle(
                                  color: Color(0xFF6B6B73),
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                category,
                                style: const TextStyle(
                                  color: Color(0xFF2E2E36),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      onChanged: _handleAmountChanged,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D2D35),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Ngân sách chi tiêu trong tháng*',
                        labelStyle: const TextStyle(fontSize: 16),
                        suffixText: 'đ',
                        suffixStyle: const TextStyle(
                          color: Color(0xFF2D2D35),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0DDE8),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0DDE8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF3D3D44),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 26,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          'Tham khảo thống kê chi tiêu của bạn',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: FinanceColors.textStrong,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _CategoryHistoryChart(
                points: points,
                average: average,
                hideAmounts: false,
                highlightColor: const Color(0xFF9FC3E7),
                caption:
                    'Trung bình 5 tháng gần nhất, chỉ tính tháng có chi tiêu',
                selectedIndex: selectedHistoryIndex,
                onSelectIndex: (index) {
                  if (index == _selectedHistoryIndex) {
                    return;
                  }
                  setState(() {
                    _selectedHistoryIndex = index;
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(
                trendTitle,
                style: const TextStyle(
                  fontSize: 18,
                  color: FinanceColors.textStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        FinanceBottomBarSurface(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showMobileKeyboardMoneySuggestions(context))
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE3E1EA)),
                      ),
                      child: FinanceMoneySuggestionChips(
                        suggestions: const [100000, 1000000, 10000000],
                        onSelected: _applyAmountSuggestion,
                        topPadding: 0,
                        expanded: true,
                      ),
                    ),
                  if (_showMobileKeyboardMoneySuggestions(context))
                    const SizedBox(height: 10),
                  FinancePrimaryActionButton(
                    label: 'Tạo ngân sách',
                    height: 54,
                    borderRadius: 14,
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                    disabledBackgroundColor: const Color(0xFFE7E7EC),
                    disabledForegroundColor: const Color(0xFFBCBCC4),
                    onPressed: canSubmit
                        ? () {
                            Navigator.of(context).pop(
                              _BudgetCreateResult(
                                category: category,
                                monthlyBudget: amount,
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FinanceColors.background,
      appBar: AppBar(
        backgroundColor: FinanceColors.appBarTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        iconTheme: const IconThemeData(color: FinanceColors.textPrimary),
        title: const Text(
          'Tạo ngân sách',
          style: TextStyle(
            color: FinanceColors.textPrimary,
            fontWeight: FontWeight.w900,
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
      body: _selectedCategory == null
          ? _buildCategoryList()
          : _buildBudgetForm(),
    );
  }
}

class _BudgetCreateCategoryRow extends StatelessWidget {
  const _BudgetCreateCategoryRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.disabled = false,
    this.created = false,
    this.showDivider = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool disabled;
  final bool created;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(
                    bottom: BorderSide(color: Color(0xFFE9E6EF), width: 1),
                  )
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Icon(
                  icon,
                  size: 36,
                  color: disabled
                      ? const Color(0xFFD9D9E0)
                      : const Color(0xFF65A8E6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 40 / 1.6,
                        fontWeight: FontWeight.w800,
                        color: disabled
                            ? const Color(0xFFC8C8D0)
                            : FinanceColors.textStrong,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF66666E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (created)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Đã tạo ngân sách',
                    style: TextStyle(
                      color: Color(0xFF47474F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 30,
                  color: disabled
                      ? const Color(0xFFC8C8D0)
                      : const Color(0xFF33333B),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCategoryScreen extends StatefulWidget {
  const _BudgetCategoryScreen({
    required this.info,
    required this.periodLabel,
    required this.hideAmounts,
    required this.initialAnchorDate,
    required this.initialRange,
    this.initialSuccessMessage,
  });

  final _BudgetCardInfo info;
  final String periodLabel;
  final bool hideAmounts;
  final DateTime initialAnchorDate;
  final _FinanceTimeRange initialRange;
  final String? initialSuccessMessage;

  @override
  State<_BudgetCategoryScreen> createState() => _BudgetCategoryScreenState();
}

class _BudgetCategoryScreenState extends State<_BudgetCategoryScreen> {
  late bool _monthMode;
  late DateTime _anchorDate;
  _DetailTxnTab _txnTab = _DetailTxnTab.all;
  String? _successMessage;
  int _selectedHistoryIndex = 5;

  @override
  void initState() {
    super.initState();
    _anchorDate = DateTime(
      widget.initialAnchorDate.year,
      widget.initialAnchorDate.month,
      widget.initialAnchorDate.day,
    );
    _monthMode = widget.initialRange != _FinanceTimeRange.week;
    _successMessage = widget.initialSuccessMessage;
    _scheduleSuccessDismiss();
  }

  void _scheduleSuccessDismiss() {
    if (_successMessage == null) {
      return;
    }
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _successMessage = null;
      });
    });
  }

  String _money(double value) {
    if (widget.hideAmounts) {
      return '******';
    }
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  DateTime _weekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  _FinanceRangeWindow _activeRange() {
    if (_monthMode) {
      return _FinanceRangeWindow(
        start: DateTime(_anchorDate.year, _anchorDate.month, 1),
        end: DateTime(_anchorDate.year, _anchorDate.month + 1, 1),
      );
    }
    final start = _weekStart(_anchorDate);
    return _FinanceRangeWindow(
      start: start,
      end: start.add(const Duration(days: 7)),
    );
  }

  _FinanceRangeWindow _monthRange() {
    return _FinanceRangeWindow(
      start: DateTime(_anchorDate.year, _anchorDate.month, 1),
      end: DateTime(_anchorDate.year, _anchorDate.month + 1, 1),
    );
  }

  int _remainingDaysInMonth(DateTime monthDate) {
    final monthStart = DateTime(monthDate.year, monthDate.month, 1);
    final monthDays = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final now = DateTime.now();

    if (monthStart.year == now.year && monthStart.month == now.month) {
      return (monthDays - now.day).clamp(0, monthDays).toInt();
    }

    final selectedMonth = DateTime(monthStart.year, monthStart.month);
    final currentMonth = DateTime(now.year, now.month);
    if (selectedMonth.isAfter(currentMonth)) {
      return monthDays;
    }
    return 0;
  }

  String _periodTitle(_FinanceRangeWindow range) {
    final prefix = widget.info.type == TransactionType.income
        ? 'Thu nhập'
        : 'Chi tiêu';
    if (_monthMode) {
      return '$prefix tháng ${range.start.month}';
    }
    final start = range.start;
    final end = range.end.subtract(const Duration(days: 1));
    return '$prefix tuần ${start.day}/${start.month} - ${end.day}/${end.month}';
  }

  String _expenseParentForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('hóa đơn') ||
        lower.contains('hoa don') ||
        lower.contains('điện') ||
        lower.contains('nước') ||
        lower.contains('nhà') ||
        lower.contains('cố định')) {
      return 'Chi phí cố định';
    }
    return 'Chi phí phát sinh';
  }

  bool _matchesCategory(FinanceTransaction tx) {
    if (tx.type != widget.info.type) {
      return false;
    }

    if (widget.info.isTotal) {
      return true;
    }

    final selected = widget.info.title.toLowerCase();
    final current = tx.category.toLowerCase();

    if (widget.info.type == TransactionType.expense &&
        (selected == 'chi phí cố định' || selected == 'chi phí phát sinh')) {
      return _expenseParentForCategory(tx.category).toLowerCase() == selected;
    }

    return current == selected;
  }

  List<FinanceTransaction> _periodTransactions(
    FinanceProvider provider,
    _FinanceRangeWindow range,
  ) {
    return provider.transactions.where((tx) {
      final inRange =
          !tx.createdAt.isBefore(range.start) &&
          tx.createdAt.isBefore(range.end);
      return inRange && _matchesCategory(tx);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int _historyIndex(List<_CategoryPeriodPoint> points) {
    if (points.isEmpty) {
      return 0;
    }
    return _selectedHistoryIndex.clamp(0, points.length - 1).toInt();
  }

  _FinanceRangeWindow _rangeFromHistory(List<_CategoryPeriodPoint> points) {
    if (points.isEmpty) {
      return _activeRange();
    }
    final selected = points[_historyIndex(points)];
    return _FinanceRangeWindow(start: selected.start, end: selected.end);
  }

  double _sumInRange(FinanceProvider provider, _FinanceRangeWindow range) {
    return provider.transactions
        .where((tx) {
          final inRange =
              !tx.createdAt.isBefore(range.start) &&
              tx.createdAt.isBefore(range.end);
          return inRange && _matchesCategory(tx);
        })
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  List<_CategoryPeriodPoint> _historyPoints(FinanceProvider provider) {
    final points = <_CategoryPeriodPoint>[];
    if (_monthMode) {
      for (var offset = -5; offset <= 0; offset++) {
        final base = DateTime(_anchorDate.year, _anchorDate.month + offset, 1);
        final start = DateTime(base.year, base.month, 1);
        final end = DateTime(base.year, base.month + 1, 1);
        final amount = _sumInRange(
          provider,
          _FinanceRangeWindow(start: start, end: end),
        );
        final label = base.month == 1
            ? '${base.month}/${base.year}'
            : '${base.month}';
        points.add(
          _CategoryPeriodPoint(
            label: label,
            amount: amount,
            start: start,
            end: end,
          ),
        );
      }
      return points;
    }

    final currentStart = _weekStart(_anchorDate);
    for (var offset = -5; offset <= 0; offset++) {
      final start = currentStart.add(Duration(days: offset * 7));
      final end = start.add(const Duration(days: 7));
      final amount = _sumInRange(
        provider,
        _FinanceRangeWindow(start: start, end: end),
      );
      final endDay = end.subtract(const Duration(days: 1));
      final label = offset == 0
          ? '${start.day}/${start.month} - ${endDay.day}/${endDay.month}'
          : '${start.day} - ${endDay.day}';
      points.add(
        _CategoryPeriodPoint(
          label: label,
          amount: amount,
          start: start,
          end: end,
        ),
      );
    }
    return points;
  }

  List<_TopReceiverAggregate> _topReceivers(
    List<FinanceTransaction> transactions,
  ) {
    final map = <String, _TopReceiverAggregate>{};
    for (final tx in transactions) {
      final current = map[tx.title];
      if (current == null) {
        map[tx.title] = _TopReceiverAggregate(
          name: tx.title,
          total: tx.amount,
          count: 1,
          icon: widget.info.icon,
        );
      } else {
        map[tx.title] = _TopReceiverAggregate(
          name: current.name,
          total: current.total + tx.amount,
          count: current.count + 1,
          icon: current.icon,
        );
      }
    }

    final rows = map.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    return rows;
  }

  Widget _buildAllTransactions(List<FinanceTransaction> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyTransactions();
    }

    final grouped = <DateTime, List<FinanceTransaction>>{};
    for (final tx in transactions) {
      final day = DateTime(
        tx.createdAt.year,
        tx.createdAt.month,
        tx.createdAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(tx);
    }

    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      children: keys.map((day) {
        final items = grouped[day]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F6FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Text(
                  '${day.day}/${day.month}/${day.year}',
                  style: const TextStyle(
                    fontSize: 20 / 1.2,
                    color: Color(0xFF46464E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...items.map(
                (tx) => Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEFEAF3), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFD),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E4EA)),
                        ),
                        child: Icon(
                          widget.info.icon,
                          color: widget.info.accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: const TextStyle(
                                fontSize: 22 / 1.2,
                                fontWeight: FontWeight.w700,
                                color: FinanceColors.textStrong,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFF4CD375),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                tx.category,
                                style: const TextStyle(
                                  color: Color(0xFF3A8D5A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.info.type == TransactionType.expense ? '-' : '+'}${_money(tx.amount)}',
                        style: TextStyle(
                          fontSize: 22 / 1.1,
                          fontWeight: FontWeight.w900,
                          color: widget.info.type == TransactionType.expense
                              ? const Color(0xFF3A3A42)
                              : const Color(0xFF18A957),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopSpending(List<FinanceTransaction> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyTransactions();
    }

    final ranked = List<FinanceTransaction>.from(transactions)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        children: List.generate(ranked.length, (index) {
          final tx = ranked[index];
          return Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              border: index == ranked.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Color(0xFFEFEAF3), width: 1),
                    ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFB0B0B8),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E4EA)),
                  ),
                  child: Icon(widget.info.icon, color: widget.info.accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(
                          fontSize: 22 / 1.2,
                          fontWeight: FontWeight.w700,
                          color: FinanceColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.dayTime(tx.createdAt),
                        style: const TextStyle(color: Color(0xFF66666F)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${widget.info.type == TransactionType.expense ? '-' : '+'}${_money(tx.amount)}',
                  style: TextStyle(
                    fontSize: 22 / 1.1,
                    fontWeight: FontWeight.w900,
                    color: widget.info.type == TransactionType.expense
                        ? const Color(0xFF3A3A42)
                        : const Color(0xFF18A957),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopReceivers(List<FinanceTransaction> transactions) {
    final rows = _topReceivers(transactions);
    if (rows.isEmpty) {
      return _buildEmptyTransactions();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          return Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              border: index == rows.length - 1
                  ? null
                  : const Border(
                      bottom: BorderSide(color: Color(0xFFEFEAF3), width: 1),
                    ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color(0xFFB0B0B8),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E4EA)),
                  ),
                  child: Icon(row.icon, color: widget.info.accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        style: const TextStyle(
                          fontSize: 22 / 1.2,
                          fontWeight: FontWeight.w700,
                          color: FinanceColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${row.count} giao dịch',
                        style: const TextStyle(color: Color(0xFF66666F)),
                      ),
                    ],
                  ),
                ),
                Text(
                  _money(row.total),
                  style: const TextStyle(
                    fontSize: 22 / 1.1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3A3A42),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FinanceColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 78, color: Color(0xFFC5CCE2)),
          SizedBox(height: 8),
          Text(
            'Không có dữ liệu',
            style: TextStyle(
              fontSize: 30 / 1.4,
              fontWeight: FontWeight.w900,
              color: Color(0xFF303038),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Bạn không có giao dịch nào tại thời gian này',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6F6F78), fontSize: 20 / 1.25),
          ),
        ],
      ),
    );
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showBudgetMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F6FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Tùy chỉnh',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF303038),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 40),
                        color: const Color(0xFF33333B),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: FinanceColors.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text(
                          'Chỉnh sửa ngân sách',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showHint('Sẽ sớm hỗ trợ chỉnh sửa ngân sách.');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_outline_rounded),
                        title: const Text(
                          'Xóa ngân sách',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showHint('Sẽ sớm hỗ trợ xóa ngân sách.');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final historyPoints = _historyPoints(provider);
    final activeRange = _rangeFromHistory(historyPoints);
    final selectedHistoryIndex = _historyIndex(historyPoints);
    final transactions = _periodTransactions(provider, activeRange);
    final totalAmount = transactions.fold(0.0, (sum, tx) => sum + tx.amount);
    final nonZeroAvg = historyPoints.where((item) => item.amount > 0).toList();
    final avgLine = nonZeroAvg.isEmpty
        ? 0.0
        : nonZeroAvg.fold(0.0, (sum, item) => sum + item.amount) /
              nonZeroAvg.length;

    final resolvedMonthlyBudget = widget.info.isTotal
        ? provider.monthlyBudget
        : widget.info.allocated;
    final hasCustomBudget =
        widget.info.type == TransactionType.expense &&
        (widget.info.isTotal
            ? resolvedMonthlyBudget > 0
            : widget.info.hasCustomBudget);
    final monthBudget = hasCustomBudget ? resolvedMonthlyBudget : 0.0;
    final allocatedBudget = _monthMode ? monthBudget : 0.0;
    final hasBudget = allocatedBudget > 0;
    final remaining = allocatedBudget - totalAmount;
    final overBudget = hasBudget && remaining < 0;
    final daysRemaining = _remainingDaysInMonth(activeRange.start);
    final monthTotalAmount = _monthMode
        ? totalAmount
        : _sumInRange(provider, _monthRange());
    final monthRemaining = monthBudget - monthTotalAmount;
    final monthOverBudget = hasCustomBudget && monthRemaining < 0;
    final showBudgetSection =
        widget.info.type == TransactionType.expense && _monthMode && hasBudget;
    final botText = monthOverBudget
        ? 'SOS Vượt ngân sách ${widget.info.title} thì làm gì?'
        : _monthMode
        ? '${_money(totalAmount)} cho ${widget.info.title} hợp lý chưa?'
        : 'Chấm điểm chi tiêu';
    final chartCaption = showBudgetSection
        ? 'Hạn mức ngân sách mỗi tháng'
        : _monthMode
        ? 'Trung bình 5 tháng gần nhất, chỉ tính tháng có ${widget.info.type == TransactionType.income ? 'thu nhập' : 'chi tiêu'}'
        : 'Trung bình 5 tuần gần nhất, chỉ tính tuần có ${widget.info.type == TransactionType.income ? 'thu nhập' : 'chi tiêu'}';

    return Scaffold(
      backgroundColor: FinanceColors.background,
      appBar: AppBar(
        backgroundColor: FinanceColors.appBarTint,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.info.title,
          style: const TextStyle(
            color: FinanceColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: FinanceColors.textPrimary),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline_rounded),
          ),
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
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _periodTitle(activeRange),
                            style: const TextStyle(
                              fontSize: 40 / 1.55,
                              fontWeight: FontWeight.w900,
                              color: FinanceColors.textStrong,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF0F3),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: FinanceColors.borderSoft),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() {
                            _monthMode = false;
                            _selectedHistoryIndex = 5;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 84,
                            height: 38,
                            decoration: BoxDecoration(
                              color: !_monthMode
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: !_monthMode
                                  ? Border.all(color: FinanceColors.borderSoft)
                                  : null,
                              boxShadow: !_monthMode
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x18000000),
                                        blurRadius: 9,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Tuần',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: !_monthMode
                                      ? FinanceColors.accentPrimary
                                      : FinanceColors.textStrong,
                                  fontWeight: !_monthMode
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() {
                            _monthMode = true;
                            _selectedHistoryIndex = 5;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 84,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _monthMode
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: _monthMode
                                  ? Border.all(color: FinanceColors.borderSoft)
                                  : null,
                              boxShadow: _monthMode
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x18000000),
                                        blurRadius: 9,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Tháng',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _monthMode
                                      ? FinanceColors.accentPrimary
                                      : FinanceColors.textStrong,
                                  fontWeight: _monthMode
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CategoryHistoryChart(
                points: historyPoints,
                average: avgLine,
                selectedIndex: selectedHistoryIndex,
                onSelectIndex: (index) {
                  if (index == selectedHistoryIndex) {
                    return;
                  }
                  setState(() {
                    _selectedHistoryIndex = index;
                  });
                },
                hideAmounts: widget.hideAmounts,
                highlightColor: widget.info.type == TransactionType.income
                    ? const Color(0xFFF6B348)
                    : const Color(0xFF1A84F6),
                referenceLineValue: showBudgetSection
                    ? allocatedBudget
                    : avgLine,
                referenceLineColor: showBudgetSection
                    ? const Color(0xFF14A9AD)
                    : FinanceColors.accentPrimary,
                caption: chartCaption,
              ),
              const SizedBox(height: 14),
              if (showBudgetSection)
                FinanceSectionHeader(
                  title: 'Ngân sách',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: overBudget
                              ? const Color(0xFFFFF1EA)
                              : const Color(0xFFEAF8EF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              overBudget
                                  ? Icons.local_fire_department_rounded
                                  : Icons.verified_user_rounded,
                              size: 16,
                              color: overBudget
                                  ? const Color(0xFFFF6A2A)
                                  : const Color(0xFF18A957),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              overBudget ? 'Đã vượt' : 'Tốt',
                              style: TextStyle(
                                color: overBudget
                                    ? const Color(0xFFFF6A2A)
                                    : const Color(0xFF18A957),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _showBudgetMenu,
                        borderRadius: BorderRadius.circular(999),
                        child: Ink(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDF7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            color: FinanceColors.accentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const FinanceSectionHeader(title: 'Tóm tắt'),
              const SizedBox(height: 10),
              if (showBudgetSection)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: FinanceColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: overBudget
                                ? const Color(0xFFE8E8EE)
                                : widget.info.accentColor,
                            width: 8,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(11),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F8FB),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.info.icon,
                            color: overBudget
                                ? const Color(0xFFC5C5CE)
                                : widget.info.accentColor,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã chi ${_money(totalAmount)}',
                              style: const TextStyle(
                                color: Color(0xFF3A3A42),
                                fontSize: 38 / 1.65,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Color(0xFF66666F),
                                  fontSize: 22 / 1.2,
                                ),
                                children: [
                                  TextSpan(
                                    text: overBudget
                                        ? 'Vượt ${_money(remaining.abs())}'
                                        : 'Còn ${_money(remaining)}',
                                    style: TextStyle(
                                      color: overBudget
                                          ? const Color(0xFFFF5B27)
                                          : const Color(0xFF18AFAE),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' - Chi $daysRemaining ngày tới',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: FinanceColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.info.type == TransactionType.income
                                ? 'Đã thu'
                                : 'Đã chi',
                            style: const TextStyle(
                              color: Color(0xFF6B6B73),
                              fontSize: 22 / 1.2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _money(totalAmount),
                            style: const TextStyle(
                              fontSize: 36 / 1.4,
                              fontWeight: FontWeight.w900,
                              color: FinanceColors.textStrong,
                            ),
                          ),
                        ],
                      ),
                      if (widget.info.type == TransactionType.expense &&
                          _monthMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.savings_outlined,
                                color: Color(0xFFB2B2BA),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Chưa có ngân sách',
                                style: TextStyle(
                                  color: Color(0xFFB2B2BA),
                                  fontSize: 22 / 1.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  'Đặt ngay',
                                  style: TextStyle(
                                    color: FinanceColors.accentPrimary,
                                    fontSize: 32 / 1.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: FinanceColors.accentPrimary,
                              ),
                            ],
                          ),
                        )
                      else if (widget.info.type == TransactionType.income)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text(
                                '${transactions.length} giao dịch',
                                style: const TextStyle(
                                  color: Color(0xFF6F6F78),
                                  fontSize: 22 / 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD9E8FA)),
                ),
                child: Text(
                  botText,
                  style: const TextStyle(
                    color: Color(0xFF33333B),
                    fontSize: 22 / 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const FinanceSectionHeader(title: 'Giao dịch'),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _BudgetTxnFilterChip(
                      icon: Icons.receipt_long_outlined,
                      label: 'Tất cả',
                      active: _txnTab == _DetailTxnTab.all,
                      onTap: () => setState(() => _txnTab = _DetailTxnTab.all),
                    ),
                    const SizedBox(width: 8),
                    _BudgetTxnFilterChip(
                      icon: Icons.bar_chart_rounded,
                      label: 'Top chi tiêu',
                      active: _txnTab == _DetailTxnTab.topSpending,
                      onTap: () =>
                          setState(() => _txnTab = _DetailTxnTab.topSpending),
                    ),
                    const SizedBox(width: 8),
                    _BudgetTxnFilterChip(
                      icon: Icons.account_circle_outlined,
                      label: 'Top người nhận',
                      active: _txnTab == _DetailTxnTab.topReceivers,
                      onTap: () =>
                          setState(() => _txnTab = _DetailTxnTab.topReceivers),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (_txnTab == _DetailTxnTab.all)
                _buildAllTransactions(transactions)
              else if (_txnTab == _DetailTxnTab.topSpending)
                _buildTopSpending(transactions)
              else
                _buildTopReceivers(transactions),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, -0.15),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
                    child: child,
                  ),
                ),
                child: _successMessage == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(_successMessage),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38C653),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24 / 1.25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
