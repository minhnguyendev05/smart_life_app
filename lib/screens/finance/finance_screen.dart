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

  static const Color _screenBackground = Color(0xFFF4F2F8);
  static const Color _panelBackground = Colors.white;
  static const Color _borderColor = Color(0xFFE8E3EE);
  static const Color _accentPink = Color(0xFFF63FA7);
  static const Color _accentMint = Color(0xFF4CCFB0);
  static const Color _accentOrange = Color(0xFFF6A93B);

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
  TransactionType? _filterType;
  _FinanceTimeRange _timeRange = _FinanceTimeRange.month;
  final _ocrService = ReceiptOcrService();
  bool _hideAmounts = false;
  bool _showCategoryDetails = true;
  bool _showAllocationView = true;

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
    final scopedTransactions = _transactionsInRange(
      source: provider.transactions,
      range: currentRange,
    );
    final filtered = _filterType == null
        ? scopedTransactions
        : scopedTransactions.where((item) => item.type == _filterType).toList();
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
    final categorySlices = _buildCategorySlices(
      _expenseByCategory(scopedTransactions),
    );
    final totalCategoryExpense = categorySlices.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final recentTransactions = filtered.take(5).toList();

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
              previousExpense: previousExpense,
              categorySlices: categorySlices,
              totalExpense: totalCategoryExpense,
            ),
            const SizedBox(height: 12),
            _buildInsightStrip(),
            if (recentTransactions.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildRecentTransactions(recentTransactions),
            ],
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
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                'Tình hình thu chi',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2F2F36),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => setState(() => _hideAmounts = !_hideAmounts),
                visualDensity: VisualDensity.compact,
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
            color: _panelBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _showAllocationView = true),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _showAllocationView
                        ? const Color(0xFFFFEBF6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pie_chart_outline_rounded,
                        size: 18,
                        color: _accentPink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Phân bổ',
                        style: TextStyle(
                          color: _accentPink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _showAllocationView = false),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: !_showAllocationView
                        ? const Color(0xFFEFEAF6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, size: 20),
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
    required double previousExpense,
    required List<_CategorySlice> categorySlices,
    required double totalExpense,
  }) {
    final delta = previousExpense - expense;
    final reduced = delta >= 0;

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
                child: _SummaryAmountCard(
                  label: 'Chi tiêu',
                  value: _formatAmount(expense),
                  leadingIcon: Icons.outbound_rounded,
                  trailingIcon: Icons.south_rounded,
                  accentColor: _accentPink,
                  trailingColor: const Color(0xFF2CCF73),
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryAmountCard(
                  label: 'Thu nhập',
                  value: _formatAmount(income),
                  leadingIcon: Icons.savings_outlined,
                  trailingIcon: Icons.south_rounded,
                  accentColor: const Color(0xFFE6E1EC),
                  trailingColor: const Color(0xFFFF7B32),
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
                  child: previousExpense <= 0
                      ? const Text(
                          'Chưa có dữ liệu tháng trước để so sánh',
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
                                  color: reduced
                                      ? const Color(0xFF2CBF67)
                                      : const Color(0xFFD84A4A),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const TextSpan(
                                text: 'so với cùng kỳ tháng trước',
                              ),
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
            child: _showAllocationView
                ? _buildAllocationChart(
                    key: const ValueKey('donut-view'),
                    categorySlices: categorySlices,
                    totalExpense: totalExpense,
                  )
                : _buildCategoryBars(
                    key: const ValueKey('bar-view'),
                    categorySlices: categorySlices,
                    totalExpense: totalExpense,
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
              child: Column(
                children: categorySlices.map((slice) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: slice.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            slice.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A4A52),
                            ),
                          ),
                        ),
                        Text(
                          _percentLabel(slice.amount, totalExpense),
                          style: TextStyle(
                            color: slice.color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatAmount(slice.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF35353C),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
  }) {
    if (categorySlices.isEmpty || totalExpense <= 0) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: Text(
            'Chưa có dữ liệu chi tiêu tháng này',
            style: TextStyle(
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

  Widget _buildCategoryBars({
    Key? key,
    required List<_CategorySlice> categorySlices,
    required double totalExpense,
  }) {
    if (categorySlices.isEmpty || totalExpense <= 0) {
      return const SizedBox(
        key: ValueKey('empty-bar-view'),
        height: 220,
        child: Center(
          child: Text(
            'Chưa có dữ liệu phân bổ',
            style: TextStyle(
              color: Color(0xFF797983),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      key: key,
      children: categorySlices.take(5).map((slice) {
        final ratio = slice.amount / totalExpense;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      slice.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3D3D45),
                      ),
                    ),
                  ),
                  Text(
                    _percentLabel(slice.amount, totalExpense),
                    style: TextStyle(
                      color: slice.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFECEAF1),
                  color: slice.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInsightStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _panelBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFFFE4F3),
            child: Icon(Icons.face_4_outlined, color: _accentPink, size: 16),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'So sánh chi tiêu với người 20 tuổi',
              style: TextStyle(
                fontSize: 18 / 1.6,
                fontWeight: FontWeight.w700,
                color: Color(0xFF33333B),
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Color(0xFF88888F)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List<FinanceTransaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Giao dịch gần đây',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (_filterType != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBF6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _filterType == TransactionType.expense
                      ? 'Đang lọc: Chi'
                      : 'Đang lọc: Thu',
                  style: const TextStyle(
                    color: _accentPink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ...transactions.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: _panelBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
              ),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.type == TransactionType.income
                        ? const Color(0xFFE8FFF7)
                        : const Color(0xFFFFF3EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.type == TransactionType.income
                        ? Icons.south_rounded
                        : Icons.north_rounded,
                    color: item.type == TransactionType.income
                        ? const Color(0xFF2CCF73)
                        : _accentOrange,
                  ),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${item.category} • ${Formatters.dayTime(item.createdAt)}',
                ),
                trailing: Text(
                  _formatSignedAmount(item.type, item.amount),
                  style: TextStyle(
                    color: item.type == TransactionType.income
                        ? const Color(0xFF2CCF73)
                        : _accentOrange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
      if (_filterType == null) {
        _filterType = TransactionType.expense;
      } else if (_filterType == TransactionType.expense) {
        _filterType = TransactionType.income;
      } else {
        _filterType = null;
      }
    });

    if (_filterType == null) {
      _showHint('Đang hiển thị tất cả giao dịch trong kỳ hiện tại.');
      return;
    }
    if (_filterType == TransactionType.expense) {
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

  Map<String, double> _expenseByCategory(List<FinanceTransaction> source) {
    final map = <String, double>{};
    for (final item in source) {
      if (item.type != TransactionType.expense) continue;
      map[item.category] = (map[item.category] ?? 0) + item.amount;
    }
    return map;
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

  String _formatSignedAmount(TransactionType type, double amount) {
    final sign = type == TransactionType.income ? '+' : '-';
    if (_hideAmounts) {
      return '$sign******';
    }
    return '$sign${_compactCurrency(amount)}';
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
    return _SummaryAmountCard(
      label: label,
      value: value,
      leadingIcon: Icons.account_balance_wallet_outlined,
      trailingIcon: Icons.south_rounded,
      accentColor: color,
      trailingColor: color,
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
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;
  final int? badgeCount;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final baseColor = disabled ? const Color(0xFF9E9EA7) : iconColor;

    return Opacity(
      opacity: disabled ? 0.72 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : onTap,
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
                      child: Icon(icon, color: baseColor, size: 30),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? accentColor.withValues(alpha: 0.6) : accentColor,
          width: highlighted ? 2 : 1,
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
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(leadingIcon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3A3A42),
                    fontWeight: FontWeight.w600,
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
