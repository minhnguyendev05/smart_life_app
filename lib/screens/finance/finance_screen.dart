import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_category.dart';
import '../../models/finance_recurring_transaction.dart';
import '../../models/finance_transaction.dart';
import '../../providers/finance_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/receipt_ocr_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_toast.dart';
import 'finance_shared_widgets.dart';
import 'finance_styles.dart';

part 'finance_supporting_widgets.dart';
part 'finance_budget_screens.dart';
part 'finance_transaction_entry_screen.dart';
part 'finance_flow_change_screen.dart';
part 'finance_classify_transactions_screen.dart';
part 'finance_category_manager_screen.dart';
part 'finance_recurring_flow_screens.dart';

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

  static const Color _screenBackground = FinanceColors.background;
  static const Color _panelBackground = FinanceColors.surface;
  static const Color _borderColor = FinanceColors.border;
  static const Color _accentPink = FinanceColors.accentSecondary;

  static const List<Color> _chartPaletteExtended = [
    Color(0xFF4CCFB0),
    Color(0xFF5FB9F6),
    Color(0xFFF26A83),
    Color(0xFFF6B348),
    Color(0xFF77D1C9),
    Color(0xFF7C8CFF),
    Color(0xFF4ECDC4),
    Color(0xFFF7C948),
    Color(0xFFFF8A5B),
    Color(0xFFB39DDB),
    Color(0xFF4FBF8A),
    Color(0xFF6C9FF5),
  ];

  static const List<IconData> _fallbackExpenseIcons = [
    Icons.local_cafe_outlined,
    Icons.local_grocery_store_outlined,
    Icons.local_gas_station_outlined,
    Icons.directions_bus_outlined,
    Icons.sports_esports_outlined,
    Icons.sports_soccer_outlined,
    Icons.pets_outlined,
    Icons.music_note_outlined,
    Icons.school_outlined,
    Icons.local_hospital_outlined,
    Icons.umbrella_outlined,
    Icons.phone_iphone_outlined,
  ];

  static const List<IconData> _fallbackIncomeIcons = [
    Icons.payments_outlined,
    Icons.credit_card_outlined,
    Icons.savings_outlined,
    Icons.workspace_premium_outlined,
    Icons.card_giftcard_outlined,
    Icons.attach_money_outlined,
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
  int _selectedTrendIndex = 2;
  _ExpenseBreakdownTab _expenseBreakdownTab = _ExpenseBreakdownTab.child;
  final Map<String, double> _customCategoryMonthlyBudgets = {};
  final Set<String> _expandedExpenseParents = {
    'Chi phí cố định',
    'Chi phí phát sinh',
  };
  String? _selectedAllocationCategory;
  Color? _selectedAllocationColor;
  String? _selectedAllocationPercent;
  Offset? _selectedAllocationOffset;

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
    final trendRanges = [olderRange, previousRange, currentRange];
    final selectedTrendIndex = _selectedTrendIndex
        .clamp(0, trendRanges.length - 1)
        .toInt();
    final selectedRange = trendRanges[selectedTrendIndex];
    final selectedPreviousRange = _resolvePreviousRange(selectedRange);
    final scopedTransactions = _transactionsInRange(
      source: provider.transactions,
      range: selectedRange,
    );
    final monthExpense = _sumAmount(
      scopedTransactions,
      TransactionType.expense,
    );
    final monthIncome = _sumAmount(scopedTransactions, TransactionType.income);
    final previousExpense = _sumAmount(
      _transactionsInRange(
        source: provider.transactions,
        range: selectedPreviousRange,
        type: TransactionType.expense,
      ),
      TransactionType.expense,
    );
    final previousIncome = _sumAmount(
      _transactionsInRange(
        source: provider.transactions,
        range: selectedPreviousRange,
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
      _sumAmount(
        _transactionsInRange(
          source: provider.transactions,
          range: currentRange,
          type: _focusType,
        ),
        _focusType,
      ),
    ];
    final trendLabels = [
      _trendLabelForRange(olderRange),
      _trendLabelForRange(previousRange),
      _trendLabelForRange(currentRange),
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
              periodLabel: _rangeLabel(selectedRange),
              expense: monthExpense,
              income: monthIncome,
              focusCurrent: focusCurrent,
              focusPrevious: focusPrevious,
              focusType: _focusType,
              categorySlices: categorySlices,
              totalCategoryAmount: totalCategoryAmount,
              trendSeries: trendSeries,
              trendLabels: trendLabels,
              trendSelectedIndex: selectedTrendIndex,
              onTrendSelected: (index) {
                if (index == selectedTrendIndex) {
                  return;
                }
                setState(() {
                  _selectedTrendIndex = index;
                });
              },
              periodBudget: periodBudget,
            ),
            const SizedBox(height: 14),
            _buildBudgetSection(
              cards: budgetCards,
              periodBudget: periodBudget,
              periodLabel: _rangeLabel(selectedRange),
              range: selectedRange,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 8,
            vertical: compact ? 8 : 10,
          ),
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
                  compact: compact,
                  onTap: _openTransactionEntry,
                ),
              ),
              Expanded(
                child: _QuickActionItem(
                  icon: Icons.show_chart_rounded,
                  label: 'Biến động\nthu chi',
                  iconColor: const Color(0xFF22C6C3),
                  compact: compact,
                  onTap: _openFlowChangeScreen,
                ),
              ),
              Expanded(
                child: _QuickActionItem(
                  icon: Icons.sell_outlined,
                  label: 'Phân loại\ngiao dịch',
                  iconColor: const Color(0xFF22C6C3),
                  badgeCount: 1,
                  compact: compact,
                  onTap: () => setState(() => _showCategoryDetails = true),
                ),
              ),
              Expanded(
                child: _QuickActionItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Tiện ích\nkhác',
                  iconColor: const Color(0xFF22C6C3),
                  compact: compact,
                  onTap: _showUtilitiesBottomSheet,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader() {
    final allocationActive = !_showTrendView;
    final trendActive = _showTrendView;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
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
                    onPressed: () =>
                        setState(() => _hideAmounts = !_hideAmounts),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
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
              padding: EdgeInsets.all(compact ? 3 : 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEF6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: FinanceColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _showTrendView = false),
                    child: Ink(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 10,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 10,
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
      },
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
    required List<String> trendLabels,
    required int trendSelectedIndex,
    required ValueChanged<int> onTrendSelected,
    required double periodBudget,
  }) {
    final delta = focusPrevious - focusCurrent;
    final reduced = delta >= 0;
    final changeColor = _changeColorForFocus(
      focusType: focusType,
      reduced: reduced,
    );
    final canMovePrevious = _canMovePeriod(-1);
    final canMoveNext = _canMovePeriod(1);

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
                onPressed: canMovePrevious ? () => _movePeriod(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: canMovePrevious
                    ? const Color(0xFF70707A)
                    : const Color(0xFFC1C1C9),
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
                onPressed: canMoveNext ? () => _movePeriod(1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: canMoveNext
                    ? const Color(0xFF70707A)
                    : const Color(0xFFC1C1C9),
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
                    focusType: focusType,
                  )
                : _buildTrendChart(
                    key: const ValueKey('trend-view'),
                    values: trendSeries,
                    labels: trendLabels,
                    selectedIndex: trendSelectedIndex,
                    onSelectIndex: onTrendSelected,
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
    required TransactionType focusType,
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
        final percents = categorySlices
            .map((slice) => slice.amount / totalExpense)
            .toList();
        final minAboveOne = percents
            .where((value) => value >= 0.01)
            .fold<double>(double.infinity, math.min);
        final minDisplayPercent = minAboveOne.isFinite
            ? math.min(0.05, minAboveOne * 0.8)
            : 0.05;
        final minValue = totalExpense * minDisplayPercent;
        final sectionSpace = categorySlices.length > 6 ? 2.0 : 3.0;

        return Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: categorySlices
                  .map(
                    (slice) => _CategoryLegend(
                      color: slice.color,
                      percent: _percentLabel(slice.amount, totalExpense),
                      label: slice.name,
                      icon: focusType == TransactionType.income
                          ? _iconForIncomeCategory(slice.name)
                          : _iconForBudgetCategory(slice.name),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: size * 0.28,
                      sectionsSpace: sectionSpace,
                      borderData: FlBorderData(show: false),
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (event, response) {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            if (_selectedAllocationCategory != null) {
                              setState(() {
                                _selectedAllocationCategory = null;
                                _selectedAllocationColor = null;
                                _selectedAllocationPercent = null;
                                _selectedAllocationOffset = null;
                              });
                            }
                            return;
                          }
                          final localPosition = event.localPosition;
                          final index =
                              response.touchedSection!.touchedSectionIndex;
                          if (index < 0 || index >= categorySlices.length) {
                            return;
                          }
                          final slice = categorySlices[index];
                          setState(() {
                            _selectedAllocationCategory = slice.name;
                            _selectedAllocationColor = slice.color;
                            _selectedAllocationPercent = _percentLabel(
                              slice.amount,
                              totalExpense,
                            );
                            _selectedAllocationOffset = localPosition;
                          });
                        },
                      ),
                      sections: categorySlices.map((slice) {
                        final percent = slice.amount / totalExpense;
                        final displayValue = percent < 0.01
                            ? minValue
                            : slice.amount;
                        return PieChartSectionData(
                          value: displayValue,
                          color: slice.color,
                          radius: size * 0.18,
                          title: '',
                        );
                      }).toList(),
                    ),
                  ),
                  if (_selectedAllocationCategory != null)
                    Builder(
                      builder: (_) {
                        final selectedCategory = _selectedAllocationCategory!;
                        final selectedIcon = focusType == TransactionType.income
                            ? _iconForIncomeCategory(selectedCategory)
                            : _iconForBudgetCategory(selectedCategory);
                        final bubbleWidth = size * 0.56;
                        final bubbleHeight = _selectedAllocationPercent == null
                            ? 40.0
                            : 56.0;
                        final offset =
                            _selectedAllocationOffset ??
                            Offset(size / 2, size / 2);
                        final maxLeft = size - bubbleWidth - 6;
                        final desiredLeft = offset.dx - bubbleWidth / 2;
                        final left = desiredLeft.clamp(
                          6.0,
                          maxLeft < 6 ? 6.0 : maxLeft,
                        );
                        final preferTop = offset.dy - bubbleHeight - 8;
                        final preferBottom = offset.dy + 8;
                        final maxTop = size - bubbleHeight - 6;
                        final top = (preferTop < 6)
                            ? preferBottom.clamp(6.0, maxTop < 6 ? 6.0 : maxTop)
                            : preferTop.clamp(6.0, maxTop < 6 ? 6.0 : maxTop);

                        return Positioned(
                          left: left,
                          top: top,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: _selectedAllocationCategory != null
                                ? 1
                                : 0,
                            child: Container(
                              width: bubbleWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE6E2EC),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x16000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color:
                                              (_selectedAllocationColor ??
                                                      FinanceColors.textStrong)
                                                  .withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                        ),
                                        child: Icon(
                                          selectedIcon,
                                          size: 14,
                                          color:
                                              _selectedAllocationColor ??
                                              FinanceColors.textStrong,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          selectedCategory,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color:
                                                _selectedAllocationColor ??
                                                FinanceColors.textStrong,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_selectedAllocationPercent != null)
                                    Text(
                                      _selectedAllocationPercent!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6D6D76),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
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
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onSelectIndex,
  }) {
    final hasData = values.any((item) => item > 0);
    final maxRaw = hasData ? values.reduce(math.max) : 0.0;
    final divisor = maxRaw >= 1000000 ? 1000000.0 : 1000.0;
    final unitLabel = maxRaw >= 1000000 ? '(Triệu)' : '(Nghìn)';
    final normalized = values.map((item) => item / divisor).toList();
    final maxY = (normalized.reduce(math.max) * 1.2).clamp(1.0, 999999.0);
    final resolvedSelectedIndex = selectedIndex
        .clamp(0, math.max(0, normalized.length - 1))
        .toInt();
    final barGroups = List.generate(normalized.length, (index) {
      final isCurrent = index == resolvedSelectedIndex;
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
    });

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
            child: FinanceAdvancedBarChart(
              barGroups: barGroups,
              labels: labels,
              selectedIndex: resolvedSelectedIndex,
              onSelectIndex: onSelectIndex,
              minY: 0,
              maxY: maxY.toDouble(),
              interval: maxY / 4,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 8,
              leftReservedSize: 36,
              bottomReservedSize: 32,
              bottomLabelHeight: 18,
              leftLabelBuilder: (value) {
                if (value == value.roundToDouble()) {
                  return value.toInt().toString();
                }
                return value.toStringAsFixed(1);
              },
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
        FinanceCurvedDualTabBar(
          leftLabel: 'Danh mục con',
          rightLabel: 'Danh mục cha',
          selectedIndex: _expenseBreakdownTab == _ExpenseBreakdownTab.child
              ? 0
              : 1,
          tabHeight: 42,
          onChanged: (index) => setState(
            () => _expenseBreakdownTab = index == 0
                ? _ExpenseBreakdownTab.child
                : _ExpenseBreakdownTab.parent,
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
                          color: FinanceColors.textStrong,
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
      hasCustomBudget: customMonthly != null,
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

  Color _categoryColorFor(String name, int index) {
    if (index < _chartPaletteExtended.length) {
      return _chartPaletteExtended[index];
    }
    final seed = name.toLowerCase().hashCode & 0x7fffffff;
    final hue = (seed % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.55, 0.85).toColor();
  }

  IconData _fallbackIconFor(String name, List<IconData> options) {
    if (options.isEmpty) {
      return Icons.category_outlined;
    }
    final seed = name.toLowerCase().hashCode & 0x7fffffff;
    return options[seed % options.length];
  }

  IconData _iconForIncomeCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('lương')) {
      return Icons.badge_outlined;
    }
    if (lower.contains('thưởng')) {
      return Icons.workspace_premium_outlined;
    }
    if (lower.contains('freelance') || lower.contains('tự do')) {
      return Icons.laptop_mac_outlined;
    }
    if (lower.contains('hỗ trợ') || lower.contains('gia đình')) {
      return Icons.favorite_border_rounded;
    }
    if (lower.contains('bán') || lower.contains('kinh doanh')) {
      return Icons.storefront_outlined;
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
    return _fallbackIconFor(category, _fallbackIncomeIcons);
  }

  Widget _buildBudgetSection({
    required List<_BudgetCardInfo> cards,
    required double periodBudget,
    required String periodLabel,
    required _FinanceRangeWindow range,
  }) {
    final totalSpent = cards.isEmpty ? 0.0 : cards.first.spent;
    final effectiveBudget = cards.isEmpty
        ? periodBudget
        : cards.first.allocated;
    final hasConfiguredBudget = effectiveBudget > 0;
    final remaining = effectiveBudget - totalSpent;
    final isOverBudget = hasConfiguredBudget && remaining < 0;

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
                  range: range,
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
                  !hasConfiguredBudget
                      ? Icons.info_outline_rounded
                      : isOverBudget
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  color: !hasConfiguredBudget
                      ? const Color(0xFF6F6F78)
                      : isOverBudget
                      ? const Color(0xFFD84A4A)
                      : const Color(0xFF2CBF67),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    !hasConfiguredBudget
                        ? 'Bạn chưa thiết lập ngân sách. Nhấn "Tạo ngân sách" để bắt đầu.'
                        : isOverBudget
                        ? 'Bạn đã vượt ngân sách ${_compactCurrency(remaining.abs())}'
                        : 'Còn lại ${_compactCurrency(remaining)} trong ngân sách',
                    style: TextStyle(
                      color: !hasConfiguredBudget
                          ? const Color(0xFF575761)
                          : isOverBudget
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
                    onTap: () => _openCreateBudget(
                      periodLabel: periodLabel,
                      range: range,
                    ),
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
                        range: range,
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
    required _FinanceRangeWindow range,
  }) async {
    final provider = context.read<FinanceProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _BudgetOverviewScreen(
          cards: cards,
          periodBudget: periodBudget,
          periodLabel: periodLabel,
          timeRange: _timeRange,
          periodStart: range.start,
          periodEnd: range.end,
          totalMonthlyBudget: provider.monthlyBudget,
          customMonthlyBudgets: Map<String, double>.from(
            _customCategoryMonthlyBudgets,
          ),
          hideAmounts: _hideAmounts,
          onCreateBudget: () =>
              _openCreateBudget(periodLabel: periodLabel, range: range),
          onOpenCategory: (item) {
            _openBudgetCategory(info: item, periodLabel: periodLabel);
          },
          onMutateBudget:
              ({
                required info,
                monthlyBudget,
                required delete,
                required periodStart,
                required periodEnd,
              }) {
                return _mutateBudgetFromOverview(
                  info: info,
                  monthlyBudget: monthlyBudget,
                  delete: delete,
                  periodStart: periodStart,
                  periodEnd: periodEnd,
                );
              },
        ),
      ),
    );
  }

  _BudgetOverviewData _buildOverviewDataForRange(
    FinanceProvider provider,
    _FinanceRangeWindow range,
  ) {
    final scopedTransactions = _transactionsInRange(
      source: provider.transactions,
      range: range,
      type: TransactionType.expense,
    );
    final periodBudget = _budgetForCurrentRange(provider.monthlyBudget);
    final cards = _buildBudgetCards(
      transactions: scopedTransactions,
      periodBudget: periodBudget,
    );

    return _BudgetOverviewData(
      cards: cards,
      periodBudget: periodBudget,
      periodLabel: _rangeLabel(range),
      timeRange: _timeRange,
      periodStart: range.start,
      periodEnd: range.end,
      totalMonthlyBudget: provider.monthlyBudget,
      customMonthlyBudgets: Map<String, double>.from(
        _customCategoryMonthlyBudgets,
      ),
    );
  }

  Future<_BudgetOverviewData> _mutateBudgetFromOverview({
    required _BudgetCardInfo info,
    double? monthlyBudget,
    required bool delete,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final provider = context.read<FinanceProvider>();

    if (info.isTotal) {
      if (delete) {
        await provider.updateBudget(0);
      } else if (monthlyBudget != null) {
        final safeBudget = monthlyBudget < 0 ? 0.0 : monthlyBudget;
        await provider.updateBudget(safeBudget);
      }
    } else {
      setState(() {
        if (delete) {
          _customCategoryMonthlyBudgets.remove(info.title);
        } else if (monthlyBudget != null) {
          final safeBudget = monthlyBudget < 0 ? 0.0 : monthlyBudget;
          _customCategoryMonthlyBudgets[info.title] = safeBudget;
        }
      });
    }

    return _buildOverviewDataForRange(
      provider,
      _FinanceRangeWindow(start: periodStart, end: periodEnd),
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

  Future<void> _openCreateBudget({
    required String periodLabel,
    _FinanceRangeWindow? range,
  }) async {
    final provider = context.read<FinanceProvider>();
    final currentRange = range ?? _resolveCurrentRange();
    final existingCategories = {..._customCategoryMonthlyBudgets.keys};
    if (provider.monthlyBudget > 0) {
      existingCategories.add('Tổng chi tiêu trong tháng');
    }

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

    final isTotalBudgetCategory =
        result.category.trim().toLowerCase() ==
        'tổng chi tiêu trong tháng'.toLowerCase();

    if (isTotalBudgetCategory) {
      final scopedTransactions = _transactionsInRange(
        source: provider.transactions,
        range: currentRange,
        type: TransactionType.expense,
      );
      await provider.updateBudget(result.monthlyBudget);

      final refreshedPeriodBudget = _budgetForCurrentRange(
        provider.monthlyBudget,
      );
      final refreshedCards = _buildBudgetCards(
        transactions: scopedTransactions,
        periodBudget: refreshedPeriodBudget,
      );
      final totalCard = refreshedCards.firstWhere(
        (item) => item.isTotal,
        orElse: () => _BudgetCardInfo(
          title: 'Ngân sách tổng',
          allocated: refreshedPeriodBudget,
          spent: scopedTransactions.fold(0.0, (sum, tx) => sum + tx.amount),
          icon: Icons.account_balance_wallet_outlined,
          accentColor: const Color(0xFF1BB7B8),
          isTotal: true,
          type: TransactionType.expense,
        ),
      );

      await _openBudgetCategory(
        info: totalCard,
        periodLabel: periodLabel,
        successMessage: 'Tạo hạn mức chi tiêu thành công!',
      );
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
      hasCustomBudget: true,
    );

    await _openBudgetCategory(
      info: info,
      periodLabel: periodLabel,
      successMessage: 'Tạo hạn mức chi tiêu thành công!',
    );
  }

  Future<void> _openTransactionEntry() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TransactionEntryScreen(
          expenseCategories: _expenseCategories,
          incomeCategories: _incomeCategories,
          iconForExpenseCategory: _iconForBudgetCategory,
          iconForIncomeCategory: _iconForIncomeCategory,
        ),
      ),
    );
  }

  Future<void> _openFlowChangeScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FlowChangeScreen(
          iconForIncomeCategory: _iconForIncomeCategory,
          iconForExpenseCategory: _iconForBudgetCategory,
        ),
      ),
    );
  }

  Future<void> _openClassifyTransactionsScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ClassifyTransactionsScreen(
          iconForIncomeCategory: _iconForIncomeCategory,
          iconForExpenseCategory: _iconForBudgetCategory,
        ),
      ),
    );
  }

  Future<void> _openCategoryManagerScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CategoryManagerScreen(
          iconForIncomeCategory: _iconForIncomeCategory,
          iconForExpenseCategory: _iconForBudgetCategory,
        ),
      ),
    );
  }

  // ignore: unused_element
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        itemCount: _utilityEntries.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: compact ? 10 : 14,
                          crossAxisSpacing: compact ? 8 : 10,
                          childAspectRatio: compact ? 0.58 : 0.66,
                        ),
                        itemBuilder: (context, index) {
                          final item = _utilityEntries[index];
                          return _UtilitySheetItem(
                            icon: item.icon,
                            label: item.label,
                            badge: item.badge,
                            badgeWidth: item.badgeWidth,
                            compact: compact,
                            onTap: () {
                              Navigator.pop(ctx);
                              _handleUtilityAction(item.action);
                            },
                          );
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
        _openTransactionEntry();
        return;
      case _FinanceUtilityAction.flowChange:
        _openFlowChangeScreen();
        return;
      case _FinanceUtilityAction.categorize:
        _openClassifyTransactionsScreen();
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
        _openCategoryManagerScreen();
        return;
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
    final provider = context.read<FinanceProvider>();
    final now = DateTime.now();
    var tempRange = _timeRange;
    var tempYear = _anchorDate.year;
    var tempMonth = _anchorDate.month;
    var tempDay = _anchorDate.day;
    var tempWeekStart = _weekStart(_anchorDate);
    final oldestTransactionYear = _oldestTransactionYear(provider.transactions);

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

            final yearChoices = _yearChoices(
              selectedYear: tempYear,
              currentYear: now.year,
              oldestTransactionYear: oldestTransactionYear,
            );
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
      _selectedTrendIndex = 2;
    });
  }

  void _movePeriod(int delta) {
    if (!_canMovePeriod(delta)) {
      return;
    }

    final anchor = _anchorDate;
    setState(() {
      _selectedTrendIndex = 2;
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

  bool _canMovePeriod(int delta) {
    if (delta < 0) {
      return true;
    }

    final anchor = _anchorDate;
    final now = DateTime.now();

    switch (_timeRange) {
      case _FinanceTimeRange.week:
        final targetWeekStart = _weekStart(
          anchor.add(Duration(days: 7 * delta)),
        );
        final currentWeekStart = _weekStart(now);
        return !targetWeekStart.isAfter(currentWeekStart);
      case _FinanceTimeRange.month:
        final targetMonthStart = DateTime(anchor.year, anchor.month + delta, 1);
        final currentMonthStart = DateTime(now.year, now.month, 1);
        return !targetMonthStart.isAfter(currentMonthStart);
      case _FinanceTimeRange.year:
        final targetYearStart = DateTime(anchor.year + delta, 1, 1);
        final currentYearStart = DateTime(now.year, 1, 1);
        return !targetYearStart.isAfter(currentYearStart);
    }
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
    final hasConfiguredBudget =
        periodBudget > 0 || customPeriodBudgetByCategory.isNotEmpty;
    final totalAllocated = !hasConfiguredBudget
        ? 0.0
        : customPeriodBudgetByCategory.isEmpty
        ? periodBudget
        : customPeriodBudgetByCategory.values.fold<double>(
            0.0,
            (sum, item) => sum + item,
          );
    final totalSpentForBudget = hasConfiguredBudget ? totalSpent : 0.0;

    final cards = <_BudgetCardInfo>[
      _BudgetCardInfo(
        title: 'Ngân sách tổng',
        allocated: totalAllocated,
        spent: totalSpentForBudget,
        icon: Icons.savings_outlined,
        accentColor: const Color(0xFF1CC5C7),
        isTotal: true,
        hasCustomBudget: totalAllocated > 0,
      ),
    ];

    if (!hasConfiguredBudget) {
      return cards;
    }

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
          hasCustomBudget: customPeriodBudgetByCategory.containsKey(category),
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
    if (lower.contains('cà phê') || lower.contains('cafe')) {
      return Icons.coffee_outlined;
    }
    if (lower.contains('điện') || lower.contains('điện lực')) {
      return Icons.electrical_services_outlined;
    }
    if (lower.contains('nước')) {
      return Icons.water_drop_outlined;
    }
    if (lower.contains('internet') || lower.contains('wifi')) {
      return Icons.wifi_rounded;
    }
    if (lower.contains('điện thoại') || lower.contains('phone')) {
      return Icons.phone_iphone_outlined;
    }
    if (lower.contains('xăng') || lower.contains('nhiên liệu')) {
      return Icons.local_gas_station_outlined;
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
    if (lower.contains('siêu thị')) {
      return Icons.local_grocery_store_outlined;
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
    if (lower.contains('sức khỏe') || lower.contains('y tế')) {
      return Icons.favorite_outline_rounded;
    }
    if (lower.contains('thể thao')) {
      return Icons.sports_soccer_outlined;
    }
    if (lower.contains('du lịch') || lower.contains('travel')) {
      return Icons.flight_takeoff_outlined;
    }
    if (lower.contains('từ thiện')) {
      return Icons.volunteer_activism_outlined;
    }
    if (lower.contains('tổng')) {
      return Icons.account_balance_wallet_outlined;
    }
    return _fallbackIconFor(category, _fallbackExpenseIcons);
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

  String _trendLabelForRange(_FinanceRangeWindow range) {
    final now = DateTime.now();
    switch (_timeRange) {
      case _FinanceTimeRange.week:
        if (_isSameWeek(range.start, now)) {
          return 'Tuần này';
        }
        return 'T${_weekOfYear(range.start)}';
      case _FinanceTimeRange.month:
        if (range.start.year == now.year && range.start.month == now.month) {
          return 'Tháng này';
        }
        return range.start.month == 1
            ? '1/${range.start.year}'
            : '${range.start.month}';
      case _FinanceTimeRange.year:
        if (range.start.year == now.year) {
          return 'Năm nay';
        }
        return '${range.start.year}';
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

  List<int> _yearChoices({
    required int selectedYear,
    required int currentYear,
    int? oldestTransactionYear,
  }) {
    // Always keep a usable baseline range, then expand backward if data is older.
    final baselineStart = currentYear - 10;
    final startYear = math.min(
      math.min(baselineStart, selectedYear),
      oldestTransactionYear ?? baselineStart,
    );
    final endYear = math.max(currentYear, selectedYear);

    return List<int>.generate(
      endYear - startYear + 1,
      (index) => startYear + index,
    );
  }

  int? _oldestTransactionYear(List<FinanceTransaction> transactions) {
    if (transactions.isEmpty) {
      return null;
    }

    var oldestYear = transactions.first.createdAt.year;
    for (final item in transactions.skip(1)) {
      if (item.createdAt.year < oldestYear) {
        oldestYear = item.createdAt.year;
      }
    }
    return oldestYear;
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

    return List.generate(entries.length, (index) {
      final item = entries[index];
      return _CategorySlice(
        name: item.key,
        amount: item.value,
        color: _categoryColorFor(item.key, index),
      );
    });
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
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
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
                  FinanceMoneySuggestionChips(
                    suggestions: const [100000, 1000000, 10000000],
                    onSelected: (amount) {
                      amountCtrl.text = amount.toStringAsFixed(0);
                    },
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
