import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_transaction.dart';
import '../../providers/finance_provider.dart';
import '../../utils/formatters.dart';
import 'finance_budget_screens.dart';
import 'finance_screen.dart';
import 'finance_shared_widgets.dart';
import 'finance_supporting_widgets.dart';
import 'finance_styles.dart';

enum _FlowMetricTab { income, expense, difference }

enum _FlowExpenseBreakdown { child, parent }

class _FlowRange {
  const _FlowRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _FlowBucket {
  const _FlowBucket({
    required this.range,
    required this.compareRange,
    required this.focusDate,
    required this.incomeSamePeriod,
    required this.expenseSamePeriod,
    required this.axisLabel,
    required this.listLabel,
    required this.income,
    required this.expense,
    required this.incomeCompare,
    required this.expenseCompare,
  });

  final _FlowRange range;
  final _FlowRange compareRange;
  final DateTime focusDate;
  final double incomeSamePeriod;
  final double expenseSamePeriod;
  final String axisLabel;
  final String listLabel;
  final double income;
  final double expense;
  final double incomeCompare;
  final double expenseCompare;
}

class _FlowCategoryDelta {
  const _FlowCategoryDelta({
    required this.name,
    required this.current,
    required this.delta,
  });

  final String name;
  final double current;
  final double delta;
}

class _FlowDifferenceRow {
  const _FlowDifferenceRow({
    required this.primaryLabel,
    this.secondaryLabel,
    required this.income,
    required this.expense,
  });

  final String primaryLabel;
  final String? secondaryLabel;
  final double income;
  final double expense;

  double get difference => income - expense;
}

class FinanceFlowChangeScreen extends StatefulWidget {
  const FinanceFlowChangeScreen({super.key, 
    required this.iconForIncomeCategory,
    required this.iconForExpenseCategory,
  });

  final IconData Function(String category) iconForIncomeCategory;
  final IconData Function(String category) iconForExpenseCategory;

  @override
  State<FinanceFlowChangeScreen> createState() => _FinanceFlowChangeScreenState();
}

class _FinanceFlowChangeScreenState extends State<FinanceFlowChangeScreen> {
  static const Color _positiveColor = Color(0xFF22BC58);
  static const Color _negativeColor = Color(0xFFFF5B2E);
  static const Color _neutralColor = Color(0xFF8E8E97);

  FinanceTimeRange _range = FinanceTimeRange.week;
  _FlowMetricTab _metric = _FlowMetricTab.expense;
  _FlowExpenseBreakdown _expenseBreakdown = _FlowExpenseBreakdown.child;
  bool _compareEnabled = true;
  int _selectedIndex = 5;
  bool _showCompareInfoHint = false;

