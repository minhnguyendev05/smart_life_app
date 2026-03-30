import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_transaction.dart';
import '../../providers/finance_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/receipt_ocr_service.dart';
import '../../utils/formatters.dart';

enum _FinanceTimeRange { week, month, year }

enum _ExpenseBreakdownTab { child, parent }

enum _DetailTxnTab { all, topSpending, topReceivers }

class _FinanceRangeWindow {
  const _FinanceRangeWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _FinanceTimeFilterResult {
  const _FinanceTimeFilterResult({
    required this.range,
    required this.year,
    required this.month,
    required this.day,
  });

  final _FinanceTimeRange range;
  final int year;
  final int month;
  final int day;
}

class _FinanceWeekOption {
  const _FinanceWeekOption({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

enum _FinanceUtilityAction {
  addTransaction,
  flowChange,
  categorize,
  categoryManager,
  recurring,
  budget,
  community,
  addDevice,
  removeHome,
  calendar,
  moni,
  intro,
  transactionLimit,
}

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

  static const List<String> _budgetSetupCategories = [
    'Hóa đơn',
    'Ăn uống',
    'Đầu tư',
    'Học tập',
    'Làm đẹp',
    'Mua sắm',
    'Người thân',
    'Nhà cửa',
    'Sức khỏe',
    'Từ thiện',
    'Tổng chi tiêu trong tháng',
    'Chợ, siêu thị',
    'Di chuyển',
    'Giải trí',
    'Khác',
  ];

  static const Color _screenBackground = Color(0xFFF4F2F8);
  static const Color _panelBackground = Colors.white;
  static const Color _borderColor = Color(0xFFE8E3EE);
  static const Color _accentPink = Color(0xFFF63FA7);

  static const List<Color> _chartPalette = [
    Color(0xFF4CCFB0),
    Color(0xFFF26A83),
    Color(0xFFF6B348),
    Color(0xFF5FB9F6),
    Color(0xFF77D1C9),
  ];

  static const List<_UtilitySheetEntry> _utilityEntries = [
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.addTransaction,
      icon: Icons.note_add_outlined,
      label: 'Nhập\ngiao dịch',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.flowChange,
      icon: Icons.show_chart_rounded,
      label: 'Biến động\nthu chi',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.categorize,
      icon: Icons.sell_outlined,
      label: 'Phân loại\ngiao dịch',
      badge: '1',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.categoryManager,
      icon: Icons.folder_open_outlined,
      label: 'Quản lý\ndanh mục',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.recurring,
      icon: Icons.event_repeat_outlined,
      label: 'Giao dịch\nđịnh kỳ',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.budget,
      icon: Icons.savings_outlined,
      label: 'Ngân sách\nchi tiêu',
      badge: '+ Xu',
      badgeWidth: 48,
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.community,
      icon: Icons.forum_outlined,
      label: 'Cộng đồng\nchi tiêu',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.addDevice,
      icon: Icons.phone_android_outlined,
      label: 'Thêm vào\nthiết bị',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.removeHome,
      icon: Icons.star_outline_rounded,
      label: 'Gỡ khỏi\ntrang chủ',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.calendar,
      icon: Icons.calendar_month_outlined,
      label: 'Lịch',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.moni,
      icon: Icons.smart_toy_outlined,
      label: 'Moni (AI)',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.intro,
      icon: Icons.menu_book_outlined,
      label: 'Giới thiệu\ntính năng',
    ),
    _UtilitySheetEntry(
      action: _FinanceUtilityAction.transactionLimit,
      icon: Icons.speed_outlined,
      label: 'Hạn mức\ngiao dịch',
    ),
  ];

  DateTime? _filterMonth;
  _FinanceTimeRange _timeRange = _FinanceTimeRange.month;
  TransactionType _focusType = TransactionType.expense;
  final _ocrService = ReceiptOcrService();
  bool _hideAmounts = false;
  bool _showCategoryDetails = true;
  bool _showTrendView = false;
  _ExpenseBreakdownTab _expenseBreakdownTab = _ExpenseBreakdownTab.child;
  final Map<String, double> _customCategoryMonthlyBudgets = {};
  final Set<String> _expandedExpenseParents = {
    'Chi phí cố định',
    'Chi phí phát sinh',
  };

  DateTime get _anchorDate {
    final now = DateTime.now();
    final anchor = _filterMonth ?? DateTime(now.year, now.month, now.day);
    return DateTime(anchor.year, anchor.month, anchor.day);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final currentRange = _resolveCurrentRange();
    final previousRange = _resolvePreviousRange(currentRange);
    final olderRange = _resolvePreviousRange(previousRange);
    final scopedTransactions = _transactionsInRange(
      source: provider.transactions,
      range: currentRange,
    );
    final monthExpense = _sumAmount(
      scopedTransactions,
      TransactionType.expense,
    );
    final monthIncome = _sumAmount(scopedTransactions, TransactionType.income);
    final previousExpense = _sumAmount(
      _transactionsInRange(
        source: provider.transactions,
        range: previousRange,
        type: TransactionType.expense,
      ),
      TransactionType.expense,
    );
    final previousIncome = _sumAmount(
      _transactionsInRange(
        source: provider.transactions,
        range: previousRange,
        type: TransactionType.income,
      ),
      TransactionType.income,
    );
    final focusCurrent = _focusType == TransactionType.expense
        ? monthExpense
        : monthIncome;
    final focusPrevious = _focusType == TransactionType.expense
        ? previousExpense
        : previousIncome;
    final focusByCategory = _amountByCategory(
      scopedTransactions,
      type: _focusType,
    );
    final categorySlices = _buildCategorySlices(focusByCategory);
    final totalCategoryAmount = categorySlices.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final trendSeries = [
      _sumAmount(
        _transactionsInRange(
          source: provider.transactions,
          range: olderRange,
          type: _focusType,
        ),
        _focusType,
      ),
      _sumAmount(
        _transactionsInRange(
          source: provider.transactions,
          range: previousRange,
          type: _focusType,
        ),
        _focusType,
      ),
      focusCurrent,
    ];
    final periodBudget = _budgetForCurrentRange(provider.monthlyBudget);
    final budgetCards = _buildBudgetCards(
      transactions: scopedTransactions,
      periodBudget: periodBudget,
    );

    return ColoredBox(
      color: _screenBackground,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 14),
            _buildSectionHeader(),
            const SizedBox(height: 10),
            _buildMonthOverviewCard(
              periodLabel: _rangeLabel(currentRange),
              expense: monthExpense,
              income: monthIncome,
              focusCurrent: focusCurrent,
              focusPrevious: focusPrevious,
              focusType: _focusType,
              categorySlices: categorySlices,
              totalCategoryAmount: totalCategoryAmount,
              trendSeries: trendSeries,
              trendCurrentLabel: _rangeLabel(currentRange),
              periodBudget: periodBudget,
            ),
            const SizedBox(height: 14),
            _buildBudgetSection(
              cards: budgetCards,
              periodBudget: periodBudget,
              periodLabel: _rangeLabel(currentRange),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildHeaderCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            }
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Quản lý chi tiêu',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool dense = false,
  }) {
    final size = dense ? 34.0 : 42.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _panelBackground,
            shape: BoxShape.circle,
            border: Border.all(color: _borderColor),
          ),
          child: Icon(
            icon,
            size: dense ? 18 : 20,
            color: const Color(0xFF2F2F36),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: _panelBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionItem(
              icon: Icons.note_add_outlined,
              label: 'Nhập\ngiao dịch',
              iconColor: const Color(0xFF22C6C3),
              onTap: () => _showAddActionMenu(context),
            ),
          ),
          Expanded(
            child: _QuickActionItem(
              icon: Icons.show_chart_rounded,
              label: 'Biến động\nthu chi',
              iconColor: const Color(0xFF22C6C3),
              onTap: _cycleFilterType,
            ),
          ),
          Expanded(
            child: _QuickActionItem(
              icon: Icons.sell_outlined,
              label: 'Phân loại\ngiao dịch',
              iconColor: const Color(0xFF22C6C3),
              badgeCount: 1,
              onTap: () => setState(() => _showCategoryDetails = true),
            ),
          ),
          Expanded(
            child: _QuickActionItem(
              icon: Icons.grid_view_rounded,
              label: 'Tiện ích\nkhác',
              iconColor: Color(0xFF22C6C3),
              onTap: _showUtilitiesBottomSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    final allocationActive = !_showTrendView;
    final trendActive = _showTrendView;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tình hình thu chi',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF2F2F36),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              IconButton(
                onPressed: () => setState(() => _hideAmounts = !_hideAmounts),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                tooltip: _hideAmounts ? 'Hiện số tiền' : 'Ẩn số tiền',
                icon: Icon(
                  _hideAmounts
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _accentPink,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1EEF6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E3EE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _showTrendView = false),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: allocationActive
                        ? const Color(0xFFFFEAF5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 18,
                        color: allocationActive
                            ? _accentPink
                            : const Color(0xFF404048),
                      ),
                      if (allocationActive) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Phân bổ',
                          style: TextStyle(
                            color: _accentPink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _showTrendView = true),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: trendActive
                        ? const Color(0xFFFFEAF5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 20,
                        color: trendActive
                            ? _accentPink
                            : const Color(0xFF404048),
                      ),
                      if (trendActive) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Xu hướng',
                          style: TextStyle(
                            color: _accentPink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthOverviewCard({
    required String periodLabel,
    required double expense,
    required double income,
    required double focusCurrent,
    required double focusPrevious,
    required TransactionType focusType,
    required List<_CategorySlice> categorySlices,
    required double totalCategoryAmount,
    required List<double> trendSeries,
    required String trendCurrentLabel,
    required double periodBudget,
  }) {
    final delta = focusPrevious - focusCurrent;
    final reduced = delta >= 0;
    final changeColor = _changeColorForFocus(
      focusType: focusType,
      reduced: reduced,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _movePeriod(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: const Color(0xFF70707A),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showTimeFilterBottomSheet,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            periodLabel,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2F2F36),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _movePeriod(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: const Color(0xFFC1C1C9),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () =>
                      setState(() => _focusType = TransactionType.expense),
                  child: _SummaryAmountCard(
                    label: 'Chi tiêu',
                    value: _formatAmount(expense),
                    leadingIcon: Icons.outbound_rounded,
                    trailingIcon: Icons.south_rounded,
                    accentColor: _accentPink,
                    trailingColor: const Color(0xFF2CCF73),
                    highlighted: focusType == TransactionType.expense,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () =>
                      setState(() => _focusType = TransactionType.income),
                  child: _SummaryAmountCard(
                    label: 'Thu nhập',
                    value: _formatAmount(income),
                    leadingIcon: Icons.savings_outlined,
                    trailingIcon: Icons.south_rounded,
                    accentColor: _accentPink,
                    trailingColor: const Color(0xFFFF7B32),
                    highlighted: focusType == TransactionType.income,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xFF69A7DB)),
                const SizedBox(width: 8),
                Expanded(
                  child: focusPrevious <= 0
                      ? const Text(
                          'Chưa có dữ liệu kỳ trước để so sánh',
                          style: TextStyle(
                            color: Color(0xFF65656E),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF65656E),
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '${reduced ? 'Giảm' : 'Tăng'} ${_compactCurrency(delta.abs())} ',
                                style: TextStyle(
                                  color: changeColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: _comparisonTextForRange()),
                            ],
                          ),
                        ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6A6A73),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: !_showTrendView
                ? _buildAllocationChart(
                    key: const ValueKey('donut-view'),
                    categorySlices: categorySlices,
                    totalExpense: totalCategoryAmount,
                    emptyMessage: focusType == TransactionType.expense
                        ? 'Chưa có dữ liệu chi tiêu trong kỳ này'
                        : 'Chưa có dữ liệu thu nhập trong kỳ này',
                  )
                : _buildTrendChart(
                    key: const ValueKey('trend-view'),
                    values: trendSeries,
                    currentLabel: trendCurrentLabel,
                  ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                setState(() => _showCategoryDetails = !_showCategoryDetails),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chi tiết từng danh mục (${categorySlices.length})',
                    style: const TextStyle(
                      color: _accentPink,
                      fontSize: 36 / 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _showCategoryDetails
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _accentPink,
                  ),
                ],
              ),
            ),
          ),
          if (_showCategoryDetails && categorySlices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildCategoryDetailPanel(
                focusType: focusType,
                categorySlices: categorySlices,
                totalAmount: totalCategoryAmount,
                periodBudget: periodBudget,
                periodLabel: periodLabel,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllocationChart({
    Key? key,
    required List<_CategorySlice> categorySlices,
    required double totalExpense,
    required String emptyMessage,
  }) {
    if (categorySlices.isEmpty || totalExpense <= 0) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Text(
            emptyMessage,
            style: const TextStyle(
              color: Color(0xFF797983),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth * 0.72, 260.0);
        final highlights = categorySlices.take(3).toList();

        return Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: highlights
                  .map(
                    (slice) => _CategoryLegend(
                      color: slice.color,
                      percent: _percentLabel(slice.amount, totalExpense),
                      label: slice.name,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: size,
              height: size,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: size * 0.28,
                  sectionsSpace: 4,
                  borderData: FlBorderData(show: false),
                  sections: categorySlices
                      .map(
                        (slice) => PieChartSectionData(
                          value: slice.amount,
                          color: slice.color,
                          radius: size * 0.18,
                          title: '',
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrendChart({
    Key? key,
    required List<double> values,
    required String currentLabel,
  }) {
    final hasData = values.any((item) => item > 0);
    final maxRaw = hasData ? values.reduce(math.max) : 0.0;
    final divisor = maxRaw >= 1000000 ? 1000000.0 : 1000.0;
    final unitLabel = maxRaw >= 1000000 ? '(Triệu)' : '(Nghìn)';
    final normalized = values.map((item) => item / divisor).toList();
    final maxY = (normalized.reduce(math.max) * 1.2).clamp(1.0, 999999.0);

    return SizedBox(
      key: key,
      height: 330,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unitLabel,
            style: const TextStyle(
              color: Color(0xFF707079),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Color(0xFFE5E8EE), strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFF8A8D95), width: 1.2),
                  ),
                ),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final label = value == value.roundToDouble()
                            ? value.toInt().toString()
                            : value.toStringAsFixed(1);
                        return Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4F4F58),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final labels = ['T1', 'T2', currentLabel];
                        final isCurrent = index == labels.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            index >= 0 && index < labels.length
                                ? labels[index]
                                : '',
                            style: TextStyle(
                              fontSize: 14,
                              color: isCurrent
                                  ? const Color(0xFF1A78EE)
                                  : const Color(0xFF3F3F47),
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(normalized.length, (index) {
                  final isCurrent = index == normalized.length - 1;
                  return BarChartGroupData(
                    x: index,
                    barsSpace: 0,
                    barRods: [
                      BarChartRodData(
                        toY: normalized[index],
                        width: 54,
                        borderRadius: BorderRadius.circular(6),
                        color: isCurrent
                            ? const Color(0xFF1A84F6)
                            : const Color(0xFFB8CEE2),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetailPanel({
    required TransactionType focusType,
    required List<_CategorySlice> categorySlices,
    required double totalAmount,
    required double periodBudget,
    required String periodLabel,
  }) {
    if (focusType == TransactionType.income) {
      return Column(
        children: categorySlices
            .map(
              (slice) => _buildCategoryDetailRow(
                slice: slice,
                totalAmount: totalAmount,
                info: _detailInfoFromSlice(
                  slice: slice,
                  type: focusType,
                  periodBudget: periodBudget,
                  totalAmount: totalAmount,
                ),
                periodLabel: periodLabel,
              ),
            )
            .toList(),
      );
    }

    final parentGroups = _buildExpenseParentGroups(categorySlices);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F2F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8E3EE)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildBreakdownTabChip(
                  label: 'Danh mục con',
                  selected: _expenseBreakdownTab == _ExpenseBreakdownTab.child,
                  onTap: () => setState(
                    () => _expenseBreakdownTab = _ExpenseBreakdownTab.child,
                  ),
                ),
              ),
              Expanded(
                child: _buildBreakdownTabChip(
                  label: 'Danh mục cha',
                  selected: _expenseBreakdownTab == _ExpenseBreakdownTab.parent,
                  onTap: () => setState(
                    () => _expenseBreakdownTab = _ExpenseBreakdownTab.parent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_expenseBreakdownTab == _ExpenseBreakdownTab.child)
          ...categorySlices.map(
            (slice) => _buildCategoryDetailRow(
              slice: slice,
              totalAmount: totalAmount,
              info: _detailInfoFromSlice(
                slice: slice,
                type: focusType,
                periodBudget: periodBudget,
                totalAmount: totalAmount,
              ),
              periodLabel: periodLabel,
            ),
          )
        else
          ...parentGroups.map(
            (group) => _buildParentCategoryTile(
              group: group,
              periodLabel: periodLabel,
              periodBudget: periodBudget,
              totalAmount: totalAmount,
            ),
          ),
      ],
    );
  }

  Widget _buildBreakdownTabChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFFF4A0CF) : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFF12D9D)
                    : const Color(0xFF303038),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 20 / 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDetailRow({
    required _CategorySlice slice,
    required _BudgetCardInfo info,
    required double totalAmount,
    required String periodLabel,
    bool indent = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openBudgetCategory(info: info, periodLabel: periodLabel),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.fromLTRB(indent ? 12 : 4, 10, 4, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFEAE6EE),
                width: indent ? 0 : 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: slice.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  info.type == TransactionType.income
                      ? _iconForIncomeCategory(slice.name)
                      : _iconForBudgetCategory(slice.name),
                  size: 19,
                  color: slice.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  slice.name,
                  style: const TextStyle(
                    color: Color(0xFF33333B),
                    fontSize: 22 / 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                _formatAmount(slice.amount),
                style: const TextStyle(
                  color: Color(0xFF35353C),
                  fontWeight: FontWeight.w800,
                  fontSize: 22 / 1.2,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A7A83)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentCategoryTile({
    required _ParentCategoryGroup group,
    required String periodLabel,
    required double periodBudget,
    required double totalAmount,
  }) {
    final expanded = _expandedExpenseParents.contains(group.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  if (expanded) {
                    _expandedExpenseParents.remove(group.name);
                  } else {
                    _expandedExpenseParents.add(group.name);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        group.name == 'Chi phí cố định'
                            ? Icons.home_work_outlined
                            : Icons.layers_outlined,
                        size: 19,
                        color: const Color(0xFFF5A037),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          color: Color(0xFF2F2F37),
                          fontSize: 22 / 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      _formatAmount(group.amount),
                      style: const TextStyle(
                        color: Color(0xFF35353C),
                        fontSize: 22 / 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF787880),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: group.children
                    .map(
                      (slice) => _buildCategoryDetailRow(
                        slice: slice,
                        totalAmount: totalAmount,
                        info: _detailInfoFromSlice(
                          slice: slice,
                          type: TransactionType.expense,
                          periodBudget: periodBudget,
                          totalAmount: totalAmount,
                        ),
                        periodLabel: periodLabel,
                        indent: true,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  _BudgetCardInfo _detailInfoFromSlice({
    required _CategorySlice slice,
    required TransactionType type,
    required double periodBudget,
    required double totalAmount,
  }) {
    final customMonthly = _customCategoryMonthlyBudgets[slice.name];
    final allocated = type == TransactionType.expense
        ? customMonthly != null
              ? _budgetForCurrentRange(customMonthly)
              : _allocatedBudgetForCategory(
                  categoryAmount: slice.amount,
                  totalAmount: totalAmount,
                  periodBudget: periodBudget,
                )
        : 0.0;

    return _BudgetCardInfo(
      title: slice.name,
      allocated: allocated,
      spent: slice.amount,
      icon: type == TransactionType.income
          ? _iconForIncomeCategory(slice.name)
          : _iconForBudgetCategory(slice.name),
      accentColor: slice.color,
      type: type,
    );
  }

  double _allocatedBudgetForCategory({
    required double categoryAmount,
    required double totalAmount,
    required double periodBudget,
  }) {
    if (periodBudget <= 0) {
      return 0;
    }
    if (totalAmount <= 0) {
      return periodBudget / 4;
    }
    return (periodBudget * (categoryAmount / totalAmount)).clamp(
      periodBudget * 0.1,
      periodBudget * 0.75,
    );
  }

  List<_ParentCategoryGroup> _buildExpenseParentGroups(
    List<_CategorySlice> categorySlices,
  ) {
    final grouped = <String, List<_CategorySlice>>{};
    for (final item in categorySlices) {
      final parent = _expenseParentFor(item.name);
      grouped.putIfAbsent(parent, () => []).add(item);
    }

    final groups = grouped.entries
        .map(
          (entry) => _ParentCategoryGroup(
            name: entry.key,
            children: entry.value,
            amount: entry.value.fold(0.0, (sum, item) => sum + item.amount),
          ),
        )
        .toList();
    groups.sort((a, b) => b.amount.compareTo(a.amount));
    return groups;
  }

  String _expenseParentFor(String category) {
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

  IconData _iconForIncomeCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('lương')) {
      return Icons.badge_outlined;
    }
    if (lower.contains('thưởng')) {
      return Icons.workspace_premium_outlined;
    }
    if (lower.contains('lợi nhuận')) {
      return Icons.savings_outlined;
    }
    if (lower.contains('trợ cấp')) {
      return Icons.volunteer_activism_outlined;
    }
    if (lower.contains('thu hồi')) {
      return Icons.refresh_rounded;
    }
    return Icons.attach_money_rounded;
  }

  Widget _buildBudgetSection({
    required List<_BudgetCardInfo> cards,
    required double periodBudget,
    required String periodLabel,
  }) {
    final totalSpent = cards.isEmpty ? 0.0 : cards.first.spent;
    final effectiveBudget = cards.isEmpty
        ? periodBudget
        : cards.first.allocated;
    final remaining = effectiveBudget - totalSpent;
    final isOverBudget = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ngân sách chi tiêu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D2D35),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _openBudgetOverview(
                  cards: cards,
                  periodBudget: periodBudget,
                  periodLabel: periodLabel,
                ),
                child: Ink(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EEF6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF777782),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            periodLabel,
            style: const TextStyle(
              color: Color(0xFF7A7A84),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  isOverBudget
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isOverBudget
                      ? const Color(0xFFD84A4A)
                      : const Color(0xFF2CBF67),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOverBudget
                        ? 'Bạn đã vượt ngân sách ${_compactCurrency(remaining.abs())}'
                        : 'Còn lại ${_compactCurrency(remaining)} trong ngân sách',
                    style: TextStyle(
                      color: isOverBudget
                          ? const Color(0xFFB73D3D)
                          : const Color(0xFF2E7D57),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length + 1,
              separatorBuilder: (_, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == cards.length) {
                  return _BudgetCreateCard(
                    onTap: () => _openCreateBudget(periodLabel: periodLabel),
                  );
                }

                final card = cards[index];
                return _BudgetSpendingCard(
                  info: card,
                  hideAmounts: _hideAmounts,
                  onTap: () {
                    if (card.isTotal) {
                      _openBudgetOverview(
                        cards: cards,
                        periodBudget: periodBudget,
                        periodLabel: periodLabel,
                      );
                    } else {
                      _openBudgetCategory(info: card, periodLabel: periodLabel);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBudgetOverview({
    required List<_BudgetCardInfo> cards,
    required double periodBudget,
    required String periodLabel,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BudgetOverviewScreen(
          cards: cards,
          periodBudget: periodBudget,
          periodLabel: periodLabel,
          hideAmounts: _hideAmounts,
          onCreateBudget: () => _openCreateBudget(periodLabel: periodLabel),
          onOpenCategory: (item) {
            _openBudgetCategory(info: item, periodLabel: periodLabel);
          },
        ),
      ),
    );
  }

  Future<void> _openBudgetCategory({
    required _BudgetCardInfo info,
    required String periodLabel,
    String? successMessage,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BudgetCategoryScreen(
          info: info,
          periodLabel: periodLabel,
          hideAmounts: _hideAmounts,
          initialAnchorDate: _anchorDate,
          initialRange: _timeRange,
          initialSuccessMessage: successMessage,
        ),
      ),
    );
  }

  Future<void> _openCreateBudget({required String periodLabel}) async {
    final provider = context.read<FinanceProvider>();
    final currentRange = _resolveCurrentRange();
    final scopedTransactions = _transactionsInRange(
      source: provider.transactions,
      range: currentRange,
      type: TransactionType.expense,
    );
    final periodBudget = _budgetForCurrentRange(provider.monthlyBudget);
    final budgetCards = _buildBudgetCards(
      transactions: scopedTransactions,
      periodBudget: periodBudget,
    );
    final existingCategories = {
      ..._customCategoryMonthlyBudgets.keys,
      ...budgetCards
          .where((item) => !item.isTotal && item.spent > 0)
          .map((item) => item.title),
    };

    final result = await Navigator.of(context).push<_BudgetCreateResult>(
      MaterialPageRoute<_BudgetCreateResult>(
        builder: (_) => _BudgetCreateScreen(
          categories: _budgetSetupCategories,
          existingCategories: existingCategories,
          transactions: provider.transactions,
          iconForCategory: _iconForBudgetCategory,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _customCategoryMonthlyBudgets[result.category] = result.monthlyBudget;
    });

    final scopedExpense = _transactionsInRange(
      source: provider.transactions,
      range: currentRange,
      type: TransactionType.expense,
    );
    final spent = scopedExpense
        .where((tx) => tx.category == result.category)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final info = _BudgetCardInfo(
      title: result.category,
      allocated: _budgetForCurrentRange(result.monthlyBudget),
      spent: spent,
      icon: _iconForBudgetCategory(result.category),
      accentColor: const Color(0xFF1CC5C7),
      type: TransactionType.expense,
    );

    await _openBudgetCategory(
      info: info,
      periodLabel: periodLabel,
      successMessage: 'Tạo hạn mức chi tiêu thành công!',
    );
  }

  Future<void> _showAddActionMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('Nhập thủ công'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddTransactionSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Quét từ ảnh hóa đơn'),
                onTap: () {
                  Navigator.pop(ctx);
                  _importFromImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUtilitiesBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F6FB),
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
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Danh sách tiện ích',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2F2F36),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 34),
                        color: const Color(0xFF3D3D45),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    itemCount: _utilityEntries.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (context, index) {
                      final item = _utilityEntries[index];
                      return _UtilitySheetItem(
                        icon: item.icon,
                        label: item.label,
                        badge: item.badge,
                        badgeWidth: item.badgeWidth,
                        onTap: () {
                          Navigator.pop(ctx);
                          _handleUtilityAction(item.action);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleUtilityAction(_FinanceUtilityAction action) {
    switch (action) {
      case _FinanceUtilityAction.addTransaction:
        _showAddActionMenu(context);
        return;
      case _FinanceUtilityAction.flowChange:
        _cycleFilterType();
        return;
      case _FinanceUtilityAction.categorize:
        setState(() => _showCategoryDetails = true);
        return;
      case _FinanceUtilityAction.calendar:
        _showTimeFilterBottomSheet();
        return;
      case _FinanceUtilityAction.moni:
        _showHint('Tab Moni (AI) nằm ở thanh tab dưới của module Finance.');
        return;
      case _FinanceUtilityAction.budget:
        _showHint(
          'Bạn có thể đổi ngân sách trong tab Tiện ích của Finance module.',
        );
        return;
      case _FinanceUtilityAction.recurring:
        _showHint('Tab GĐ định kỳ nằm ở thanh tab dưới của module Finance.');
        return;
      case _FinanceUtilityAction.categoryManager:
      case _FinanceUtilityAction.community:
      case _FinanceUtilityAction.addDevice:
      case _FinanceUtilityAction.removeHome:
      case _FinanceUtilityAction.intro:
      case _FinanceUtilityAction.transactionLimit:
        _showHint('Tính năng này sẽ được mở rộng ở phiên bản kế tiếp.');
        return;
    }
  }

  Future<void> _showTimeFilterBottomSheet() async {
    final now = DateTime.now();
    var tempRange = _timeRange;
    var tempYear = _anchorDate.year;
    var tempMonth = _anchorDate.month;
    var tempDay = _anchorDate.day;
    var tempWeekStart = _weekStart(_anchorDate);

    final result = await showModalBottomSheet<_FinanceTimeFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isFutureMonth(int month) {
              if (tempYear > now.year) {
                return true;
              }
              if (tempYear < now.year) {
                return false;
              }
              return month > now.month;
            }

            void shiftDisplayedMonth(int delta) {
              final moved = DateTime(tempYear, tempMonth + delta, 1);
              tempYear = moved.year;
              tempMonth = moved.month;
              final weeks = _buildWeekOptions(tempYear, tempMonth);
              tempWeekStart = weeks.isNotEmpty
                  ? weeks.first.start
                  : _weekStart(moved);
              tempDay = 1;
            }

            final yearChoices = _yearChoices(tempYear, now.year);
            final weekOptions = _buildWeekOptions(tempYear, tempMonth);

            Widget buildSelectionPanel() {
              if (tempRange == _FinanceTimeRange.week) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6EBF3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                setModalState(() => shiftDisplayedMonth(-1)),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Tháng $tempMonth/$tempYear',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2F2F36),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setModalState(() => shiftDisplayedMonth(1)),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFF4D94FF),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        itemCount: weekOptions.length,
                        itemBuilder: (context, index) {
                          final option = weekOptions[index];
                          final selected = option.start == tempWeekStart;
                          final weekName = _weekTitle(
                            option: option,
                            index: index,
                            displayYear: tempYear,
                            displayMonth: tempMonth,
                            now: now,
                          );

                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setModalState(
                              () => tempWeekStart = option.start,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFEEF8)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFF59ACE)
                                      : Colors.transparent,
                                ),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 20 / 1.2,
                                    color: Color(0xFF3E3E46),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$weekName: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          'Ngày ${_weekRangeText(option.start, option.end, tempMonth)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }

              if (tempRange == _FinanceTimeRange.year) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: GridView.builder(
                    itemCount: yearChoices.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.5,
                        ),
                    itemBuilder: (context, index) {
                      final year = yearChoices[index];
                      final selected = tempYear == year;

                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setModalState(() {
                          tempYear = year;
                          if (tempYear == now.year && tempMonth > now.month) {
                            tempMonth = now.month;
                          }
                          tempDay = 1;
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFFEEF8)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFF59ACE)
                                  : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Năm $year',
                            style: TextStyle(
                              color: const Color(0xFF3F3F47),
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              fontSize: 20 / 1.2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EBF3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => setModalState(() {
                            tempYear -= 1;
                            if (tempMonth > now.month && tempYear == now.year) {
                              tempMonth = now.month;
                            }
                          }),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$tempYear',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2F2F36),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setModalState(() => tempYear += 1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFF4D94FF),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: GridView.builder(
                        itemCount: 12,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.2,
                            ),
                        itemBuilder: (context, index) {
                          final month = index + 1;
                          final disabled = isFutureMonth(month);
                          final selected = tempMonth == month;

                          return _TimeMonthChip(
                            label: 'Tháng $month',
                            selected: selected,
                            disabled: disabled,
                            onTap: disabled
                                ? null
                                : () => setModalState(() {
                                    tempMonth = month;
                                    tempDay = 1;
                                  }),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.7,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F4FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D7DD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Chọn thời gian hiển thị chi tiêu',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2F2F36),
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TimeRangeChip(
                              label: 'Tuần',
                              selected: tempRange == _FinanceTimeRange.week,
                              onTap: () => setModalState(() {
                                tempRange = _FinanceTimeRange.week;
                                final monthSafeDay = tempDay
                                    .clamp(
                                      1,
                                      DateTime(tempYear, tempMonth + 1, 0).day,
                                    )
                                    .toInt();
                                tempWeekStart = _weekStart(
                                  DateTime(tempYear, tempMonth, monthSafeDay),
                                );
                              }),
                            ),
                          ),
                          Expanded(
                            child: _TimeRangeChip(
                              label: 'Tháng',
                              selected: tempRange == _FinanceTimeRange.month,
                              onTap: () => setModalState(
                                () => tempRange = _FinanceTimeRange.month,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _TimeRangeChip(
                              label: 'Năm',
                              selected: tempRange == _FinanceTimeRange.year,
                              onTap: () => setModalState(
                                () => tempRange = _FinanceTimeRange.year,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _borderColor),
                        ),
                        child: buildSelectionPanel(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: const Color(0xFFE8E8EE),
                              foregroundColor: const Color(0xFFAFAFB7),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(
                                ctx,
                                _FinanceTimeFilterResult(
                                  range: _FinanceTimeRange.month,
                                  year: now.year,
                                  month: now.month,
                                  day: 1,
                                ),
                              );
                            },
                            child: const Text('Xoá bộ lọc'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: _accentPink,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              var appliedYear = tempYear;
                              var appliedMonth = tempMonth;
                              var appliedDay = tempDay;

                              if (tempRange == _FinanceTimeRange.week) {
                                final anchor = _anchorForWeekSelection(
                                  weekStart: tempWeekStart,
                                  displayYear: tempYear,
                                  displayMonth: tempMonth,
                                );
                                appliedYear = anchor.year;
                                appliedMonth = anchor.month;
                                appliedDay = anchor.day;
                              } else if (tempRange == _FinanceTimeRange.year) {
                                appliedMonth = 1;
                                appliedDay = 1;
                              } else {
                                appliedDay = 1;
                              }

                              Navigator.pop(
                                ctx,
                                _FinanceTimeFilterResult(
                                  range: tempRange,
                                  year: appliedYear,
                                  month: appliedMonth,
                                  day: appliedDay,
                                ),
                              );
                            },
                            child: const Text('Áp dụng'),
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
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _timeRange = result.range;
      _filterMonth = DateTime(result.year, result.month, result.day);
    });
  }

  void _cycleFilterType() {
    setState(() {
      _focusType = _focusType == TransactionType.expense
          ? TransactionType.income
          : TransactionType.expense;
    });

    if (_focusType == TransactionType.expense) {
      _showHint('Đang tập trung vào biến động chi tiêu.');
      return;
    }
    _showHint('Đang tập trung vào biến động thu nhập.');
  }

  void _movePeriod(int delta) {
    final anchor = _anchorDate;
    setState(() {
      switch (_timeRange) {
        case _FinanceTimeRange.week:
          _filterMonth = anchor.add(Duration(days: 7 * delta));
          break;
        case _FinanceTimeRange.month:
          _filterMonth = DateTime(anchor.year, anchor.month + delta, 1);
          break;
        case _FinanceTimeRange.year:
          _filterMonth = DateTime(anchor.year + delta, anchor.month, 1);
          break;
      }
    });
  }

  _FinanceRangeWindow _resolveCurrentRange() {
    final anchor = _anchorDate;

    switch (_timeRange) {
      case _FinanceTimeRange.week:
        final start = _weekStart(anchor);
        return _FinanceRangeWindow(
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      case _FinanceTimeRange.month:
        final start = DateTime(anchor.year, anchor.month, 1);
        return _FinanceRangeWindow(
          start: start,
          end: DateTime(anchor.year, anchor.month + 1, 1),
        );
      case _FinanceTimeRange.year:
        final start = DateTime(anchor.year, 1, 1);
        return _FinanceRangeWindow(
          start: start,
          end: DateTime(anchor.year + 1, 1, 1),
        );
    }
  }

  _FinanceRangeWindow _resolvePreviousRange(_FinanceRangeWindow current) {
    switch (_timeRange) {
      case _FinanceTimeRange.week:
        final end = current.start;
        return _FinanceRangeWindow(
          start: end.subtract(const Duration(days: 7)),
          end: end,
        );
      case _FinanceTimeRange.month:
        return _FinanceRangeWindow(
          start: DateTime(current.start.year, current.start.month - 1, 1),
          end: DateTime(current.start.year, current.start.month, 1),
        );
      case _FinanceTimeRange.year:
        return _FinanceRangeWindow(
          start: DateTime(current.start.year - 1, 1, 1),
          end: DateTime(current.start.year, 1, 1),
        );
    }
  }

  List<FinanceTransaction> _transactionsInRange({
    required List<FinanceTransaction> source,
    required _FinanceRangeWindow range,
    TransactionType? type,
  }) {
    return source.where((item) {
      final at = item.createdAt;
      final inRange = !at.isBefore(range.start) && at.isBefore(range.end);
      final typeMatch = type == null || item.type == type;
      return inRange && typeMatch;
    }).toList();
  }

  Map<String, double> _amountByCategory(
    List<FinanceTransaction> source, {
    required TransactionType type,
  }) {
    final map = <String, double>{};
    for (final item in source) {
      if (item.type != type) continue;
      map[item.category] = (map[item.category] ?? 0) + item.amount;
    }
    return map;
  }

  String _comparisonTextForRange() {
    switch (_timeRange) {
      case _FinanceTimeRange.week:
        return 'so với tuần trước';
      case _FinanceTimeRange.month:
        return 'so với cùng kỳ tháng trước';
      case _FinanceTimeRange.year:
        return 'so với năm trước';
    }
  }

  Color _changeColorForFocus({
    required TransactionType focusType,
    required bool reduced,
  }) {
    if (focusType == TransactionType.expense) {
      return reduced ? const Color(0xFF2CBF67) : const Color(0xFFD84A4A);
    }
    return reduced ? const Color(0xFFD84A4A) : const Color(0xFF2CBF67);
  }

  double _budgetForCurrentRange(double monthlyBudget) {
    switch (_timeRange) {
      case _FinanceTimeRange.week:
        return monthlyBudget / 4;
      case _FinanceTimeRange.month:
        return monthlyBudget;
      case _FinanceTimeRange.year:
        return monthlyBudget * 12;
    }
  }

  List<_BudgetCardInfo> _buildBudgetCards({
    required List<FinanceTransaction> transactions,
    required double periodBudget,
  }) {
    final expenseByCategory = _amountByCategory(
      transactions,
      type: TransactionType.expense,
    );
    final totalSpent = transactions
        .where((item) => item.type == TransactionType.expense)
        .fold(0.0, (sum, item) => sum + item.amount);

    final customPeriodBudgetByCategory = _customCategoryMonthlyBudgets.map(
      (key, value) => MapEntry(key, _budgetForCurrentRange(value)),
    );
    final totalAllocated = customPeriodBudgetByCategory.isEmpty
        ? periodBudget
        : customPeriodBudgetByCategory.values.fold<double>(
            0.0,
            (sum, item) => sum + item,
          );

    final cards = <_BudgetCardInfo>[
      _BudgetCardInfo(
        title: 'Ngân sách tổng',
        allocated: totalAllocated,
        spent: totalSpent,
        icon: Icons.savings_outlined,
        accentColor: const Color(0xFF1CC5C7),
        isTotal: true,
      ),
    ];

    final sortedCategories = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visibleNames = sortedCategories
        .map((entry) => entry.key)
        .take(6)
        .toList();
    final allNames = <String>[...visibleNames];
    for (final category in customPeriodBudgetByCategory.keys) {
      if (!allNames.contains(category)) {
        allNames.add(category);
      }
    }

    if (allNames.isEmpty) {
      allNames.addAll(
        _expenseCategories
            .take(2)
            .where((item) => !customPeriodBudgetByCategory.keys.contains(item)),
      );
      allNames.addAll(customPeriodBudgetByCategory.keys);
    }

    for (final category in allNames) {
      final spent = expenseByCategory[category] ?? 0.0;
      final allocated =
          customPeriodBudgetByCategory[category] ??
          _allocatedBudgetForCategory(
            categoryAmount: spent,
            totalAmount: totalSpent,
            periodBudget: totalAllocated,
          );
      cards.add(
        _BudgetCardInfo(
          title: category,
          allocated: allocated,
          spent: spent,
          icon: _iconForBudgetCategory(category),
          accentColor: const Color(0xFF1CC5C7),
          isTotal: false,
        ),
      );
    }

    return cards;
  }

  IconData _iconForBudgetCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('đầu tư')) {
      return Icons.savings_outlined;
    }
    if (lower.contains('làm đẹp')) {
      return Icons.face_retouching_natural_outlined;
    }
    if (lower.contains('người thân')) {
      return Icons.child_friendly_outlined;
    }
    if (lower.contains('nhà cửa') || lower.contains('nhà')) {
      return Icons.home_work_outlined;
    }
    if (lower.contains('ăn') ||
        lower.contains('uống') ||
        lower.contains('chợ')) {
      return Icons.shopping_basket_outlined;
    }
    if (lower.contains('di chuyển') || lower.contains('xe')) {
      return Icons.directions_car_filled_outlined;
    }
    if (lower.contains('hóa đơn') || lower.contains('bill')) {
      return Icons.receipt_long_outlined;
    }
    if (lower.contains('giải trí')) {
      return Icons.movie_creation_outlined;
    }
    if (lower.contains('học')) {
      return Icons.menu_book_outlined;
    }
    if (lower.contains('sức khỏe')) {
      return Icons.favorite_outline_rounded;
    }
    if (lower.contains('từ thiện')) {
      return Icons.volunteer_activism_outlined;
    }
    if (lower.contains('tổng')) {
      return Icons.account_balance_wallet_outlined;
    }
    return Icons.account_balance_wallet_outlined;
  }

  String _rangeLabel(_FinanceRangeWindow range) {
    final now = DateTime.now();
    switch (_timeRange) {
      case _FinanceTimeRange.week:
        if (_isSameWeek(range.start, now)) {
          return 'Tuần này';
        }
        return 'Tuần ${_weekOfYear(range.start)}/${range.start.year}';
      case _FinanceTimeRange.month:
        if (range.start.year == now.year && range.start.month == now.month) {
          return 'Tháng này';
        }
        return 'Tháng ${range.start.month}/${range.start.year}';
      case _FinanceTimeRange.year:
        if (range.start.year == now.year) {
          return 'Năm nay';
        }
        return 'Năm ${range.start.year}';
    }
  }

  DateTime _weekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    return _weekStart(a) == _weekStart(b);
  }

  int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDay).inDays + 1;
    return ((dayOfYear + firstDay.weekday - 2) / 7).floor() + 1;
  }

  List<_FinanceWeekOption> _buildWeekOptions(int year, int month) {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);
    var cursor = _weekStart(monthStart);
    final options = <_FinanceWeekOption>[];

    while (!cursor.isAfter(monthEnd)) {
      options.add(
        _FinanceWeekOption(
          start: cursor,
          end: cursor.add(const Duration(days: 6)),
        ),
      );
      cursor = cursor.add(const Duration(days: 7));
    }

    return options;
  }

  List<int> _yearChoices(int selectedYear, int currentYear) {
    final years = <int>{
      currentYear - 2,
      currentYear - 1,
      currentYear,
      selectedYear,
    }.toList()..sort();
    return years;
  }

  String _weekTitle({
    required _FinanceWeekOption option,
    required int index,
    required int displayYear,
    required int displayMonth,
    required DateTime now,
  }) {
    final isCurrentDisplayMonth =
        displayYear == now.year && displayMonth == now.month;
    if (isCurrentDisplayMonth && option.start == _weekStart(now)) {
      return 'Tuần này';
    }
    return 'Tuần ${index + 1}';
  }

  String _weekRangeText(DateTime start, DateTime end, int displayMonth) {
    return '${_dayWithOptionalMonth(start, displayMonth)} - ${_dayWithOptionalMonth(end, displayMonth)}';
  }

  String _dayWithOptionalMonth(DateTime date, int displayMonth) {
    if (date.month == displayMonth) {
      return '${date.day}';
    }
    return '${date.day}/${date.month}';
  }

  DateTime _anchorForWeekSelection({
    required DateTime weekStart,
    required int displayYear,
    required int displayMonth,
  }) {
    final monthStart = DateTime(displayYear, displayMonth, 1);
    final monthEnd = DateTime(displayYear, displayMonth + 1, 0);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final anchorStart = weekStart.isBefore(monthStart) ? monthStart : weekStart;
    final anchorEnd = weekEnd.isAfter(monthEnd) ? monthEnd : weekEnd;

    if (anchorStart.isAfter(anchorEnd)) {
      return monthStart;
    }
    return anchorStart;
  }

  List<_CategorySlice> _buildCategorySlices(Map<String, double> raw) {
    final entries = raw.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const [];
    }

    final slices = <_CategorySlice>[];
    final maxDirectSlices = entries.length > 5 ? 4 : entries.length;
    var others = 0.0;

    for (var i = 0; i < entries.length; i++) {
      final item = entries[i];
      if (i < maxDirectSlices) {
        slices.add(
          _CategorySlice(
            name: item.key,
            amount: item.value,
            color: _chartPalette[i % _chartPalette.length],
          ),
        );
      } else {
        others += item.value;
      }
    }

    if (others > 0) {
      slices.add(
        const _CategorySlice(name: 'Khác', amount: 0, color: Color(0xFF9DB0AE)),
      );
      final idx = slices.length - 1;
      slices[idx] = _CategorySlice(
        name: 'Khác',
        amount: others,
        color: slices[idx].color,
      );
    }

    return slices;
  }

  double _sumAmount(
    List<FinanceTransaction> transactions,
    TransactionType type,
  ) {
    return transactions
        .where((item) => item.type == type)
        .fold(0, (sum, item) => sum + item.amount);
  }

  String _compactCurrency(double amount) {
    final normalized = Formatters.currency(
      amount,
    ).replaceFirst(RegExp(r'^VND\s*'), '');
    return '$normalizedđ';
  }

  String _percentLabel(double value, double total) {
    if (total <= 0 || value <= 0) {
      return '<1%';
    }

    final percent = value / total * 100;
    if (percent < 1) {
      return '<1%';
    }
    if (percent > 99) {
      return '>99%';
    }
    return '${percent.round()}%';
  }

  void _showHint(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatAmount(double amount) {
    if (_hideAmounts) {
      return '******';
    }
    return _compactCurrency(amount);
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
                    key: ValueKey('category-${type.name}-$category'),
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    items: _categoryOptions(type)
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
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
      if (normalized.contains('ăn') ||
          normalized.contains('uong') ||
          normalized.contains('uống')) {
        return 'Ăn uống';
      }
      if (normalized.contains('xe') ||
          normalized.contains('di chuyển') ||
          normalized.contains('grab')) {
        return 'Di chuyển';
      }
      if (normalized.contains('hoc') ||
          normalized.contains('học') ||
          normalized.contains('book')) {
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
          content: Text(
            'OCR không trả về dữ liệu. Kiểm tra OCR_API_KEY hoặc thử ảnh rõ hơn.',
          ),
        ),
      );
      return;
    }

    await _showAddTransactionSheet(
      context,
      initialTitle: result.title,
      initialAmount: result.amount,
      initialCategory: result.category,
      initialNote:
          'OCR: ${result.rawText.substring(0, result.rawText.length > 200 ? 200 : result.rawText.length)}',
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF8FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: iconColor, size: 30),
                  ),
                  if ((badgeCount ?? 0) > 0)
                    Positioned(
                      right: -2,
                      top: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF2F4C),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.2,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3A3A42),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryAmountCard extends StatelessWidget {
  const _SummaryAmountCard({
    required this.label,
    required this.value,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.accentColor,
    required this.trailingColor,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData leadingIcon;
  final IconData trailingIcon;
  final Color accentColor;
  final Color trailingColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFFAFD) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? accentColor.withValues(alpha: 0.75)
              : const Color(0xFFE6E2EC),
          width: highlighted ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: highlighted
                      ? accentColor.withValues(alpha: 0.14)
                      : const Color(0xFFF4F3F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(leadingIcon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: highlighted ? accentColor : const Color(0xFF3A3A42),
                    fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: trailingColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(trailingIcon, color: trailingColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF3A3A42),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentCategoryGroup {
  const _ParentCategoryGroup({
    required this.name,
    required this.amount,
    required this.children,
  });

  final String name;
  final double amount;
  final List<_CategorySlice> children;
}

class _BudgetCardInfo {
  const _BudgetCardInfo({
    required this.title,
    required this.allocated,
    required this.spent,
    required this.icon,
    required this.accentColor,
    this.isTotal = false,
    this.type = TransactionType.expense,
  });

  final String title;
  final double allocated;
  final double spent;
  final IconData icon;
  final Color accentColor;
  final bool isTotal;
  final TransactionType type;

  double get ratio {
    if (allocated <= 0) {
      return spent > 0 ? 1.0 : 0.0;
    }
    return (spent / allocated).clamp(0.0, 1.6).toDouble();
  }

  double get remaining => allocated - spent;
  double get safeRatio => ratio.clamp(0.0, 1.0).toDouble();

  bool get isOverBudget => allocated > 0 && spent > allocated;
}

class _BudgetSpendingCard extends StatelessWidget {
  const _BudgetSpendingCard({
    required this.info,
    required this.hideAmounts,
    this.onTap,
  });

  final _BudgetCardInfo info;
  final bool hideAmounts;
  final VoidCallback? onTap;

  String _format(double value) {
    if (hideAmounts) {
      return '******';
    }
    final raw = Formatters.currency(value).replaceFirst(RegExp(r'^VND\s*'), '');
    return '$rawđ';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = info.remaining;
    final overBudget = info.isOverBudget;
    final remainingRatio = info.allocated <= 0
        ? 0.0
        : (remaining / info.allocated).clamp(0.0, 1.0).toDouble();
    final statusBg = overBudget
        ? const Color(0xFFFFF1EA)
        : const Color(0xFFEAF8EF);
    final statusColor = overBudget
        ? const Color(0xFFFF6A2A)
        : const Color(0xFF18A957);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          width: 204,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E3EE)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  info.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F2F37),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 98,
                height: 98,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 98,
                      height: 98,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 10,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFE6E4EB),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 98,
                      height: 98,
                      child: CircularProgressIndicator(
                        value: remainingRatio,
                        strokeWidth: 10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overBudget
                              ? const Color(0xFFE6E4EB)
                              : info.accentColor,
                        ),
                      ),
                    ),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: overBudget
                            ? const Color(0xFFF2F1F6)
                            : const Color(0xFFF3FAFA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        info.icon,
                        color: overBudget
                            ? const Color(0xFFD8D6DE)
                            : info.accentColor,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                overBudget ? 'Vượt' : 'Còn lại',
                style: const TextStyle(fontSize: 18, color: Color(0xFF707079)),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 32,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _format(remaining.abs()),
                    style: TextStyle(
                      fontSize: 42 / 2,
                      fontWeight: FontWeight.w900,
                      color: overBudget
                          ? const Color(0xFFFF5B27)
                          : info.accentColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          overBudget
                              ? Icons.local_fire_department_rounded
                              : Icons.verified_user_rounded,
                          size: 18,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          overBudget ? 'Đã vượt' : 'Tốt',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 18 / 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCreateCard extends StatelessWidget {
  const _BudgetCreateCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          width: 196,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E3EE)),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFF4F4F6),
                child: Icon(
                  Icons.add_rounded,
                  size: 56,
                  color: Color(0xFF73737C),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Tạo ngân sách',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF34343B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetOverviewScreen extends StatefulWidget {
  const _BudgetOverviewScreen({
    required this.cards,
    required this.periodBudget,
    required this.periodLabel,
    required this.hideAmounts,
    required this.onCreateBudget,
    required this.onOpenCategory,
  });

  final List<_BudgetCardInfo> cards;
  final double periodBudget;
  final String periodLabel;
  final bool hideAmounts;
  final Future<void> Function() onCreateBudget;
  final ValueChanged<_BudgetCardInfo> onOpenCategory;

  @override
  State<_BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<_BudgetOverviewScreen> {
  String _money(double value) {
    if (widget.hideAmounts) {
      return '******';
    }
    final raw = Formatters.currency(value).replaceFirst(RegExp(r'^VND\s*'), '');
    return '$rawđ';
  }

  void _showHint(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showTotalMenu() async {
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
                    border: Border.all(color: const Color(0xFFE8E3EE)),
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
                          _showHint(
                            'Sẽ sớm hỗ trợ chỉnh sửa trực tiếp ngân sách tổng.',
                          );
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
    final total = widget.cards.firstWhere(
      (item) => item.isTotal,
      orElse: () => widget.cards.first,
    );
    final categories = widget.cards.where((item) => !item.isTotal).toList();
    final overBudget = total.isOverBudget;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBE6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Ngân sách',
          style: TextStyle(
            color: Color(0xFF32323A),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF32323A)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE8E3EE)),
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
                      widget.periodLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF303038),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chi 2 ngày tới',
                      style: TextStyle(
                        color: Color(0xFF6E6E78),
                        fontSize: 18 / 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onCreateBudget(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF12D9D)),
                  foregroundColor: const Color(0xFFF12D9D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 28),
                label: const Text(
                  'Thêm mới',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E3EE)),
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
                          color: Color(0xFF2F2F37),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
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
                    IconButton(
                      onPressed: _showTotalMenu,
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: const Color(0xFF2F2F37),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _BudgetHalfGauge(
                  ratio: total.safeRatio,
                  color: overBudget
                      ? const Color(0xFFFF6A2A)
                      : const Color(0xFF1BB7B8),
                ),
                const SizedBox(height: 4),
                Text(
                  overBudget ? 'Đã vượt' : 'Còn lại',
                  style: const TextStyle(
                    color: Color(0xFF6F6F78),
                    fontSize: 22 / 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(total.remaining.abs()),
                  style: TextStyle(
                    color: overBudget
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
                              _money(total.allocated),
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
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Danh mục',
                  style: TextStyle(
                    fontSize: 42 / 1.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F2F37),
                  ),
                ),
              ),
              Text(
                'Xếp theo tên',
                style: TextStyle(
                  fontSize: 20 / 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2F2F37),
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.tune_rounded, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          ...categories.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BudgetCategoryListTile(
                info: item,
                hideAmounts: widget.hideAmounts,
                onTap: () => widget.onOpenCategory(item),
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
  });

  final _BudgetCardInfo info;
  final bool hideAmounts;
  final VoidCallback onTap;

  String _money(double value) {
    if (hideAmounts) {
      return '******';
    }
    final raw = Formatters.currency(value).replaceFirst(RegExp(r'^VND\s*'), '');
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
            border: Border.all(color: const Color(0xFFE8E3EE)),
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
                              color: Color(0xFF2F2F37),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.more_horiz_rounded,
                          color: Color(0xFF303038),
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
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;

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
    final raw = Formatters.currency(value).replaceFirst(RegExp(r'^VND\s*'), '');
    return '$rawđ';
  }

  String _inputMoney(double value) {
    if (value <= 0) {
      return '0';
    }
    return Formatters.currency(
      value,
    ).replaceFirst(RegExp(r'^VND\s*'), '').replaceAll('đ', '');
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

  double _suggestionFor(String category) {
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

    final items =
        available
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
      return nonZero.take(2).toList();
    }

    final fallback = <_BudgetCreateSuggestion>[];
    for (final category in ['Hóa đơn', 'Ăn uống']) {
      if (available.contains(category)) {
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
                tx.category == category &&
                !tx.createdAt.isBefore(start) &&
                tx.createdAt.isBefore(end),
          )
          .fold(0.0, (sum, tx) => sum + tx.amount);
      final label = base.month == 1
          ? '${base.month}/${base.year}'
          : '${base.month}';
      points.add(_CategoryPeriodPoint(label: label, amount: amount));
    }
    return points;
  }

  void _selectCategory(String category) {
    if (widget.existingCategories.contains(category)) {
      return;
    }
    final suggestion = _suggestionFor(category);
    _amountController.text = _inputMoney(suggestion);
    setState(() {
      _selectedCategory = category;
    });
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
                  color: Color(0xFF2F2F37),
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
            color: Color(0xFF2F2F37),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E3EE)),
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
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFF12D9D)),
        ),
      ],
    );
  }

  Widget _buildBudgetForm() {
    final category = _selectedCategory!;
    final amount = _parseAmount(_amountController.text);
    final canSubmit = amount > 0;
    final points = _historyPoints(category);
    final avgSource = points
        .take(points.length - 1)
        .where((item) => item.amount > 0);
    final average = avgSource.isEmpty
        ? 0.0
        : avgSource.fold(0.0, (sum, item) => sum + item.amount) /
              avgSource.length;

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
                  border: Border.all(color: const Color(0xFFE8E3EE)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            widget.iconForCategory(category),
                            size: 48,
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
                                  fontSize: 32 / 1.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                category,
                                style: const TextStyle(
                                  color: Color(0xFF2E2E36),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 40 / 1.6,
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
                        fontSize: 46 / 1.45,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D2D35),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Ngân sách chi tiêu trong tháng*',
                        suffixText: 'đ',
                        suffixStyle: const TextStyle(
                          color: Color(0xFF2D2D35),
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
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF3D3D44),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tham khảo thống kê chi tiêu của bạn',
                    style: TextStyle(
                      fontSize: 42 / 1.55,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2F2F37),
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
              ),
              const SizedBox(height: 12),
              Text(
                'Xu hướng chi tiêu $category 6 tháng gần đây',
                style: const TextStyle(
                  fontSize: 42 / 1.55,
                  color: Color(0xFF2F2F37),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
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
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF12D9D),
                  disabledBackgroundColor: const Color(0xFFE7E7EC),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFFBCBCC4),
                  minimumSize: const Size.fromHeight(64),
                  textStyle: const TextStyle(
                    fontSize: 40 / 1.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Tạo ngân sách'),
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
      backgroundColor: const Color(0xFFF4F2F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBE6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF32323A)),
        title: const Text(
          'Tạo ngân sách',
          style: TextStyle(
            color: Color(0xFF32323A),
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
              border: Border.all(color: const Color(0xFFE8E3EE)),
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
                            : const Color(0xFF2F2F37),
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
  }

  String _money(double value) {
    if (widget.hideAmounts) {
      return '******';
    }
    final raw = Formatters.currency(value).replaceFirst(RegExp(r'^VND\s*'), '');
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

  String _periodTitle() {
    final prefix = widget.info.type == TransactionType.income
        ? 'Thu nhập'
        : 'Chi tiêu';
    if (_monthMode) {
      return '$prefix tháng ${_anchorDate.month}';
    }
    final start = _weekStart(_anchorDate);
    final end = start.add(const Duration(days: 6));
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

  List<FinanceTransaction> _periodTransactions(FinanceProvider provider) {
    final range = _activeRange();
    return provider.transactions.where((tx) {
      final inRange =
          !tx.createdAt.isBefore(range.start) &&
          tx.createdAt.isBefore(range.end);
      return inRange && _matchesCategory(tx);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
        points.add(_CategoryPeriodPoint(label: label, amount: amount));
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
      points.add(_CategoryPeriodPoint(label: label, amount: amount));
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
            border: Border.all(color: const Color(0xFFE8E3EE)),
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
                                color: Color(0xFF2F2F37),
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
        border: Border.all(color: const Color(0xFFE8E3EE)),
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
                          color: Color(0xFF2F2F37),
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
        border: Border.all(color: const Color(0xFFE8E3EE)),
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
                          color: Color(0xFF2F2F37),
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
        border: Border.all(color: const Color(0xFFE8E3EE)),
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
                    border: Border.all(color: const Color(0xFFE8E3EE)),
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
    final transactions = _periodTransactions(provider);
    final totalAmount = transactions.fold(0.0, (sum, tx) => sum + tx.amount);
    final historyPoints = _historyPoints(provider);
    final nonZeroAvg = historyPoints
        .take(historyPoints.length - 1)
        .where((item) => item.amount > 0)
        .toList();
    final avgLine = nonZeroAvg.isEmpty
        ? 0.0
        : nonZeroAvg.fold(0.0, (sum, item) => sum + item.amount) /
              nonZeroAvg.length;

    final hasMonthlyBudget =
        widget.info.type == TransactionType.expense &&
        widget.info.allocated > 0;
    final allocatedBudget =
        widget.info.type == TransactionType.expense && _monthMode
        ? widget.info.allocated
        : 0.0;
    final hasBudget = allocatedBudget > 0;
    final remaining = allocatedBudget - totalAmount;
    final overBudget = hasBudget && remaining < 0;
    final monthTotalAmount = _sumInRange(provider, _monthRange());
    final monthRemaining = widget.info.allocated - monthTotalAmount;
    final monthOverBudget = hasMonthlyBudget && monthRemaining < 0;
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
      backgroundColor: const Color(0xFFF4F2F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBE6F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.info.title,
          style: const TextStyle(
            color: Color(0xFF32323A),
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF32323A)),
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
              border: Border.all(color: const Color(0xFFE8E3EE)),
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
                        _periodTitle(),
                        style: const TextStyle(
                          fontSize: 40 / 1.55,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2F2F37),
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
                  border: Border.all(color: const Color(0xFFE7E5EC)),
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _monthMode = false),
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
                              ? Border.all(color: const Color(0xFFE7E5EC))
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
                                  ? const Color(0xFFF12D9D)
                                  : const Color(0xFF2F2F37),
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
                      onTap: () => setState(() => _monthMode = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 84,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _monthMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: _monthMode
                              ? Border.all(color: const Color(0xFFE7E5EC))
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
                                  ? const Color(0xFFF12D9D)
                                  : const Color(0xFF2F2F37),
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
            hideAmounts: widget.hideAmounts,
            highlightColor: widget.info.type == TransactionType.income
                ? const Color(0xFFF6B348)
                : const Color(0xFF1A84F6),
            referenceLineValue: showBudgetSection ? allocatedBudget : avgLine,
            referenceLineColor: showBudgetSection
                ? const Color(0xFF14A9AD)
                : const Color(0xFFF12D9D),
            caption: chartCaption,
          ),
          const SizedBox(height: 14),
          if (showBudgetSection)
            Row(
              children: [
                const Text(
                  'Ngân sách',
                  style: TextStyle(
                    fontSize: 42 / 1.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F2F37),
                  ),
                ),
                const SizedBox(width: 8),
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
                const Spacer(),
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
                      color: Color(0xFFF12D9D),
                    ),
                  ),
                ),
              ],
            )
          else
            const Text(
              'Tóm tắt',
              style: TextStyle(
                fontSize: 42 / 1.5,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F2F37),
              ),
            ),
          const SizedBox(height: 10),
          if (showBudgetSection)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8E3EE)),
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
                              const TextSpan(text: ' - Chi 2 ngày tới'),
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
                border: Border.all(color: const Color(0xFFE8E3EE)),
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
                          color: Color(0xFF2F2F37),
                        ),
                      ),
                    ],
                  ),
                  if (widget.info.type == TransactionType.expense && _monthMode)
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
                                color: Color(0xFFF12D9D),
                                fontSize: 32 / 1.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFFF12D9D),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
          const Text(
            'Giao dịch',
            style: TextStyle(
              fontSize: 42 / 1.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F2F37),
            ),
          ),
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
          if (_successMessage != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF38C653),
                borderRadius: BorderRadius.circular(16),
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
          ],
          if (_txnTab == _DetailTxnTab.all)
            _buildAllTransactions(transactions)
          else if (_txnTab == _DetailTxnTab.topSpending)
            _buildTopSpending(transactions)
          else
            _buildTopReceivers(transactions),
        ],
      ),
    );
  }
}

class _CategoryPeriodPoint {
  const _CategoryPeriodPoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _TopReceiverAggregate {
  const _TopReceiverAggregate({
    required this.name,
    required this.total,
    required this.count,
    required this.icon,
  });

  final String name;
  final double total;
  final int count;
  final IconData icon;
}

class _CategoryHistoryChart extends StatelessWidget {
  const _CategoryHistoryChart({
    required this.points,
    required this.average,
    required this.hideAmounts,
    required this.highlightColor,
    required this.caption,
    this.referenceLineValue,
    this.referenceLineColor,
  });

  final List<_CategoryPeriodPoint> points;
  final double average;
  final bool hideAmounts;
  final Color highlightColor;
  final String caption;
  final double? referenceLineValue;
  final Color? referenceLineColor;

  String _money(double value) {
    if (hideAmounts) {
      return '******';
    }
    final raw = Formatters.currency(value).replaceFirst(RegExp(r'^VND\s*'), '');
    return '$rawđ';
  }

  @override
  Widget build(BuildContext context) {
    final referenceValue = referenceLineValue ?? average;
    final lineColor = referenceLineColor ?? const Color(0xFFF12D9D);
    final maxValue = [
      referenceValue,
      ...points.map((item) => item.amount),
      1.0,
    ].reduce(math.max);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3EE)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const chartHeight = 150.0;
                final avgTop =
                    chartHeight - (referenceValue / maxValue * chartHeight);

                return Stack(
                  children: [
                    Positioned(
                      left: 4,
                      right: 4,
                      top: avgTop,
                      child: _DashedHorizontalLine(
                        color: lineColor,
                        dashWidth: 10,
                        gapWidth: 6,
                        height: 2,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: (avgTop - 18).clamp(0.0, 150.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _money(referenceValue),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18 / 1.2,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(points.length, (index) {
                          final point = points[index];
                          final hasSpending = point.amount > 0;
                          final barHeight = hasSpending
                              ? (point.amount / maxValue * chartHeight)
                                    .clamp(12.0, chartHeight)
                                    .toDouble()
                              : 0.0;
                          final selected = index == points.length - 1;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (hasSpending)
                                    Container(
                                      height: barHeight,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? highlightColor
                                            : const Color(0xFFBCD1E6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    )
                                  else
                                    const SizedBox(height: 0),
                                  const SizedBox(height: 8),
                                  Text(
                                    point.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF1A78EE)
                                          : const Color(0xFF4A4A52),
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      fontSize: 18 / 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DashedHorizontalLine(
                color: lineColor,
                dashWidth: 7,
                gapWidth: 4,
                height: 2,
                width: 32,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  caption,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6D6D76),
                    fontSize: 18 / 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedHorizontalLine extends StatelessWidget {
  const _DashedHorizontalLine({
    required this.color,
    required this.dashWidth,
    required this.gapWidth,
    required this.height,
    this.width,
  });

  final Color color;
  final double dashWidth;
  final double gapWidth;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    Widget child = LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final dashCount = (totalWidth / (dashWidth + gapWidth)).floor().clamp(
          1,
          1000,
        );

        return Row(
          children: List.generate(dashCount, (index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index == dashCount - 1 ? 0 : gapWidth,
              ),
              child: Container(width: dashWidth, height: height, color: color),
            );
          }),
        );
      },
    );

    if (width != null) {
      child = SizedBox(width: width, child: child);
    }

    return SizedBox(height: height, child: child);
  }
}

class _BudgetTxnFilterChip extends StatelessWidget {
  const _BudgetTxnFilterChip({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFFE1F2) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? const Color(0xFFF05DB2) : const Color(0xFFE8E3EE),
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: active
                    ? const Color(0xFFF12D9D)
                    : const Color(0xFF33333B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? const Color(0xFFF12D9D)
                      : const Color(0xFF33333B),
                  fontSize: 19 / 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  const _CategoryLegend({
    required this.color,
    required this.percent,
    required this.label,
  });

  final Color color;
  final String percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.square_rounded, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              percent,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6E6E77),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TimeRangeChip extends StatelessWidget {
  const _TimeRangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFEDF7) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFFF59ACE) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: selected
                    ? const Color(0xFFF63FA7)
                    : const Color(0xFF3A3A42),
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeMonthChip extends StatelessWidget {
  const _TimeMonthChip({
    required this.label,
    required this.selected,
    required this.disabled,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF12D9D) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : disabled
                    ? const Color(0xFFC6C6CE)
                    : const Color(0xFF404048),
                fontSize: 18,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UtilitySheetEntry {
  const _UtilitySheetEntry({
    required this.action,
    required this.icon,
    required this.label,
    this.badge,
    this.badgeWidth,
  });

  final _FinanceUtilityAction action;
  final IconData icon;
  final String label;
  final String? badge;
  final double? badgeWidth;
}

class _UtilitySheetItem extends StatelessWidget {
  const _UtilitySheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeWidth,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final double? badgeWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF8FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: const Color(0xFF22C6C3), size: 31),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        height: 26,
                        width: badgeWidth,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3C50),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.28,
                  color: Color(0xFF55555E),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySlice {
  const _CategorySlice({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final double amount;
  final Color color;
}