  int _bucketCountForRange(FinanceTimeRange range) {
    return range == FinanceTimeRange.year ? 2 : 6;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _startOfWeek(DateTime value) {
    final day = _startOfDay(value);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  DateTime _clampedDate(int year, int month, int day) {
    final safeDay = day.clamp(1, _daysInMonth(year, month));
    return DateTime(year, month, safeDay);
  }

  DateTime _endExclusiveForDay(DateTime value) {
    return DateTime(value.year, value.month, value.day + 1);
  }

  String _d2(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _axisLabelForWeek(DateTime start, DateTime end, bool isCurrent) {
    final endDay = end.subtract(const Duration(days: 1));
    if (isCurrent) {
      return 'Tuần này';
    }
    if (start.month == endDay.month) {
      return '${_d2(start.day)}-${_d2(endDay.day)}';
    }
    return '${_d2(start.day)}/${_d2(start.month)}';
  }

  String _axisLabelForMonth(DateTime start, bool isCurrent) {
    if (isCurrent) {
      return 'Tháng này';
    }
    return 'T${start.month}';
  }

  String _axisLabelForYear(DateTime start, bool isCurrent) {
    if (isCurrent) {
      return 'Năm nay';
    }
    return 'Năm ${start.year}';
  }

  String _listLabelForWeek(DateTime start, DateTime end, bool isCurrent) {
    final endDay = end.subtract(const Duration(days: 1));
    if (isCurrent) {
      return '${_d2(start.day)}/${_d2(start.month)}\n${_d2(endDay.day)}/${_d2(endDay.month)}';
    }
    return '${_d2(start.day)} - ${_d2(endDay.day)}\nTháng ${_d2(start.month)}';
  }

  String _listLabelForMonth(DateTime start) {
    return '${start.month}\n${start.year}';
  }

  String _listLabelForYear(DateTime start) {
    return '${start.year}';
  }

  double _sumInRange(
    List<FinanceTransaction> transactions,
    _FlowRange range,
    TransactionType type,
  ) {
    return transactions
        .where((tx) {
          final inRange =
              !tx.createdAt.isBefore(range.start) &&
              tx.createdAt.isBefore(range.end);
          return inRange && tx.type == type;
        })
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Map<String, double> _sumByCategory(
    List<FinanceTransaction> transactions,
    _FlowRange range,
    TransactionType type,
  ) {
    final map = <String, double>{};
    for (final tx in transactions) {
      final inRange =
          !tx.createdAt.isBefore(range.start) &&
          tx.createdAt.isBefore(range.end);
      if (!inRange || tx.type != type) {
        continue;
      }
      map[tx.category] = (map[tx.category] ?? 0) + tx.amount;
    }
    return map;
  }

  List<_FlowBucket> _buildBuckets(List<FinanceTransaction> transactions) {
    final now = DateTime.now();
    final buckets = <_FlowBucket>[];

    switch (_range) {
      case FinanceTimeRange.week:
        final currentWeekStart = _startOfWeek(now);
        for (var i = 5; i >= 0; i--) {
          final start = currentWeekStart.subtract(Duration(days: i * 7));
          final end = start.add(const Duration(days: 7));
          final compareStart = start.subtract(const Duration(days: 7));
          final compareEnd = end.subtract(const Duration(days: 7));
          final isCurrent = i == 0;
          final range = _FlowRange(start: start, end: end);
          final compareRange = _FlowRange(start: compareStart, end: compareEnd);

          buckets.add(
            _FlowBucket(
              range: range,
              compareRange: compareRange,
              focusDate: start,
              incomeSamePeriod: _sumInRange(
                transactions,
                compareRange,
                TransactionType.income,
              ),
              expenseSamePeriod: _sumInRange(
                transactions,
                compareRange,
                TransactionType.expense,
              ),
              axisLabel: _axisLabelForWeek(start, end, isCurrent),
              listLabel: _listLabelForWeek(start, end, isCurrent),
              income: _sumInRange(transactions, range, TransactionType.income),
              expense: _sumInRange(
                transactions,
                range,
                TransactionType.expense,
              ),
              incomeCompare: _sumInRange(
                transactions,
                compareRange,
                TransactionType.income,
              ),
              expenseCompare: _sumInRange(
                transactions,
                compareRange,
                TransactionType.expense,
              ),
            ),
          );
        }
        return buckets;
      case FinanceTimeRange.month:
        final currentMonthStart = DateTime(now.year, now.month, 1);
        final today = _startOfDay(now);
        final cutoffDay = today.day;
        for (var i = 5; i >= 0; i--) {
          final start = DateTime(
            currentMonthStart.year,
            currentMonthStart.month - i,
            1,
          );
          final compareStart = DateTime(start.year, start.month - 1, 1);
          final isCurrent = i == 0;
          final periodEndDay = _clampedDate(start.year, start.month, cutoffDay);
          final samePeriodRange = _FlowRange(
            start: start,
            end: _endExclusiveForDay(periodEndDay),
          );
          final compareEndDay = _clampedDate(
            compareStart.year,
            compareStart.month,
            periodEndDay.day,
          );
          final end = isCurrent
              ? _endExclusiveForDay(periodEndDay)
              : DateTime(start.year, start.month + 1, 1);
          final compareEnd = _endExclusiveForDay(compareEndDay);
          final range = _FlowRange(start: start, end: end);
          final compareRange = _FlowRange(start: compareStart, end: compareEnd);

          buckets.add(
            _FlowBucket(
              range: range,
              compareRange: compareRange,
              focusDate: periodEndDay,
              incomeSamePeriod: _sumInRange(
                transactions,
                samePeriodRange,
                TransactionType.income,
              ),
              expenseSamePeriod: _sumInRange(
                transactions,
                samePeriodRange,
                TransactionType.expense,
              ),
              axisLabel: _axisLabelForMonth(start, isCurrent),
              listLabel: _listLabelForMonth(start),
              income: _sumInRange(transactions, range, TransactionType.income),
              expense: _sumInRange(
                transactions,
                range,
                TransactionType.expense,
              ),
              incomeCompare: _sumInRange(
                transactions,
                compareRange,
                TransactionType.income,
              ),
              expenseCompare: _sumInRange(
                transactions,
                compareRange,
                TransactionType.expense,
              ),
            ),
          );
        }
        return buckets;
      case FinanceTimeRange.year:
        final currentYear = now.year;
        final today = _startOfDay(now);
        for (var i = 1; i >= 0; i--) {
          final year = currentYear - i;
          final start = DateTime(year, 1, 1);
          final compareStart = DateTime(year - 1, 1, 1);
          final isCurrent = i == 0;
          final periodEndDay = _clampedDate(year, today.month, today.day);
          final samePeriodRange = _FlowRange(
            start: start,
            end: _endExclusiveForDay(periodEndDay),
          );
          final compareEndDay = _clampedDate(
            year - 1,
            periodEndDay.month,
            periodEndDay.day,
          );
          final end = isCurrent
              ? _endExclusiveForDay(periodEndDay)
              : DateTime(year + 1, 1, 1);
          final compareEnd = _endExclusiveForDay(compareEndDay);
          final range = _FlowRange(start: start, end: end);
          final compareRange = _FlowRange(start: compareStart, end: compareEnd);

          buckets.add(
            _FlowBucket(
              range: range,
              compareRange: compareRange,
              focusDate: periodEndDay,
              incomeSamePeriod: _sumInRange(
                transactions,
                samePeriodRange,
                TransactionType.income,
              ),
              expenseSamePeriod: _sumInRange(
                transactions,
                samePeriodRange,
                TransactionType.expense,
              ),
              axisLabel: _axisLabelForYear(start, isCurrent),
              listLabel: _listLabelForYear(start),
              income: _sumInRange(transactions, range, TransactionType.income),
              expense: _sumInRange(
                transactions,
                range,
                TransactionType.expense,
              ),
              incomeCompare: _sumInRange(
                transactions,
                compareRange,
                TransactionType.income,
              ),
              expenseCompare: _sumInRange(
                transactions,
                compareRange,
                TransactionType.expense,
              ),
            ),
          );
        }
        return buckets;
    }
  }

  int _resolvedSelectedIndex(List<_FlowBucket> buckets) {
    if (buckets.isEmpty) {
      return -1;
    }
    return _selectedIndex.clamp(0, buckets.length - 1).toInt();
  }

  double _currentValue(_FlowBucket bucket) {
    switch (_metric) {
      case _FlowMetricTab.income:
        return bucket.income;
      case _FlowMetricTab.expense:
        return bucket.expense;
      case _FlowMetricTab.difference:
        return bucket.income - bucket.expense;
    }
  }

  double _compareValue(_FlowBucket bucket) {
    switch (_metric) {
      case _FlowMetricTab.income:
        return bucket.incomeCompare;
      case _FlowMetricTab.expense:
        return bucket.expenseCompare;
      case _FlowMetricTab.difference:
        return bucket.incomeCompare - bucket.expenseCompare;
    }
  }

  double _chartCompareValue(_FlowBucket bucket) {
    switch (_metric) {
      case _FlowMetricTab.income:
        return bucket.incomeSamePeriod;
      case _FlowMetricTab.expense:
        return bucket.expenseSamePeriod;
      case _FlowMetricTab.difference:
        return _compareValue(bucket);
    }
  }

  String _money(double value) {
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  String _signedMoney(double value) {
    final abs = _money(value.abs());
    if (value < 0) {
      return '-$abs';
    }
    return abs;
  }

  String _rangeCurrentLabel() {
    switch (_range) {
      case FinanceTimeRange.week:
        return 'tuần này';
      case FinanceTimeRange.month:
        return 'tháng này';
      case FinanceTimeRange.year:
        return 'năm nay';
    }
  }

  bool _containsNow(_FlowRange range) {
    final now = DateTime.now();
    return !now.isBefore(range.start) && now.isBefore(range.end);
  }

  String _selectedRangeLabel(_FlowBucket? selected) {
    if (selected == null) {
      return _rangeCurrentLabel();
    }

    final start = selected.range.start;
    final endDay = selected.range.end.subtract(const Duration(days: 1));
    final isCurrent = _containsNow(selected.range);

    switch (_range) {
      case FinanceTimeRange.week:
        if (isCurrent) {
          return 'tuần này';
        }
        return 'tuần ${_d2(start.day)}/${_d2(start.month)}-${_d2(endDay.day)}/${_d2(endDay.month)}';
      case FinanceTimeRange.month:
        if (isCurrent) {
          return 'tháng này';
        }
        return 'tháng ${start.month}/${start.year}';
      case FinanceTimeRange.year:
        if (isCurrent) {
          return 'năm nay';
        }
        return 'năm ${start.year}';
    }
  }

  String _rangeCompareLabel() {
    switch (_range) {
      case FinanceTimeRange.week:
        return 'tuần trước';
      case FinanceTimeRange.month:
        return 'tháng trước';
      case FinanceTimeRange.year:
        return 'năm trước';
    }
  }

  String _rangeUnitLabel() {
    switch (_range) {
      case FinanceTimeRange.week:
        return 'tuần';
      case FinanceTimeRange.month:
        return 'tháng';
      case FinanceTimeRange.year:
        return 'năm';
    }
  }

  String _summaryTitle(_FlowBucket? selected) {
    final suffix = _selectedRangeLabel(selected);
    switch (_metric) {
      case _FlowMetricTab.income:
        return 'Tổng thu $suffix';
      case _FlowMetricTab.expense:
        return 'Tổng chi $suffix';
      case _FlowMetricTab.difference:
        return 'Tổng chênh lệch $suffix';
    }
  }

  String _selectedDateLabel(_FlowBucket selected) {
    final d = selected.focusDate.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  String _legendPreviousLabel() {
    switch (_metric) {
      case _FlowMetricTab.income:
        return 'Thu nhập cùng kỳ';
      case _FlowMetricTab.expense:
        return 'Chi tiêu cùng kỳ';
      case _FlowMetricTab.difference:
        return 'Chênh lệch cùng kỳ';
    }
  }

  String _legendCurrentLabel() {
    switch (_metric) {
      case _FlowMetricTab.income:
        return 'Tổng thu nhập trong ${_rangeUnitLabel()}';
      case _FlowMetricTab.expense:
        return 'Tổng chi tiêu trong ${_rangeUnitLabel()}';
      case _FlowMetricTab.difference:
        return 'Tổng chênh lệch trong ${_rangeUnitLabel()}';
    }
  }

  bool _isGoodDelta(double delta) {
    switch (_metric) {
      case _FlowMetricTab.income:
        return delta >= 0;
      case _FlowMetricTab.expense:
        return delta <= 0;
      case _FlowMetricTab.difference:
        return delta >= 0;
    }
  }

  Color _deltaColor(double delta) {
    if (delta == 0) {
      return _neutralColor;
    }
    return _isGoodDelta(delta) ? _positiveColor : _negativeColor;
  }

  IconData _deltaIcon(double delta) {
    if (delta == 0) {
      return Icons.remove_rounded;
    }
    return delta > 0
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
  }

  Color _deltaTileBackground(double delta) {
    if (delta == 0) {
      return const Color(0xFFF3F3F6);
    }
    return _isGoodDelta(delta)
        ? const Color(0xFFEFF8F1)
        : const Color(0xFFFFF3EE);
  }

  String _comparisonText(double delta) {
    if (delta == 0) {
      return 'Bằng cùng kỳ ${_rangeCompareLabel()}';
    }
    final action = delta > 0 ? 'Tăng' : 'Giảm';
    return '$action ${_money(delta.abs())} so với cùng kỳ ${_rangeCompareLabel()}';
  }

  String _metricCompareNoun() {
    switch (_metric) {
      case _FlowMetricTab.income:
        return 'thu nhập';
      case _FlowMetricTab.expense:
        return 'chi tiêu';
      case _FlowMetricTab.difference:
        return 'chênh lệch';
    }
  }

  String _fullDate(DateTime date) {
    return '${_d2(date.day)}/${_d2(date.month)}/${date.year}';
  }

  String _compareHintText(_FlowBucket selected) {
    final compareStart = selected.compareRange.start;
    final compareEndDay = selected.compareRange.end.subtract(
      const Duration(days: 1),
    );
    return 'So với ${_metricCompareNoun()} từ ${_fullDate(compareStart)} đến ${_fullDate(compareEndDay)}';
  }

  Widget _buildCompareInfoHint(_FlowBucket selected) {
    const arrowSize = 16.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxHintWidth = (screenWidth - 28).clamp(220.0, 520.0).toDouble();

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxHintWidth),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -8,
              right: 18,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: arrowSize,
                  height: arrowSize,
                  color: const Color(0xFF1D74D5),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1D74D5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _compareHintText(selected),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20 / 1.2,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _groupExpenseByParent(Map<String, double> raw) {
    final grouped = <String, double>{};
    for (final entry in raw.entries) {
      final parent = _expenseParentOf(entry.key);
      grouped[parent] = (grouped[parent] ?? 0) + entry.value;
    }
    return grouped;
  }

  String _expenseParentOf(String category) {
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

  IconData _iconForParent(String parent) {
    if (parent == 'Chi phí cố định') {
      return Icons.home_work_outlined;
    }
    return Icons.layers_outlined;
  }

  List<_FlowCategoryDelta> _categoryRows(
    List<FinanceTransaction> transactions,
    _FlowBucket selected,
  ) {
    final type = _metric == _FlowMetricTab.income
        ? TransactionType.income
        : TransactionType.expense;

    var currentMap = _sumByCategory(transactions, selected.range, type);
    var compareMap = _compareEnabled
        ? _sumByCategory(transactions, selected.compareRange, type)
        : <String, double>{};

    if (_metric == _FlowMetricTab.expense &&
        _expenseBreakdown == _FlowExpenseBreakdown.parent) {
      currentMap = _groupExpenseByParent(currentMap);
      compareMap = _groupExpenseByParent(compareMap);
    }

    final names = <String>{...currentMap.keys, ...compareMap.keys};
    final rows = <_FlowCategoryDelta>[];
    for (final name in names) {
      final current = currentMap[name] ?? 0;
      final compare = compareMap[name] ?? 0;
      if (current == 0 && compare == 0) {
        continue;
      }
      rows.add(
        _FlowCategoryDelta(
          name: name,
          current: current,
          delta: current - compare,
        ),
      );
    }

    rows.sort((a, b) {
      final byCurrent = b.current.compareTo(a.current);
      if (byCurrent != 0) {
        return byCurrent;
      }
      return b.delta.abs().compareTo(a.delta.abs());
    });
    return rows;
  }

  List<_FlowDifferenceRow> _differenceRows(List<_FlowBucket> buckets) {
    return buckets.reversed
        .map(
          (bucket) => _FlowDifferenceRow(
            primaryLabel: bucket.listLabel.split('\n').first,
            secondaryLabel: bucket.listLabel.contains('\n')
                ? bucket.listLabel.split('\n').last
                : null,
            income: bucket.income,
            expense: bucket.expense,
          ),
        )
        .toList();
  }

  Color _colorForName(String name) {
    final type = _metric == _FlowMetricTab.income
        ? TransactionType.income
        : TransactionType.expense;
    final seed = name.toLowerCase().hashCode & 0x7fffffff;
    final hue = (seed % 360).toDouble();
    final fallback = HSVColor.fromAHSV(1, hue, 0.56, 0.88).toColor();
    return FinanceTransactionVisualResolver.resolveCategoryVisual(
      category: name,
      type: type,
      customCategories: context.read<FinanceProvider>().customCategories,
      fallbackColor: fallback,
    ).color;
  }

  IconData _iconForRow(_FlowCategoryDelta row) {
    if (_metric == _FlowMetricTab.income) {
      return FinanceTransactionVisualResolver.resolveCategoryVisual(
        category: row.name,
        type: TransactionType.income,
        customCategories: context.read<FinanceProvider>().customCategories,
        fallbackIcon: widget.iconForIncomeCategory(row.name),
      ).icon;
    }
    if (_expenseBreakdown == _FlowExpenseBreakdown.parent) {
      return _iconForParent(row.name);
    }
    return FinanceTransactionVisualResolver.resolveCategoryVisual(
      category: row.name,
      type: TransactionType.expense,
      customCategories: context.read<FinanceProvider>().customCategories,
      fallbackIcon: widget.iconForExpenseCategory(row.name),
    ).icon;
  }

  DateTime _detailAnchorDateFromBucket(_FlowBucket bucket) {
    if (_containsNow(bucket.range)) {
      return _startOfDay(DateTime.now());
    }
    return _startOfDay(bucket.range.end.subtract(const Duration(days: 1)));
  }

  Future<void> _openFlowCategoryDetail({
    required String category,
    required _FlowBucket selectedBucket,
    required TransactionType type,
  }) async {
    final initialRange = _range == FinanceTimeRange.week
        ? FinanceTimeRange.week
        : FinanceTimeRange.month;
    final anchorDate = _detailAnchorDateFromBucket(selectedBucket);
    final icon = FinanceTransactionVisualResolver.resolveCategoryVisual(
      category: category,
      type: type,
      customCategories: context.read<FinanceProvider>().customCategories,
      fallbackIcon: type == TransactionType.income
          ? widget.iconForIncomeCategory(category)
          : widget.iconForExpenseCategory(category),
    ).icon;

    final info = FinanceBudgetCardInfo(
      title: category,
      allocated: 0,
      spent: 0,
      icon: icon,
      accentColor: _colorForName(category),
      type: type,
      hasCustomBudget: false,
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FinanceBudgetCategoryScreen(
          info: info,
          periodLabel: 'Tháng ${anchorDate.month} ${anchorDate.year}',
          hideAmounts: false,
          initialAnchorDate: anchorDate,
          initialRange: initialRange,
        ),
      ),
    );
  }

  double _divisorFromValues(List<double> values) {
    final maxAbs = values.map((v) => v.abs()).fold<double>(0.0, math.max);
    if (maxAbs >= 1000000) {
      return 1000000.0;
    }
    return 1000.0;
  }

  String _unitLabel(double divisor) {
    return divisor >= 1000000 ? 'Triệu' : 'Nghìn';
  }

  String _axisTick(double value) {
    if (value.abs() < 0.001) {
      return '0';
    }
    if ((value * 10).round() % 10 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  void _changeRange(FinanceTimeRange value) {
    if (_range == value) {
      return;
    }
    setState(() {
      _range = value;
      _selectedIndex = _bucketCountForRange(value) - 1;
      _showCompareInfoHint = false;
    });
  }

  void _changeMetric(_FlowMetricTab value) {
    if (_metric == value) {
      return;
    }
    setState(() {
      _metric = value;
      _showCompareInfoHint = false;
    });
  }

  void _setSelectedFlowIndex(int index, int length) {
    if (index < 0 || index >= length || index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectFlowIndexFromTap({
    required TapDownDetails details,
    required BoxConstraints constraints,
    required int itemCount,
    required double leftReserved,
  }) {
    if (itemCount <= 0) {
      return;
    }
    final local = details.localPosition;
    if (local.dx < leftReserved) {
      return;
    }
    final plotWidth = (constraints.maxWidth - leftReserved)
        .clamp(0.0, double.infinity)
        .toDouble();
    if (plotWidth <= 0) {
      return;
    }
    final slotWidth = plotWidth / itemCount;
    final relativeX = (local.dx - leftReserved).clamp(0.0, plotWidth - 0.001);
    final index = (relativeX / slotWidth).floor().clamp(0, itemCount - 1);
    _setSelectedFlowIndex(index, itemCount);
  }

  Widget _singleLineText(
    String text, {
    required TextStyle style,
    double height = 24,
    Alignment alignment = Alignment.centerLeft,
    TextAlign textAlign = TextAlign.left,
  }) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: alignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            textAlign: textAlign,
            style: style,
          ),
        ),
      ),
    );
  }

  Widget _buildTriplePillTabs({
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onTapIndex,
    required double height,
    required EdgeInsets padding,
    required BorderRadiusGeometry borderRadius,
    required BorderRadius activeRadius,
    required Color backgroundColor,
    BoxBorder? border,
    double activeFontSize = 16,
    double inactiveFontSize = 15,
  }) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        border: border,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / labels.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: tabWidth * selectedIndex,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: tabWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: activeRadius,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x13000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(labels.length, (index) {
                  final active = index == selectedIndex;
                  final tabTextStyle = TextStyle(
                    color: active
                        ? FinanceColors.accentPrimary
                        : FinanceColors.textStrong,
                    fontSize: active ? activeFontSize : inactiveFontSize,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                  );
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: activeRadius,
                        splashFactory: NoSplash.splashFactory,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        onTap: () => onTapIndex(index),
                        child: Center(
                          child: _singleLineText(
                            labels[index],
                            style: tabTextStyle,
                            alignment: Alignment.center,
                            textAlign: TextAlign.center,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopRangeTabs() {
    final selectedIndex = switch (_range) {
      FinanceTimeRange.week => 0,
      FinanceTimeRange.month => 1,
      FinanceTimeRange.year => 2,
    };
    return _buildTriplePillTabs(
      labels: const ['Theo tuần', 'Theo tháng', 'Theo năm'],
      selectedIndex: selectedIndex,
      onTapIndex: (index) {
        if (index == 0) {
          _changeRange(FinanceTimeRange.week);
        } else if (index == 1) {
          _changeRange(FinanceTimeRange.month);
        } else {
          _changeRange(FinanceTimeRange.year);
        }
      },
      height: 66,
      padding: const EdgeInsets.all(6),
      borderRadius: BorderRadius.circular(20),
      activeRadius: BorderRadius.circular(14),
      backgroundColor: const Color(0xFFEFEFF3),
      border: Border.all(color: FinanceColors.border),
      activeFontSize: 18 / 1.15,
      inactiveFontSize: 17 / 1.15,
    );
  }

  Widget _buildMetricTabs() {
    final selectedIndex = switch (_metric) {
      _FlowMetricTab.income => 0,
      _FlowMetricTab.expense => 1,
      _FlowMetricTab.difference => 2,
    };
    return _buildTriplePillTabs(
      labels: const ['Thu nhập', 'Chi tiêu', 'Chênh lệch'],
      selectedIndex: selectedIndex,
      onTapIndex: (index) {
        if (index == 0) {
          _changeMetric(_FlowMetricTab.income);
        } else if (index == 1) {
          _changeMetric(_FlowMetricTab.expense);
        } else {
          _changeMetric(_FlowMetricTab.difference);
        }
      },
      height: 66,
      padding: const EdgeInsets.all(6),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      activeRadius: BorderRadius.circular(14),
      backgroundColor: const Color(0xFFEFEFF3),
      border: Border.all(color: FinanceColors.border),
      activeFontSize: 18 / 1.15,
      inactiveFontSize: 17 / 1.15,
    );
  }

  Widget _buildComparisonBanner(double delta, _FlowBucket? selectedBucket) {
    final color = _deltaColor(delta);
    final canShowInfo = selectedBucket != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _deltaTileBackground(delta),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(_deltaIcon(delta), color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _singleLineText(
              _comparisonText(delta),
              style: TextStyle(
                color: color,
                fontSize: 20 / 1.15,
                fontWeight: FontWeight.w700,
              ),
              height: 26,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canShowInfo
                ? () {
                    setState(() {
                      _showCompareInfoHint = !_showCompareInfoHint;
                    });
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.info_outline_rounded,
                color: canShowInfo ? color : color.withValues(alpha: 0.55),
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot({required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        _singleLineText(
          text,
          style: const TextStyle(
            color: Color(0xFF3E3E47),
            fontSize: 20 / 1.2,
            fontWeight: FontWeight.w500,
          ),
          height: 22,
        ),
      ],
    );
  }

  Widget _buildFlowGuideLine({required double height}) {
    final safeHeight = height.clamp(0.0, double.infinity).toDouble();
    final dashHeight = 8.0;
    final gapHeight = 4.0;
    final segments = <Widget>[];
    var remaining = safeHeight;
    var guard = 0;

    while (remaining > 0 && guard < 500) {
      var segmentHeight = remaining < dashHeight ? remaining : dashHeight;
      remaining -= segmentHeight;

      if (remaining > 0 && remaining <= gapHeight) {
        segmentHeight += remaining;
        remaining = 0;
      }

      segments.add(
        Container(
          width: 2,
          height: segmentHeight,
          color: const Color(0xFF8FC4FA),
        ),
      );

      if (remaining <= 0) {
        break;
      }

      final gap = remaining < gapHeight ? remaining : gapHeight;
      if (gap > 0) {
        segments.add(SizedBox(height: gap));
        remaining -= gap;
      }

      guard++;
    }

    return SizedBox(
      width: 2,
      height: safeHeight,
      child: Column(children: segments),
    );
  }

  Widget _buildIncomeExpenseChart({
    required List<_FlowBucket> buckets,
    required int selectedIndex,
    required double divisor,
  }) {
    final currentValues = buckets.map(_currentValue).toList();
    final compareValues = buckets.map(_chartCompareValue).toList();
    final currentNorm = currentValues.map((v) => v / divisor).toList();
    final compareNorm = compareValues.map((v) => v / divisor).toList();

    final maxNorm = [
      ...currentNorm,
      if (_compareEnabled) ...compareNorm,
      1.0,
    ].fold<double>(0.0, math.max);
    final maxY = (maxNorm * 1.2).clamp(1.0, 999999.0).toDouble();
    final interval = (maxY / 4).clamp(0.2, 999999.0).toDouble();
    final isDenseRange = buckets.length >= 6;
    final barWidth = isDenseRange ? 44.0 : 56.0;

    const compareColor = Color(0xFF5E9EE2);
    const selectedCompareColor = Color(0xFF1A84F6);
    const totalColor = Color(0xFFAFCDE8);
    const selectedTotalColor = Color(0xFF1A84F6);
    const selectedTotalWhenCompareColor = Color(0xFFA6C8E6);
    final labels = buckets.map((bucket) => bucket.axisLabel).toList();
    final hasSelection = selectedIndex >= 0 && selectedIndex < buckets.length;
    final selectedBucket = hasSelection ? buckets[selectedIndex] : null;
    final selectedGuideValue =
        selectedIndex >= 0 && selectedIndex < currentNorm.length
        ? currentNorm[selectedIndex]
        : 0.0;
    final barGroups = List.generate(buckets.length, (index) {
      final selected = index == selectedIndex;
      final compareY = compareNorm[index];
      final currentY = currentNorm[index];
      final showCompare = _compareEnabled;

      final mainY = showCompare ? compareY : currentY;
      final mainColor = showCompare
          ? (selected ? selectedCompareColor : compareColor)
          : (selected ? selectedTotalColor : totalColor);
      final backColor = selected ? selectedTotalWhenCompareColor : totalColor;

      final rod = BarChartRodData(
        toY: mainY,
        width: barWidth,
        color: mainY.abs() < 0.0001 ? Colors.transparent : mainColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
        backDrawRodData: showCompare
            ? BackgroundBarChartRodData(
                show: true,
                fromY: 0,
                toY: currentY,
                color: currentY.abs() < 0.0001 ? Colors.transparent : backColor,
              )
            : BackgroundBarChartRodData(show: false),
      );

      return BarChartGroupData(x: index, barsSpace: 0, barRods: [rod]);
    });

    return SizedBox(
      height: 420,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const leftReserved = 42.0;
                const bottomReserved = 42.0;
                const lineTop = 10.0;
                final plotWidth = (constraints.maxWidth - leftReserved)
                    .clamp(0.0, double.infinity)
                    .toDouble();
                final plotHeight = (constraints.maxHeight - bottomReserved)
                    .clamp(0.0, double.infinity)
                    .toDouble();
                final slotWidth = buckets.isEmpty
                    ? 0.0
                    : (plotWidth / buckets.length).toDouble();
                final centerX =
                    leftReserved + slotWidth * (selectedIndex + 0.5);
                final selectedRatio = maxY <= 0
                    ? 0.0
                    : (selectedGuideValue / maxY).clamp(0.0, 1.0).toDouble();
                final lineBottom = plotHeight - (selectedRatio * plotHeight);
                final lineHeight = (lineBottom - lineTop)
                    .clamp(0.0, plotHeight)
                    .toDouble();
                const bubbleWidth = 112.0;
                final bubbleLeft = hasSelection
                    ? (centerX - bubbleWidth / 2).clamp(
                        4.0,
                        constraints.maxWidth - bubbleWidth - 4,
                      )
                    : 0.0;

                return Stack(
                  children: [
                    Positioned.fill(
                      child: FinanceAdvancedBarChart(
                        barGroups: barGroups,
                        labels: labels,
                        selectedIndex: selectedIndex,
                        onSelectIndex: (index) =>
                            _setSelectedFlowIndex(index, buckets.length),
                        minY: 0,
                        maxY: maxY,
                        interval: interval,
                        alignment: BarChartAlignment.spaceAround,
                        groupsSpace: isDenseRange ? 8 : 12,
                        leftReservedSize: leftReserved,
                        bottomReservedSize: bottomReserved,
                        labelWidth: isDenseRange ? 44.0 : 90.0,
                        leftLabelBuilder: _axisTick,
                        bottomLabelHeight: 18,
                      ),
                    ),
                    if (_compareEnabled &&
                        selectedIndex >= 0 &&
                        selectedIndex < buckets.length &&
                        lineHeight > 0.5)
                      Positioned(
                        left: (centerX - 1).clamp(
                          0.0,
                          constraints.maxWidth - 2,
                        ),
                        top: lineTop,
                        child: _buildFlowGuideLine(height: lineHeight),
                      ),
                    if (_compareEnabled &&
                        hasSelection &&
                        selectedBucket != null)
                      Positioned(
                        left: bubbleLeft,
                        top: 6,
                        child: IgnorePointer(
                          child: Container(
                            width: bubbleWidth,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF8FC4FA),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                _singleLineText(
                                  _selectedDateLabel(selectedBucket),
                                  style: const TextStyle(
                                    color: Color(0xFF73737C),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  alignment: Alignment.center,
                                  textAlign: TextAlign.center,
                                  height: 18,
                                ),
                                _singleLineText(
                                  _money(_currentValue(selectedBucket)),
                                  style: const TextStyle(
                                    color: Color(0xFF1A78EE),
                                    fontSize: 19 / 1.2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  alignment: Alignment.center,
                                  textAlign: TextAlign.center,
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) => _selectFlowIndexFromTap(
                          details: details,
                          constraints: constraints,
                          itemCount: buckets.length,
                          leftReserved: leftReserved,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 26,
            child: Visibility(
              visible: _compareEnabled,
              maintainState: true,
              maintainAnimation: true,
              maintainSize: true,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      _buildLegendDot(
                        color: compareColor,
                        text: _legendPreviousLabel(),
                      ),
                      const SizedBox(width: 18),
                      _buildLegendDot(
                        color: totalColor,
                        text: _legendCurrentLabel(),
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

  Widget _buildDifferenceChart({
    required List<_FlowBucket> buckets,
    required int selectedIndex,
    required double divisor,
  }) {
    final values = buckets.map(_currentValue).toList();
    final normalized = values.map((v) => v / divisor).toList();
    final maxAbs = normalized.map((v) => v.abs()).fold<double>(0.0, math.max);
    final safeMax = (maxAbs * 1.2).clamp(1.0, 999999.0).toDouble();
    final interval = (safeMax / 3).clamp(0.2, 999999.0).toDouble();
    final selectedLineX = _compareEnabled && selectedIndex >= 0
        ? selectedIndex.toDouble()
        : null;
    final isDenseRange = buckets.length >= 6;
    final barWidth = isDenseRange ? 34.0 : 48.0;
    final labels = buckets.map((bucket) => bucket.axisLabel).toList();
    final barGroups = List.generate(buckets.length, (index) {
      final value = normalized[index];
      final selected = index == selectedIndex;
      final positive = value >= 0;
      final color = positive
          ? (selected ? const Color(0xFF1A84F6) : const Color(0xFFABCCE9))
          : (selected ? const Color(0xFFF0B6A3) : const Color(0xFFE8C8BC));
      final visible = value.abs() >= 0.0001;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            width: barWidth,
            color: visible ? color : Colors.transparent,
            borderRadius: value >= 0
                ? const BorderRadius.vertical(top: Radius.circular(10))
                : const BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
        ],
      );
    });

    return SizedBox(
      height: 360,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const leftReserved = 42.0;
          return Stack(
            children: [
              Positioned.fill(
                child: FinanceAdvancedBarChart(
                  barGroups: barGroups,
                  labels: labels,
                  selectedIndex: selectedIndex,
                  onSelectIndex: (index) =>
                      _setSelectedFlowIndex(index, buckets.length),
                  minY: -safeMax,
                  maxY: safeMax,
                  interval: interval,
                  alignment: BarChartAlignment.spaceEvenly,
                  groupsSpace: isDenseRange ? 10 : 14,
                  leftReservedSize: leftReserved,
                  bottomReservedSize: 42,
                  labelWidth: isDenseRange ? 44.0 : 90.0,
                  leftLabelBuilder: _axisTick,
                  extraLinesData: ExtraLinesData(
                    extraLinesOnTop: true,
                    verticalLines: selectedLineX == null
                        ? <VerticalLine>[]
                        : [
                            VerticalLine(
                              x: selectedLineX,
                              color: const Color(0xFF8FC4FA),
                              strokeWidth: 2,
                              dashArray: [8, 4],
                            ),
                          ],
                  ),
                  bottomLabelHeight: 18,
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) => _selectFlowIndexFromTap(
                    details: details,
                    constraints: constraints,
                    itemCount: buckets.length,
                    leftReserved: leftReserved,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpenseBreakdownTabs() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE9E6EE), width: 1)),
      ),
      child: Row(
        children: [
          _buildBreakdownTab(
            label: 'Danh mục con',
            selected: _expenseBreakdown == _FlowExpenseBreakdown.child,
            onTap: () {
              if (_expenseBreakdown == _FlowExpenseBreakdown.child) {
                return;
              }
              setState(() {
                _expenseBreakdown = _FlowExpenseBreakdown.child;
              });
            },
          ),
          _buildBreakdownTab(
            label: 'Danh mục cha',
            selected: _expenseBreakdown == _FlowExpenseBreakdown.parent,
            onTap: () {
              if (_expenseBreakdown == _FlowExpenseBreakdown.parent) {
                return;
              }
              setState(() {
                _expenseBreakdown = _FlowExpenseBreakdown.parent;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? FinanceColors.accentPrimary
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              style: TextStyle(
                color: selected
                    ? FinanceColors.accentPrimary
                    : FinanceColors.textStrong,
                fontSize: selected ? 34 / 1.9 : 32 / 1.9,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
              ),
              child: _singleLineText(
                label,
                style: TextStyle(
                  color: selected
                      ? FinanceColors.accentPrimary
                      : FinanceColors.textStrong,
                  fontSize: selected ? 34 / 1.9 : 32 / 1.9,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                ),
                alignment: Alignment.center,
                textAlign: TextAlign.center,
                height: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRows(
    List<_FlowCategoryDelta> rows,
    _FlowBucket? selectedBucket,
  ) {
    final showDetailChevron =
        _metric == _FlowMetricTab.income ||
        (_metric == _FlowMetricTab.expense &&
            _expenseBreakdown == _FlowExpenseBreakdown.child);

    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F5FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FinanceColors.border),
        ),
        child: _singleLineText(
          'Chưa có dữ liệu giao dịch trong kỳ này',
          style: const TextStyle(
            color: Color(0xFF66666F),
            fontWeight: FontWeight.w600,
          ),
          height: 22,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          final icon = _iconForRow(row);
          final color = _colorForName(row.name);
          final deltaColor = _deltaColor(row.delta);
          final canOpenDetail = showDetailChevron && selectedBucket != null;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canOpenDetail
                ? () => _openFlowCategoryDetail(
                    category: row.name,
                    selectedBucket: selectedBucket,
                    type: _metric == _FlowMetricTab.income
                        ? TransactionType.income
                        : TransactionType.expense,
                  )
                : null,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                border: index == rows.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFFEDEAF2), width: 1),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _singleLineText(
                      row.name,
                      style: const TextStyle(
                        color: FinanceColors.textStrong,
                        fontSize: 22 / 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _singleLineText(
                        _money(row.current),
                        style: const TextStyle(
                          color: FinanceColors.textStrong,
                          fontSize: 22 / 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                        height: 24,
                        alignment: Alignment.centerRight,
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _deltaIcon(row.delta),
                            size: 18,
                            color: deltaColor,
                          ),
                          const SizedBox(width: 4),
                          _singleLineText(
                            _money(row.delta.abs()),
                            style: TextStyle(
                              color: deltaColor,
                              fontSize: 22 / 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                            height: 22,
                            alignment: Alignment.centerRight,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 18,
                    child: showDetailChevron
                        ? const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF7A7A83),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDifferenceRows(List<_FlowDifferenceRow> rows) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        children: rows.map((row) {
          final positive = row.difference >= 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _singleLineText(
                        row.primaryLabel,
                        textAlign: TextAlign.center,
                        alignment: Alignment.center,
                        height: 28,
                        style: const TextStyle(
                          color: FinanceColors.textStrong,
                          fontSize: 36 / 1.6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (row.secondaryLabel != null)
                        _singleLineText(
                          row.secondaryLabel!,
                          textAlign: TextAlign.center,
                          alignment: Alignment.center,
                          height: 20,
                          style: const TextStyle(
                            color: Color(0xFF6D6D76),
                            fontSize: 28 / 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _singleLineText(
                        'Thu ${_money(row.income)}',
                        style: const TextStyle(
                          color: Color(0xFF676770),
                          fontSize: 22 / 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                        height: 24,
                      ),
                      const SizedBox(height: 4),
                      _singleLineText(
                        'Chi ${_money(row.expense)}',
                        style: const TextStyle(
                          color: Color(0xFF676770),
                          fontSize: 22 / 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                        height: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _singleLineText(
                      'Còn lại',
                      style: const TextStyle(
                        color: Color(0xFF6F6F78),
                        fontSize: 22 / 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                      height: 22,
                      alignment: Alignment.centerRight,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    _singleLineText(
                      _signedMoney(row.difference),
                      style: TextStyle(
                        color: positive
                            ? const Color(0xFF1A78EE)
                            : const Color(0xFFFF5A2E),
                        fontSize: 38 / 1.55,
                        fontWeight: FontWeight.w900,
                      ),
                      height: 30,
                      alignment: Alignment.centerRight,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<FinanceProvider>().transactions;
    final buckets = _buildBuckets(transactions);
    final selectedIndex = _resolvedSelectedIndex(buckets);
    final selectedBucket = selectedIndex >= 0 ? buckets[selectedIndex] : null;

    final summaryValue = selectedBucket == null
        ? 0.0
        : _currentValue(selectedBucket);
    final compareValue = selectedBucket == null
        ? 0.0
        : _compareValue(selectedBucket);
    final delta = summaryValue - compareValue;

    final chartValues = _metric == _FlowMetricTab.difference
        ? buckets.map(_currentValue).toList()
        : [
            ...buckets.map(_currentValue),
            if (_compareEnabled) ...buckets.map(_compareValue),
          ];
    final divisor = _divisorFromValues(chartValues.isEmpty ? [0] : chartValues);

    final categoryRows = selectedBucket == null
        ? const <_FlowCategoryDelta>[]
        : _categoryRows(transactions, selectedBucket);
    final differenceRows = _differenceRows(buckets);

    return Scaffold(
      backgroundColor: FinanceColors.background,
      appBar: const FinanceGradientAppBar(title: 'Biến động thu chi'),
      body: ColoredBox(
        color: FinanceColors.background,
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            children: [
              _buildTopRangeTabs(),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: FinanceColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetricTabs(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.02, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey('${_range.name}-${_metric.name}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Column(
                                children: [
                                  _singleLineText(
                                    _summaryTitle(selectedBucket),
                                    style: const TextStyle(
                                      color: Color(0xFF707079),
                                      fontSize: 42 / 1.55,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    alignment: Alignment.center,
                                    textAlign: TextAlign.center,
                                    height: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  _singleLineText(
                                    _metric == _FlowMetricTab.difference
                                        ? _signedMoney(summaryValue)
                                        : _money(summaryValue),
                                    style: const TextStyle(
                                      color: FinanceColors.textStrong,
                                      fontSize: 56 / 1.58,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    alignment: Alignment.center,
                                    textAlign: TextAlign.center,
                                    height: 36,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildComparisonBanner(delta, selectedBucket),
                                  if (_showCompareInfoHint &&
                                      selectedBucket != null) ...[
                                    const SizedBox(height: 8),
                                    _buildCompareInfoHint(selectedBucket),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _singleLineText(
                                      'Biến động',
                                      style: const TextStyle(
                                        color: FinanceColors.textStrong,
                                        fontSize: 46 / 1.6,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      height: 30,
                                    ),
                                  ),
                                  _singleLineText(
                                    'So với cùng kỳ',
                                    style: const TextStyle(
                                      color: Color(0xFF6A6A73),
                                      fontSize: 34 / 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    height: 24,
                                    alignment: Alignment.centerRight,
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(width: 6),
                                  Switch(
                                    value: _compareEnabled,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: const Color(0xFF2AC84D),
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: const Color(0xFFBFC1C8),
                                    onChanged: (value) {
                                      setState(() {
                                        _compareEnabled = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                              child: _singleLineText(
                                '(${_unitLabel(divisor)})',
                                style: const TextStyle(
                                  color: Color(0xFF6F6F78),
                                  fontSize: 22 / 1.2,
                                  fontWeight: FontWeight.w500,
                                ),
                                height: 20,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                              child: Stack(
                                children: [
                                  if (_metric == _FlowMetricTab.difference)
                                    _buildDifferenceChart(
                                      buckets: buckets,
                                      selectedIndex: selectedIndex,
                                      divisor: divisor,
                                    )
                                  else
                                    _buildIncomeExpenseChart(
                                      buckets: buckets,
                                      selectedIndex: selectedIndex,
                                      divisor: divisor,
                                    ),
                                ],
                              ),
                            ),
                            if (_metric == _FlowMetricTab.expense)
                              _buildExpenseBreakdownTabs(),
                            if (_metric != _FlowMetricTab.difference)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  10,
                                ),
                                child: _buildCategoryRows(
                                  categoryRows,
                                  selectedBucket,
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  10,
                                ),
                                child: _buildDifferenceRows(differenceRows),
                              ),
                          ],
                        ),
                      ),
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
