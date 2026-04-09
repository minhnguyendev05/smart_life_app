import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_category.dart';
import '../../models/finance_recurring_transaction.dart';
import '../../models/finance_transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/local_storage_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_toast.dart';
import 'finance_screen.dart';
import 'finance_shared_widgets.dart';
import 'finance_styles.dart';

class FinanceModuleScreen extends StatefulWidget {
  const FinanceModuleScreen({super.key});

  @override
  State<FinanceModuleScreen> createState() => _FinanceModuleScreenState();
}

class _FinanceModuleScreenState extends State<FinanceModuleScreen> {
  static const Color _bg = FinanceColors.background;
  static const Color _accentPink = FinanceColors.accentSecondary;

  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const FinanceScreen(),
      const _FinanceCalendarTab(),
      const _FinanceRecurringTab(),
      const _FinanceMoniTab(),
      _FinanceUtilitiesTab(onOpenOverview: () => setState(() => _tabIndex = 0)),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFFE6F3),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? _accentPink : const Color(0xFF70707A),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) => setState(() => _tabIndex = index),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Tổng quan',
            ),
            const NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Lịch',
            ),
            NavigationDestination(
              icon: Badge(
                label: const Text(
                  'Mới',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                child: const Icon(Icons.event_repeat_rounded),
              ),
              selectedIcon: const Icon(Icons.event_repeat_rounded),
              label: 'GĐ định kỳ',
            ),
            const NavigationDestination(
              icon: _MoniNavIcon(),
              selectedIcon: _MoniNavIcon(selected: true),
              label: 'Moni',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Tiện ích',
            ),
          ],
        ),
      ),
    );
  }
}

class _MoniNavIcon extends StatelessWidget {
  const _MoniNavIcon({this.selected = false});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: selected ? 1 : 0.84,
      child: Image.asset(
        'assets/icons/bard.png',
        width: 24,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Icon(
            selected ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
            size: 22,
          );
        },
      ),
    );
  }
}

class _FinanceCalendarTab extends StatefulWidget {
  const _FinanceCalendarTab();

  @override
  State<_FinanceCalendarTab> createState() => _FinanceCalendarTabState();
}

enum _CalendarTimeFilter { all, completed, upcoming }

enum _CalendarCategoryTab { expense, income }

class _CalendarCategorySeed {
  const _CalendarCategorySeed({
    required this.title,
    required this.icon,
    required this.color,
    required this.categories,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> categories;
}

class _CalendarCategoryVisual {
  const _CalendarCategoryVisual({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}

class _CalendarCategoryGroup {
  const _CalendarCategoryGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.type,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final TransactionType type;
  final List<_CalendarCategoryVisual> items;
}

class _CalendarFilterResult {
  const _CalendarFilterResult({
    required this.selectedCategoryKeys,
    required this.timeFilter,
    required this.showExcludedInReports,
  });

  final Set<String> selectedCategoryKeys;
  final _CalendarTimeFilter timeFilter;
  final bool showExcludedInReports;
}

class _CalendarDaySummary {
  const _CalendarDaySummary({
    required this.income,
    required this.expense,
    required this.abnormalExpense,
  });

  final double income;
  final double expense;
  final bool abnormalExpense;
}

class _FinanceCalendarTabState extends State<_FinanceCalendarTab> {
  static const String _uncategorizedKey = '__uncategorized__';

  static const List<_CalendarCategorySeed> _expenseSeeds = [
    _CalendarCategorySeed(
      title: 'Chi tiêu - sinh hoạt',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFFF48A1C),
      categories: ['Chợ, siêu thị', 'Ăn uống', 'Di chuyển'],
    ),
    _CalendarCategorySeed(
      title: 'Chi phí phát sinh',
      icon: Icons.layers_outlined,
      color: Color(0xFFF3BF17),
      categories: ['Mua sắm', 'Giải trí', 'Làm đẹp', 'Sức khỏe', 'Từ thiện'],
    ),
    _CalendarCategorySeed(
      title: 'Chi phí cố định',
      icon: Icons.home_work_outlined,
      color: Color(0xFF2C82E8),
      categories: ['Hóa đơn', 'Nhà cửa', 'Người thân'],
    ),
    _CalendarCategorySeed(
      title: 'Đầu tư - tiết kiệm',
      icon: Icons.savings_outlined,
      color: Color(0xFF2EC7AF),
      categories: ['Đầu tư', 'Học tập'],
    ),
  ];

  static const List<_CalendarCategorySeed> _incomeSeeds = [
    _CalendarCategorySeed(
      title: 'Thu nhập',
      icon: Icons.payments_outlined,
      color: Color(0xFFFF8A5B),
      categories: ['Kinh doanh', 'Lương', 'Thưởng', 'Lợi nhuận', 'Trợ cấp'],
    ),
  ];

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int _selectedDay = DateTime.now().day;
  bool _hideAmounts = false;
  bool _showTransactionList = true;

  Set<String> _selectedCategoryKeys = <String>{};
  _CalendarTimeFilter _timeFilter = _CalendarTimeFilter.all;
  bool _showExcludedInReports = false;

  String _keyForCategory(String name) => name.trim().toLowerCase();

  bool _isUncategorized(String value) {
    final key = _keyForCategory(value);
    return key.isEmpty ||
        key == 'chưa phân loại' ||
        key == 'không phân loại' ||
        key == 'uncategorized';
  }

  bool _matchCategoryFilter(FinanceTransaction tx) {
    if (_selectedCategoryKeys.isEmpty) {
      return true;
    }

    final key = _keyForCategory(tx.category);
    if (_selectedCategoryKeys.contains(key)) {
      return true;
    }

    return _selectedCategoryKeys.contains(_uncategorizedKey) &&
        _isUncategorized(tx.category);
  }

  bool _matchTimeFilter(FinanceTransaction tx) {
    if (_timeFilter == _CalendarTimeFilter.all) {
      return true;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(
      tx.createdAt.year,
      tx.createdAt.month,
      tx.createdAt.day,
    );

    if (_timeFilter == _CalendarTimeFilter.completed) {
      return !date.isAfter(today);
    }

    return date.isAfter(today);
  }

  List<FinanceTransaction> _resolveMonthTransactions(FinanceProvider provider) {
    final source = provider.transactions;
    return source.where((tx) {
      final inMonth =
          tx.createdAt.year == _month.year &&
          tx.createdAt.month == _month.month;
      if (!inMonth) {
        return false;
      }
      if (!_showExcludedInReports && !tx.includedInReports) {
        return false;
      }
      return _matchCategoryFilter(tx) && _matchTimeFilter(tx);
    }).toList();
  }

  Map<int, _CalendarDaySummary> _buildDaySummaries(
    List<FinanceTransaction> txs,
  ) {
    final incomeByDay = <int, double>{};
    final expenseByDay = <int, double>{};

    for (final tx in txs) {
      final day = tx.createdAt.day;
      if (tx.type == TransactionType.income) {
        incomeByDay[day] = (incomeByDay[day] ?? 0) + tx.amount;
      } else {
        expenseByDay[day] = (expenseByDay[day] ?? 0) + tx.amount;
      }
    }

    final expenseValues = expenseByDay.values.where((v) => v > 0).toList();
    final averageExpense = expenseValues.isEmpty
        ? 0.0
        : expenseValues.reduce((a, b) => a + b) / expenseValues.length;

    final summary = <int, _CalendarDaySummary>{};
    final allDays = <int>{...incomeByDay.keys, ...expenseByDay.keys};
    for (final day in allDays) {
      final income = incomeByDay[day] ?? 0;
      final expense = expenseByDay[day] ?? 0;
      final abnormal =
          expense > 0 && averageExpense > 0 && expense >= averageExpense * 1.8;
      summary[day] = _CalendarDaySummary(
        income: income,
        expense: expense,
        abnormalExpense: abnormal,
      );
    }
    return summary;
  }

  SplayTreeMap<DateTime, List<FinanceTransaction>> _groupByDay(
    List<FinanceTransaction> transactions,
  ) {
    final grouped = SplayTreeMap<DateTime, List<FinanceTransaction>>(
      (a, b) => b.compareTo(a),
    );

    for (final item in transactions) {
      final key = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped;
  }

  void _moveMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
      if (_selectedDay > daysInMonth) {
        _selectedDay = daysInMonth;
      }
    });
  }

  String _compactDayAmount(double amount) {
    final value = amount.abs();
    if (value <= 0) {
      return '0đ';
    }
    if (value >= 1000000) {
      final scaled = value / 1000000;
      final text = scaled >= 10
          ? scaled.toStringAsFixed(0)
          : scaled.toStringAsFixed(1).replaceAll('.0', '');
      return '${text}tr';
    }
    if (value >= 1000) {
      final scaled = value / 1000;
      final text = scaled >= 10
          ? scaled.toStringAsFixed(0)
          : scaled.toStringAsFixed(1).replaceAll('.0', '');
      return '${text}k';
    }
    return '${value.toStringAsFixed(0)}đ';
  }

  String _displayAmount(double amount, {required bool forCell}) {
    if (_hideAmounts) {
      return '******';
    }
    return forCell ? _compactDayAmount(amount) : _compactCurrency(amount);
  }

  IconData _fallbackIconForCategory(String name, TransactionType type) {
    final key = _keyForCategory(name);
    if (type == TransactionType.expense) {
      if (key.contains('chợ') || key.contains('siêu thị')) {
        return Icons.shopping_basket_outlined;
      }
      if (key.contains('ăn') || key.contains('uống')) {
        return Icons.restaurant_rounded;
      }
      if (key.contains('di chuyển')) {
        return Icons.directions_car_filled_outlined;
      }
      if (key.contains('mua sắm')) {
        return Icons.shopping_cart_outlined;
      }
      if (key.contains('giải trí')) {
        return Icons.movie_filter_outlined;
      }
      if (key.contains('làm đẹp')) {
        return Icons.spa_outlined;
      }
      if (key.contains('sức khỏe')) {
        return Icons.favorite_outline_rounded;
      }
      if (key.contains('từ thiện')) {
        return Icons.volunteer_activism_outlined;
      }
      if (key.contains('hóa đơn')) {
        return Icons.receipt_long_outlined;
      }
      if (key.contains('nhà cửa')) {
        return Icons.home_work_outlined;
      }
      if (key.contains('người thân')) {
        return Icons.child_care_outlined;
      }
      if (key.contains('đầu tư')) {
        return Icons.savings_outlined;
      }
      if (key.contains('học tập')) {
        return Icons.auto_stories_outlined;
      }
      return Icons.grid_view_rounded;
    }

    if (key.contains('lương')) {
      return Icons.work_outline_rounded;
    }
    if (key.contains('thưởng')) {
      return Icons.emoji_events_outlined;
    }
    if (key.contains('kinh doanh')) {
      return Icons.trending_up_rounded;
    }
    if (key.contains('lợi nhuận')) {
      return Icons.account_balance_wallet_outlined;
    }
    return Icons.payments_outlined;
  }

  Color _fallbackColorForCategory(String name, TransactionType type) {
    final key = _keyForCategory(name);
    if (type == TransactionType.expense) {
      if (key.contains('di chuyển')) {
        return const Color(0xFF6AB2F8);
      }
      if (key.contains('hóa đơn') || key.contains('đầu tư')) {
        return const Color(0xFF8ADBCB);
      }
      if (key.contains('nhà cửa') || key.contains('học tập')) {
        return const Color(0xFFC6C1F4);
      }
      if (key.contains('người thân') || key.contains('làm đẹp')) {
        return const Color(0xFFF3ABD0);
      }
      if (key.contains('sức khỏe') || key.contains('mua sắm')) {
        return const Color(0xFFF7B39D);
      }
      return const Color(0xFFFF9E56);
    }
    if (key.contains('thưởng')) {
      return const Color(0xFFF3BF17);
    }
    if (key.contains('lương')) {
      return const Color(0xFF46C7B8);
    }
    return const Color(0xFF58A5FF);
  }

  List<_CalendarCategoryGroup> _resolvedCategoryGroups(
    List<FinanceCategory> customCategories,
    _CalendarCategoryTab tab,
  ) {
    final type = tab == _CalendarCategoryTab.expense
        ? TransactionType.expense
        : TransactionType.income;
    final seeds = type == TransactionType.expense
        ? _expenseSeeds
        : _incomeSeeds;

    final customByType = customCategories
        .where((item) => item.type == type)
        .toList();
    final customLookup = <String, FinanceCategory>{
      for (final item in customByType) _keyForCategory(item.name): item,
    };

    final groups = seeds.map((seed) {
      final names = <String>[...seed.categories];
      for (final item in customByType) {
        if (_keyForCategory(item.group) == _keyForCategory(seed.title) &&
            !names.any(
              (n) => _keyForCategory(n) == _keyForCategory(item.name),
            )) {
          names.add(item.name);
        }
      }

      final visuals = names
          .map((name) {
            final custom = customLookup[_keyForCategory(name)];
            return _CalendarCategoryVisual(
              name: name,
              icon: custom?.icon ?? _fallbackIconForCategory(name, type),
              color: custom?.color ?? _fallbackColorForCategory(name, type),
            );
          })
          .toList(growable: false);

      return _CalendarCategoryGroup(
        title: seed.title,
        icon: seed.icon,
        color: seed.color,
        type: type,
        items: visuals,
      );
    }).toList();

    for (final item in customByType) {
      final hasGroup = groups.any(
        (group) => _keyForCategory(group.title) == _keyForCategory(item.group),
      );
      if (hasGroup) {
        continue;
      }

      groups.add(
        _CalendarCategoryGroup(
          title: item.group.trim().isEmpty ? 'Khác' : item.group.trim(),
          icon: Icons.grid_view_rounded,
          color: const Color(0xFF8E8EA0),
          type: type,
          items: [
            _CalendarCategoryVisual(
              name: item.name,
              icon: item.icon,
              color: item.color,
            ),
          ],
        ),
      );
    }

    return groups;
  }

  Future<void> _openFilterSheet(List<FinanceCategory> customCategories) async {
    final result = await showModalBottomSheet<_CalendarFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final searchController = TextEditingController();
        var draftSearch = '';
        var draftTypeTab = _CalendarCategoryTab.expense;
        var draftSelected = Set<String>.from(_selectedCategoryKeys);
        var draftTimeFilter = _timeFilter;
        var draftShowExcluded = _showExcludedInReports;

        bool hasAnyFilter() {
          return draftSelected.isNotEmpty ||
              draftTimeFilter != _CalendarTimeFilter.all ||
              draftShowExcluded;
        }

        bool isGroupSelected(_CalendarCategoryGroup group) {
          if (group.items.isEmpty) {
            return false;
          }
          return group.items
              .map((item) => _keyForCategory(item.name))
              .every(draftSelected.contains);
        }

        List<_CalendarCategoryGroup> visibleGroups() {
          final groups = _resolvedCategoryGroups(
            customCategories,
            draftTypeTab,
          );
          if (draftSearch.trim().isEmpty) {
            return groups;
          }
          final query = _keyForCategory(draftSearch);
          return groups.where((group) {
            if (_keyForCategory(group.title).contains(query)) {
              return true;
            }
            return group.items.any(
              (item) => _keyForCategory(item.name).contains(query),
            );
          }).toList();
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final groups = visibleGroups();
            final uncategorizedSelected = draftSelected.contains(
              _uncategorizedKey,
            );

            return SafeArea(
              top: false,
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F1F7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 10, 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Sắp xếp',
                                style: TextStyle(
                                  fontSize: 26 / 1.15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2F2F37),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded, size: 40),
                            color: const Color(0xFF3D3D45),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: searchController,
                              onChanged: (value) => setModalState(() {
                                draftSearch = value;
                              }),
                              decoration: InputDecoration(
                                hintText: 'Tìm kiếm',
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF7A7A83),
                                  size: 34,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Theo danh mục',
                              style: TextStyle(
                                fontSize: 24 / 1.1,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2F2F37),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: FinanceColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEAF4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.help_outline_rounded,
                                      color: FinanceColors.accentPrimary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Chưa phân loại',
                                      style: TextStyle(
                                        fontSize: 20 / 1.15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2F2F37),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => setModalState(() {
                                      if (uncategorizedSelected) {
                                        draftSelected.remove(_uncategorizedKey);
                                      } else {
                                        draftSelected.add(_uncategorizedKey);
                                      }
                                    }),
                                    child: Text(
                                      uncategorizedSelected
                                          ? 'Bỏ chọn'
                                          : 'Chọn',
                                      style: const TextStyle(
                                        color: FinanceColors.accentPrimary,
                                        fontSize: 20 / 1.15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: FinanceColors.border),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setModalState(() {
                                            draftTypeTab =
                                                _CalendarCategoryTab.expense;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(
                                              10,
                                              12,
                                              10,
                                              12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  draftTypeTab ==
                                                      _CalendarCategoryTab
                                                          .expense
                                                  ? const Color(0xFFFFF1F8)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      16,
                                                    ),
                                                  ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.outbound_rounded,
                                                  size: 28,
                                                  color:
                                                      draftTypeTab ==
                                                          _CalendarCategoryTab
                                                              .expense
                                                      ? FinanceColors
                                                            .accentPrimary
                                                      : const Color(0xFF33333B),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Chi tiêu',
                                                  style: TextStyle(
                                                    color:
                                                        draftTypeTab ==
                                                            _CalendarCategoryTab
                                                                .expense
                                                        ? FinanceColors
                                                              .accentPrimary
                                                        : const Color(
                                                            0xFF33333B,
                                                          ),
                                                    fontSize: 22 / 1.1,
                                                    fontWeight:
                                                        draftTypeTab ==
                                                            _CalendarCategoryTab
                                                                .expense
                                                        ? FontWeight.w900
                                                        : FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setModalState(() {
                                            draftTypeTab =
                                                _CalendarCategoryTab.income;
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(
                                              10,
                                              12,
                                              10,
                                              12,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  draftTypeTab ==
                                                      _CalendarCategoryTab
                                                          .income
                                                  ? const Color(0xFFFFF1F8)
                                                  : Colors.transparent,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topRight: Radius.circular(
                                                      16,
                                                    ),
                                                  ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.south_west_rounded,
                                                  size: 28,
                                                  color:
                                                      draftTypeTab ==
                                                          _CalendarCategoryTab
                                                              .income
                                                      ? FinanceColors
                                                            .accentPrimary
                                                      : const Color(0xFF33333B),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Thu nhập',
                                                  style: TextStyle(
                                                    color:
                                                        draftTypeTab ==
                                                            _CalendarCategoryTab
                                                                .income
                                                        ? FinanceColors
                                                              .accentPrimary
                                                        : const Color(
                                                            0xFF33333B,
                                                          ),
                                                    fontSize: 22 / 1.1,
                                                    fontWeight:
                                                        draftTypeTab ==
                                                            _CalendarCategoryTab
                                                                .income
                                                        ? FontWeight.w900
                                                        : FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ...groups.map((group) {
                                    final selected = isGroupSelected(group);
                                    return Container(
                                      margin: const EdgeInsets.fromLTRB(
                                        8,
                                        0,
                                        8,
                                        10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: FinanceColors.border,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.fromLTRB(
                                              12,
                                              8,
                                              12,
                                              8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: group.color.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(14),
                                                  ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  group.icon,
                                                  color: group.color,
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    group.title,
                                                    style: TextStyle(
                                                      color: group.color,
                                                      fontSize: 21 / 1.1,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => setModalState(
                                                    () {
                                                      final keys = group.items
                                                          .map(
                                                            (item) =>
                                                                _keyForCategory(
                                                                  item.name,
                                                                ),
                                                          )
                                                          .toSet();
                                                      if (selected) {
                                                        draftSelected.removeAll(
                                                          keys,
                                                        );
                                                      } else {
                                                        draftSelected.addAll(
                                                          keys,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  child: Text(
                                                    selected
                                                        ? 'Bỏ chọn'
                                                        : 'Chọn',
                                                    style: const TextStyle(
                                                      color: FinanceColors
                                                          .accentPrimary,
                                                      fontSize: 20 / 1.15,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          GridView.builder(
                                            itemCount: group.items.length,
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                              10,
                                              10,
                                              10,
                                              10,
                                            ),
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 4,
                                                  crossAxisSpacing: 8,
                                                  mainAxisSpacing: 8,
                                                  childAspectRatio: 0.82,
                                                ),
                                            itemBuilder: (context, index) {
                                              final item = group.items[index];
                                              final key = _keyForCategory(
                                                item.name,
                                              );
                                              final itemSelected = draftSelected
                                                  .contains(key);
                                              return InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: () => setModalState(() {
                                                  if (itemSelected) {
                                                    draftSelected.remove(key);
                                                  } else {
                                                    draftSelected.add(key);
                                                  }
                                                }),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: itemSelected
                                                        ? const Color(
                                                            0xFFFFF1F8,
                                                          )
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        item.icon,
                                                        color: item.color,
                                                        size: 36,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        item.name,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 20 / 1.2,
                                                          color: Color(
                                                            0xFF2F2F37,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Theo thời gian',
                              style: TextStyle(
                                fontSize: 24 / 1.1,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2F2F37),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: FinanceColors.border),
                              ),
                              child: Column(
                                children: [
                                  _CalendarTimeFilterTile(
                                    label: 'Tất cả',
                                    icon: Icons.done_all_rounded,
                                    selected:
                                        draftTimeFilter ==
                                        _CalendarTimeFilter.all,
                                    onTap: () => setModalState(() {
                                      draftTimeFilter = _CalendarTimeFilter.all;
                                    }),
                                  ),
                                  _CalendarTimeFilterTile(
                                    label: 'Đã thực hiện',
                                    icon: Icons.history_toggle_off_rounded,
                                    selected:
                                        draftTimeFilter ==
                                        _CalendarTimeFilter.completed,
                                    onTap: () => setModalState(() {
                                      draftTimeFilter =
                                          _CalendarTimeFilter.completed;
                                    }),
                                  ),
                                  _CalendarTimeFilterTile(
                                    label: 'Dự kiến thu chi',
                                    icon: Icons.calendar_today_rounded,
                                    selected:
                                        draftTimeFilter ==
                                        _CalendarTimeFilter.upcoming,
                                    onTap: () => setModalState(() {
                                      draftTimeFilter =
                                          _CalendarTimeFilter.upcoming;
                                    }),
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Theo trạng thái',
                              style: TextStyle(
                                fontSize: 24 / 1.1,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2F2F37),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                10,
                                10,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: FinanceColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.query_stats_rounded,
                                    size: 34,
                                    color: Color(0xFF7A7A83),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Hiển thị các giao dịch không tính vào báo cáo',
                                      style: TextStyle(
                                        fontSize: 19 / 1.2,
                                        color: Color(0xFF2F2F37),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: draftShowExcluded,
                                    onChanged: (value) => setModalState(() {
                                      draftShowExcluded = value;
                                    }),
                                    activeColor: Colors.white,
                                    activeTrackColor: const Color(0xFF34C759),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: FinancePrimaryActionButton(
                              label: 'Xoá bộ lọc',
                              backgroundColor: const Color(0xFFE3E1E9),
                              foregroundColor: const Color(0xFF888893),
                              onPressed: hasAnyFilter()
                                  ? () => setModalState(() {
                                      draftSelected.clear();
                                      draftTimeFilter = _CalendarTimeFilter.all;
                                      draftShowExcluded = false;
                                    })
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FinancePrimaryActionButton(
                              label: 'Áp dụng',
                              onPressed: () {
                                Navigator.pop(
                                  ctx,
                                  _CalendarFilterResult(
                                    selectedCategoryKeys: draftSelected,
                                    timeFilter: draftTimeFilter,
                                    showExcludedInReports: draftShowExcluded,
                                  ),
                                );
                              },
                            ),
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
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedCategoryKeys = result.selectedCategoryKeys;
      _timeFilter = result.timeFilter;
      _showExcludedInReports = result.showExcludedInReports;
    });
  }

  Widget _buildHeader() {
    return Container(
      color: FinanceColors.appBarTint,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).maybePop(),
              child: Ink(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: FinanceColors.borderSoft),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 24,
                  color: Color(0xFF2F2F36),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Lịch',
              style: TextStyle(
                fontSize: 42 / 1.25,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F2F37),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: FinanceColors.border),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF303039),
              size: 27,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.support_agent_rounded, color: Color(0xFF4F4F58)),
                SizedBox(width: 8),
                SizedBox(
                  height: 18,
                  child: VerticalDivider(
                    color: Color(0xFFD5D2DC),
                    thickness: 1,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.home_outlined, color: Color(0xFF4F4F58)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthControls(List<FinanceCategory> customCategories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _hideAmounts = !_hideAmounts),
            icon: Icon(
              _hideAmounts
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: const Color(0xFF2F2F37),
              size: 34,
            ),
          ),
          IconButton(
            onPressed: () => _moveMonth(-1),
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 40,
              color: Color(0xFF2F2F37),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                _monthLabel(_month),
                style: const TextStyle(
                  fontSize: 26 / 1.15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2F2F37),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _moveMonth(1),
            icon: const Icon(
              Icons.chevron_right_rounded,
              size: 40,
              color: Color(0xFF2F2F37),
            ),
          ),
          IconButton(
            onPressed: () => _openFilterSheet(customCategories),
            icon: const Icon(
              Icons.filter_alt_outlined,
              size: 34,
              color: Color(0xFF2F2F37),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double income, double expense) {
    final balance = income - expense;

    Widget metric(String label, String value, Color color) {
      return Expanded(
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5F5F68),
                fontSize: 18 / 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _hideAmounts ? '******' : value,
              style: TextStyle(
                color: color,
                fontSize: 24 / 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          metric('Thu nhập', _compactCurrency(income), const Color(0xFF23A34A)),
          const SizedBox(
            height: 56,
            child: VerticalDivider(color: Color(0xFFCCE0F7), thickness: 2),
          ),
          metric(
            'Chi tiêu',
            _compactCurrency(expense),
            const Color(0xFF2F2F37),
          ),
          const SizedBox(
            height: 56,
            child: VerticalDivider(color: Color(0xFFCCE0F7), thickness: 2),
          ),
          metric(
            'Chênh lệch',
            _compactCurrency(balance),
            const Color(0xFF2F2F37),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(Map<int, _CalendarDaySummary> summaryByDay) {
    final firstDayOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final leadingEmpty = firstDayOfMonth.weekday - 1;
    final totalCells = ((leadingEmpty + daysInMonth) / 7).ceil() * 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        children: [
          Row(
            children: const [
              _CalendarWeekLabel('T2'),
              _CalendarWeekLabel('T3'),
              _CalendarWeekLabel('T4'),
              _CalendarWeekLabel('T5'),
              _CalendarWeekLabel('T6'),
              _CalendarWeekLabel('T7'),
              _CalendarWeekLabel('CN'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: totalCells,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final day = index - leadingEmpty + 1;
              if (day < 1 || day > daysInMonth) {
                return const SizedBox.shrink();
              }

              final summary = summaryByDay[day];
              final selected = day == _selectedDay;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    _selectedDay = day;
                  }),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE3E1E9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF1A73E8)
                                  : const Color(0xFF676770),
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w500,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (summary != null && summary.income > 0)
                          Text(
                            _displayAmount(summary.income, forCell: true),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF23A34A),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        if (summary != null && summary.expense > 0)
                          Text(
                            _displayAmount(summary.expense, forCell: true),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: summary.abnormalExpense
                                  ? const Color(0xFFFF3B30)
                                  : const Color(0xFF2F2F37),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
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
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: const [
          _CalendarLegendDot(color: Color(0xFF23A34A), label: 'Thu'),
          _CalendarLegendDot(color: Color(0xFF2F2F37), label: 'Chi'),
          _CalendarLegendDot(
            color: Color(0xFFFF3B30),
            label: 'Chi cao bất thường',
          ),
          Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF777781)),
        ],
      ),
    );
  }

  Widget _buildListHeaderHandle() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _showTransactionList = !_showTransactionList;
      }),
      child: Center(
        child: Container(
          width: 128,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
          child: Icon(
            _showTransactionList
                ? Icons.keyboard_double_arrow_down_rounded
                : Icons.keyboard_double_arrow_up_rounded,
            color: const Color(0xFF7A7A83),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    SplayTreeMap<DateTime, List<FinanceTransaction>> grouped,
  ) {
    if (grouped.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: const Text(
            'Không có giao dịch phù hợp bộ lọc hiện tại.',
            style: TextStyle(
              color: Color(0xFF676770),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: grouped.entries.map((entry) {
          final day = entry.key;
          final items = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF1F8),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    '${day.day}/${day.month}/${day.year}',
                    style: const TextStyle(
                      color: Color(0xFF3A3A42),
                      fontWeight: FontWeight.w800,
                      fontSize: 20 / 1.15,
                    ),
                  ),
                ),
                ...List.generate(items.length, (index) {
                  final tx = items[index];
                  final income = tx.type == TransactionType.income;

                  return Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      border: index == items.length - 1
                          ? null
                          : const Border(
                              bottom: BorderSide(color: Color(0xFFE7E5EC)),
                            ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2DFE8)),
                          ),
                          child: Icon(
                            income
                                ? Icons.monetization_on_outlined
                                : Icons.shopping_cart_outlined,
                            color: income
                                ? const Color(0xFFFF8A24)
                                : const Color(0xFF7A7A83),
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF2F2F37),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24 / 1.15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: income
                                        ? const Color(0xFF39C766)
                                        : const Color(0xFFE0DDE7),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      income
                                          ? Icons.eco_outlined
                                          : Icons.category_outlined,
                                      color: income
                                          ? const Color(0xFF39C766)
                                          : const Color(0xFF6D6D76),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tx.category,
                                      style: TextStyle(
                                        color: income
                                            ? const Color(0xFF3B3B43)
                                            : const Color(0xFF6D6D76),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18 / 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF6D6D76),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _hideAmounts
                              ? '******'
                              : '${income ? '+' : '-'}${_compactCurrency(tx.amount)}',
                          style: TextStyle(
                            color: income
                                ? const Color(0xFF23A34A)
                                : const Color(0xFF2F2F37),
                            fontWeight: FontWeight.w900,
                            fontSize: 24 / 1.1,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final monthTransactions = _resolveMonthTransactions(provider);
    final summaryByDay = _buildDaySummaries(monthTransactions);
    final grouped = _groupByDay(monthTransactions);
    final customCategories = provider.customCategories;

    final income = monthTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final expense = monthTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return ColoredBox(
      color: FinanceColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildMonthControls(customCategories),
            _buildSummaryCard(income, expense),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildCalendarGrid(summaryByDay),
                  _buildLegend(),
                  _buildListHeaderHandle(),
                  if (_showTransactionList) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        'Danh sách giao dịch',
                        style: TextStyle(
                          fontSize: 46 / 1.35,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2F2F37),
                        ),
                      ),
                    ),
                    _buildTransactionList(grouped),
                  ] else
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarWeekLabel extends StatelessWidget {
  const _CalendarWeekLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFB1B1BA),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF5F5F68),
            fontSize: 19 / 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CalendarTimeFilterTile extends StatelessWidget {
  const _CalendarTimeFilterTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isLast = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(16),
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1F8) : Colors.transparent,
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFE8E6EE)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5A5A63), size: 38),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF2F2F37),
                fontSize: 22 / 1.15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RecurringScreenTab { upcoming, repeating }

enum _RecurringItemBucket { bill, manual }

enum _RecurringItemMenuAction { edit, delete }

enum _RecurringAddAction { markOld, reminder }

class _RecurringListItem {
  const _RecurringListItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.scheduleLabel,
    this.amount,
    this.subtitle,
    this.recurring,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String scheduleLabel;
  final double? amount;
  final String? subtitle;
  final FinanceRecurringTransaction? recurring;
}

class _FinanceRecurringTab extends StatefulWidget {
  const _FinanceRecurringTab();

  @override
  State<_FinanceRecurringTab> createState() => _FinanceRecurringTabState();
}

class _FinanceRecurringTabState extends State<_FinanceRecurringTab> {
  static const Color _headerTint = FinanceColors.appBarTint;

  static const List<_RecurringListItem> _upcomingItems = [
    _RecurringListItem(
      title: 'Chi tiêu cho Ăn uống',
      icon: Icons.lunch_dining_rounded,
      iconColor: Color(0xFFFF7E45),
      scheduleLabel: 'Chi sau 7 ngày',
      amount: 100,
    ),
    _RecurringListItem(
      title: 'Chi tiêu cho Ăn uống',
      icon: Icons.lunch_dining_rounded,
      iconColor: Color(0xFFFF7E45),
      scheduleLabel: 'Chi sau 14 ngày',
      amount: 100,
    ),
    _RecurringListItem(
      title: 'Chi tiêu cho Ăn uống',
      icon: Icons.lunch_dining_rounded,
      iconColor: Color(0xFFFF7E45),
      scheduleLabel: 'Chi sau 21 ngày',
      amount: 100,
    ),
    _RecurringListItem(
      title: 'Chi tiêu cho Ăn uống',
      icon: Icons.lunch_dining_rounded,
      iconColor: Color(0xFFFF7E45),
      scheduleLabel: 'Chi sau 28 ngày',
      amount: 100,
    ),
    _RecurringListItem(
      title: 'Chi tiêu cho Ăn uống',
      icon: Icons.lunch_dining_rounded,
      iconColor: Color(0xFFFF7E45),
      scheduleLabel: 'Chi sau 28 ngày',
      amount: 100,
    ),
  ];

  static const List<_RecurringListItem> _initialBillRecurringItems = [
    _RecurringListItem(
      title: 'Thanh toán Công ty Nước sạch số 2 Hà Nội',
      subtitle: 'Nguồn tiền: Ví chính',
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF13C5CE),
      scheduleLabel: 'Lần tới khi có hóa đơn',
    ),
    _RecurringListItem(
      title: 'Thanh toán Công ty Nước sạch số 2 Hà Nội',
      subtitle: 'Nguồn tiền: Ví chính',
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF13C5CE),
      scheduleLabel: 'Lần tới khi có hóa đơn',
    ),
    _RecurringListItem(
      title: 'Thanh toán Điện lực Hà Nội',
      subtitle: 'Nguồn tiền: Ví chính',
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF13C5CE),
      scheduleLabel: 'Lần tới khi có hóa đơn',
    ),
    _RecurringListItem(
      title: 'Thanh toán FPT Telecom',
      subtitle: 'Nguồn tiền: Ví chính',
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF13C5CE),
      scheduleLabel: 'Lần tới khi có hóa đơn',
    ),
  ];

  static const List<_RecurringListItem> _initialManualRecurringItems = [
    _RecurringListItem(
      title: 'Chi tiêu cho Ăn uống',
      icon: Icons.lunch_dining_rounded,
      iconColor: Color(0xFFFF7E45),
      scheduleLabel: 'Hàng tuần ▸ Chủ nhật',
      amount: 100,
    ),
    _RecurringListItem(
      title: 'Chi tiêu cho Ăn uống',
      icon: Icons.lunch_dining_rounded,
      iconColor: Color(0xFFFF7E45),
      scheduleLabel: 'Hàng tháng ▸ Ngày 12',
      amount: 100,
    ),
    _RecurringListItem(
      title: 'Chi tiêu cho Ăn uống',
      icon: Icons.lunch_dining_rounded,
      iconColor: Color(0xFFFF7E45),
      scheduleLabel: 'Hàng tuần ▸ Chủ nhật',
      amount: 100,
    ),
  ];

  _RecurringScreenTab _tab = _RecurringScreenTab.upcoming;
  bool _showGuideCard = true;
  late final List<_RecurringListItem> _billRecurringItems =
      List<_RecurringListItem>.from(_initialBillRecurringItems);
  late final List<_RecurringListItem> _manualRecurringTemplateItems =
      List<_RecurringListItem>.from(_initialManualRecurringItems);

  List<_RecurringListItem> _buildManualRecurringItems(
    List<FinanceRecurringTransaction> source,
  ) {
    final realItems = source.map(_mapRecurringToListItem).toList();
    return [...realItems, ..._manualRecurringTemplateItems];
  }

  _RecurringListItem _mapRecurringToListItem(
    FinanceRecurringTransaction recurring,
  ) {
    final title = recurring.title.trim().isEmpty
        ? (recurring.type == TransactionType.expense
              ? 'Chi tiêu cho ${recurring.category}'
              : 'Thu nhập từ ${recurring.category}')
        : recurring.title.trim();

    final fallbackIcon = recurring.type == TransactionType.expense
        ? Icons.lunch_dining_rounded
        : Icons.south_west_rounded;
    final fallbackColor = recurring.type == TransactionType.expense
        ? const Color(0xFFFF7E45)
        : const Color(0xFF55AF70);

    return _RecurringListItem(
      title: title,
      icon: recurring.categoryIcon ?? fallbackIcon,
      iconColor: recurring.categoryIconColor ?? fallbackColor,
      scheduleLabel: recurringScheduleChipLabel(recurring),
      amount: recurring.amount,
      recurring: recurring,
    );
  }

  Future<void> _openRecurringDetail(
    FinanceRecurringTransaction recurring,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            FinanceRecurringTransactionDetailScreen(recurringId: recurring.id),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _headerTint,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).maybePop(),
              child: Ink(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: FinanceColors.borderSoft),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 24,
                  color: Color(0xFF2F2F36),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Giao dịch định kỳ',
              style: TextStyle(
                fontSize: 42 / 1.25,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F2F37),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.support_agent_rounded, color: Color(0xFF4F4F58)),
                SizedBox(width: 8),
                SizedBox(
                  height: 18,
                  child: VerticalDivider(
                    color: Color(0xFFD5D2DC),
                    thickness: 1,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.home_outlined, color: Color(0xFF4F4F58)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _RecurringTopTab(
            label: 'Sắp tới',
            selected: _tab == _RecurringScreenTab.upcoming,
            onTap: () => setState(() => _tab = _RecurringScreenTab.upcoming),
          ),
          _RecurringTopTab(
            label: 'Định kỳ',
            selected: _tab == _RecurringScreenTab.repeating,
            onTap: () => setState(() => _tab = _RecurringScreenTab.repeating),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 96,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.edit_calendar_rounded,
              size: 52,
              color: Color(0xFF4D9AE5),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Theo dõi trước các khoản sắp tới',
                  style: TextStyle(
                    fontSize: 22 / 1.1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F2F37),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Nắm trước các giao dịch sắp đến hạn để không lo trừ tiền ngoài ý muốn.',
                  style: TextStyle(
                    color: Color(0xFF6C6C75),
                    fontSize: 17 / 1.1,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                onPressed: () => setState(() => _showGuideCard = false),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF34343C),
                  size: 34,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _showGuideCard = false),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFEAF4),
                  foregroundColor: FinanceColors.accentPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Đã hiểu',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20 / 1.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEmptyCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.event_available_rounded,
            size: 126,
            color: Color(0xFFD5439E),
          ),
          SizedBox(height: 12),
          Text(
            'Hết khoản cần lo tháng này rồi!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 24 / 1.1,
              color: Color(0xFF2F2F37),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'MoMo sẽ nhắc bạn khi có giao dịch mới cần chú ý',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF55555E),
              fontWeight: FontWeight.w600,
              fontSize: 17 / 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Future<_RecurringItemMenuAction?> _showRecurringItemMenuSheet({
    required bool isExpense,
  }) {
    return showModalBottomSheet<_RecurringItemMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.3,
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
                            'Tùy chỉnh',
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
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FinanceColors.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF34343C),
                          size: 32,
                        ),
                        title: const Text(
                          'Chỉnh sửa giao dịch',
                          style: TextStyle(
                            fontSize: 34 / 1.4,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF34343C),
                          ),
                        ),
                        onTap: () =>
                            Navigator.pop(ctx, _RecurringItemMenuAction.edit),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFFF2F4C),
                          size: 32,
                        ),
                        title: Text(
                          isExpense ? 'Xóa chi tiêu' : 'Xóa thu nhập',
                          style: const TextStyle(
                            fontSize: 34 / 1.4,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF2F4C),
                          ),
                        ),
                        onTap: () =>
                            Navigator.pop(ctx, _RecurringItemMenuAction.delete),
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

  Future<void> _onRecurringItemMenuTap({
    required _RecurringItemBucket bucket,
    required _RecurringListItem item,
  }) async {
    final isExpense = item.recurring?.type == TransactionType.expense
        ? true
        : item.recurring?.type == TransactionType.income
        ? false
        : (item.amount == null || item.amount! <= 0);
    final action = await _showRecurringItemMenuSheet(isExpense: isExpense);
    if (action == null || !mounted) {
      return;
    }

    switch (action) {
      case _RecurringItemMenuAction.edit:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FinanceRecurringReminderScreen(
              initialType: isExpense
                  ? TransactionType.expense
                  : TransactionType.income,
              editingRecurringId: item.recurring?.id,
            ),
          ),
        );
        return;
      case _RecurringItemMenuAction.delete:
        if (item.recurring != null) {
          await context.read<FinanceProvider>().removeRecurringTransaction(
            item.recurring!.id,
          );
        } else {
          setState(() {
            final source = bucket == _RecurringItemBucket.bill
                ? _billRecurringItems
                : _manualRecurringTemplateItems;
            source.remove(item);
          });
        }
        showAppToast(
          context,
          message: isExpense
              ? 'Đã xóa chi tiêu định kỳ.'
              : 'Đã xóa thu nhập định kỳ.',
          type: AppToastType.success,
        );
        return;
    }
  }

  Future<_RecurringAddAction?> _showAddRecurringActionSheet() {
    return showModalBottomSheet<_RecurringAddAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.47,
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
                            'Thêm giao dịch định kỳ',
                            style: TextStyle(
                              fontSize: 20,
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
                _RecurringAddActionTile(
                  icon: Icons.history_toggle_off_rounded,
                  iconColor: FinanceColors.accentPrimary,
                  iconBackground: const Color(0xFFFFEAF4),
                  title: 'Đánh dấu GD cũ',
                  onTap: () => Navigator.pop(ctx, _RecurringAddAction.markOld),
                ),
                _RecurringAddActionTile(
                  icon: Icons.event_repeat_rounded,
                  iconColor: const Color(0xFF2B8EF7),
                  iconBackground: const Color(0xFFEAF2FF),
                  title: 'Lời nhắc định kỳ',
                  onTap: () => Navigator.pop(ctx, _RecurringAddAction.reminder),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onTapAddRecurringAction() async {
    final action = await _showAddRecurringActionSheet();
    if (action == null || !mounted) {
      return;
    }

    switch (action) {
      case _RecurringAddAction.markOld:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FinancePastRecurringSelectionScreen(),
          ),
        );
        return;
      case _RecurringAddAction.reminder:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FinanceRecurringReminderScreen(),
          ),
        );
        return;
    }
  }

  Widget _buildListItemTile(
    _RecurringListItem item, {
    required bool showMenu,
    required bool showAmount,
    VoidCallback? onTap,
    VoidCallback? onMoreTap,
    bool scheduleChipBlue = false,
  }) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2DFE8)),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 32),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24 / 1.1,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F2F37),
                  ),
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6E6E78),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheduleChipBlue
                        ? const Color(0xFFEAF3FF)
                        : const Color(0xFFF3F3F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.scheduleLabel,
                    style: TextStyle(
                      color: scheduleChipBlue
                          ? const Color(0xFF217CE6)
                          : const Color(0xFF74747D),
                      fontWeight: FontWeight.w700,
                      fontSize: 18 / 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showAmount && item.amount != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      _compactCurrency(item.amount!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 23 / 1.1,
                        color: Color(0xFF2F2F37),
                      ),
                    ),
                  ),
                ),
              if (showMenu)
                IconButton(
                  onPressed: onMoreTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFFC6C4CB),
                    size: 28,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }

  Widget _buildUpcomingTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      children: [
        if (_showGuideCard) _buildGuideCard(),
        const Text(
          '2 ngày còn lại tháng 03/2026',
          style: TextStyle(
            fontSize: 50 / 1.35,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2D2D35),
          ),
        ),
        const SizedBox(height: 12),
        _buildUpcomingEmptyCard(),
        const Text(
          'Tháng 4/2026',
          style: TextStyle(
            fontSize: 50 / 1.35,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2D2D35),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Row(
            children: const [
              Expanded(
                child: Text(
                  'Dự chi',
                  style: TextStyle(
                    fontSize: 25 / 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF32323A),
                  ),
                ),
              ),
              Text(
                '900đ',
                style: TextStyle(
                  fontSize: 25 / 1.2,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2F2F37),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Column(
            children: List.generate(_upcomingItems.length, (index) {
              final item = _upcomingItems[index];
              return Column(
                children: [
                  _buildListItemTile(
                    item,
                    showMenu: false,
                    showAmount: true,
                    onTap: item.recurring != null
                        ? () => _openRecurringDetail(item.recurring!)
                        : null,
                  ),
                  if (index < _upcomingItems.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE4E3EA),
                      indent: 120,
                      endIndent: 14,
                    ),
                ],
              );
            }),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Column(
            children: [
              const Text(
                'Thêm giao dịch sắp tới',
                style: TextStyle(
                  fontSize: 50 / 1.35,
                  color: Color(0xFF2D2D35),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ví dụ: Hạn thanh toán thẻ tín dụng, app store,... để được MoMo nhắc bạn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22 / 1.2,
                  color: Color(0xFF66666F),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _onTapAddRecurringAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: FinanceColors.accentPrimary,
                  side: const BorderSide(color: FinanceColors.accentPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Thêm giao dịch',
                  style: TextStyle(
                    fontSize: 24 / 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatingSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color headerColor,
    required List<_RecurringListItem> items,
    required bool showAmount,
    required bool chipBlue,
    required _RecurringItemBucket bucket,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 23 / 1.1,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF36363F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              children: [
                _buildListItemTile(
                  item,
                  showMenu: true,
                  showAmount: showAmount,
                  onTap: item.recurring != null
                      ? () => _openRecurringDetail(item.recurring!)
                      : null,
                  onMoreTap: () =>
                      _onRecurringItemMenuTap(bucket: bucket, item: item),
                  scheduleChipBlue: chipBlue,
                ),
                if (index < items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE4E3EA),
                    indent: 120,
                    endIndent: 14,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRepeatingTab(List<_RecurringListItem> manualItems) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Giao dịch định kỳ',
                style: TextStyle(
                  fontSize: 50 / 1.35,
                  color: Color(0xFF2D2D35),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thêm giao dịch định kỳ (App Store, Mã hóa đơn, Chuyển tiền hàng tháng) để được nhắc nhở, tránh mất tiền hoặc quên thanh toán ngoài ý muốn',
                style: TextStyle(
                  color: Color(0xFF46464F),
                  fontSize: 22 / 1.2,
                  fontWeight: FontWeight.w600,
                  height: 1.38,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _onTapAddRecurringAction,
                  icon: const Icon(Icons.add, size: 34),
                  label: const Text(
                    'Thêm giao dịch',
                    style: TextStyle(
                      fontSize: 24 / 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF7DDEA),
                    foregroundColor: FinanceColors.accentPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildRepeatingSection(
          title: 'Hóa đơn định kỳ',
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFF13C5CE),
          headerColor: const Color(0xFFE8F5F8),
          items: _billRecurringItems,
          showAmount: false,
          chipBlue: false,
          bucket: _RecurringItemBucket.bill,
        ),
        _buildRepeatingSection(
          title: 'Nhập thủ công',
          icon: Icons.note_alt_outlined,
          iconColor: const Color(0xFF2580EB),
          headerColor: const Color(0xFFEAF2FB),
          items: manualItems,
          showAmount: true,
          chipBlue: true,
          bucket: _RecurringItemBucket.manual,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final manualItems = _buildManualRecurringItems(
      provider.recurringTransactions,
    );

    return ColoredBox(
      color: FinanceColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTopTabs(),
            Expanded(
              child: _tab == _RecurringScreenTab.upcoming
                  ? _buildUpcomingTab()
                  : _buildRepeatingTab(manualItems),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringAddActionTile extends StatelessWidget {
  const _RecurringAddActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 38),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24 / 1.15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F2F37),
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

class _RecurringTopTab extends StatelessWidget {
  const _RecurringTopTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? FinanceColors.accentPrimary
                  : const Color(0xFF32323A),
              fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
              fontSize: 24 / 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoniChatMessage {
  const _MoniChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _MoniChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return _MoniChatMessage(
      id:
          map['id'] as String? ??
          'msg-${DateTime.now().microsecondsSinceEpoch}',
      role: map['role'] as String? ?? 'assistant',
      content: map['content'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class _FinanceMoniTab extends StatefulWidget {
  const _FinanceMoniTab();

  @override
  State<_FinanceMoniTab> createState() => _FinanceMoniTabState();
}

class _FinanceMoniTabState extends State<_FinanceMoniTab> {
  static const String _chatStorageKey = 'moni_chat_history_v1';
  static const String _chatStorageVersion = 'v1';
  static const String _welcomeMessage =
      'Moni có thể giúp bạn quản lý chi tiêu tự động, phân tích xu hướng và gợi ý hành động phù hợp. Hãy nhắn mình điều bạn cần nhé!';

  static const List<String> _quickActions = [
    'Mẹo chi tiêu hiệu quả với Moni',
    'Ghi chép chi tiêu qua chat',
    'Đặt ngân sách chi tiêu tháng này',
  ];

  static const List<String> _suggestedPrompts = [
    'Hướng dẫn quản lý chi tiêu cá nhân',
    'Phân tích chi tiêu ăn uống tuần này',
    'Lập kế hoạch tiết kiệm 20% thu nhập',
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_MoniChatMessage> _messages = <_MoniChatMessage>[];
  bool _historyHydrated = false;
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_historyHydrated) {
      return;
    }
    _historyHydrated = true;
    _hydrateHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _hydrateHistory() async {
    final storage = context.read<LocalStorageService>();
    final rows = await storage.readList(_scopedChatStorageKey());
    final loaded =
        rows
            .map(
              (row) =>
                  _MoniChatMessage.fromMap(Map<dynamic, dynamic>.from(row)),
            )
            .where((item) => item.content.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (!mounted) {
      return;
    }

    setState(() {
      _messages
        ..clear()
        ..addAll(loaded);
      if (_messages.isEmpty) {
        _messages.add(
          _MoniChatMessage(
            id: 'assistant-welcome',
            role: 'assistant',
            content: _welcomeMessage,
            createdAt: DateTime.now(),
          ),
        );
      }
    });
    _scrollToBottom();
  }

  Future<void> _persistHistory() async {
    final storage = context.read<LocalStorageService>();
    await storage.saveList(
      _scopedChatStorageKey(),
      _messages.map((item) => item.toMap()).toList(),
    );
  }

  String _scopedChatStorageKey() {
    final userId = context.read<AuthProvider>().userId.trim();
    final scope = userId.isEmpty ? 'guest' : userId;
    return 'u:$scope:$_chatStorageKey:$_chatStorageVersion';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  double? _parseAmountToken(String raw, String? unitRaw) {
    final compact = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (compact.isEmpty) {
      return null;
    }
    var value = double.tryParse(compact);
    if (value == null || value <= 0) {
      return null;
    }

    final unit = (unitRaw ?? '').toLowerCase().trim();
    if (unit == 'k' || unit == 'nghin' || unit == 'nghìn') {
      value *= 1000;
    } else if (unit == 'tr' || unit == 'trieu' || unit == 'triệu') {
      value *= 1000000;
    }
    return value;
  }

  String _fallbackCategoryFor(TransactionType type, String normalizedPrompt) {
    if (type == TransactionType.income) {
      if (normalizedPrompt.contains('thuong') ||
          normalizedPrompt.contains('thưởng')) {
        return 'Thưởng';
      }
      if (normalizedPrompt.contains('kinh doanh') ||
          normalizedPrompt.contains('ban hang')) {
        return 'Kinh doanh';
      }
      return 'Lương';
    }

    if (normalizedPrompt.contains('xang') || normalizedPrompt.contains('xe')) {
      return 'Di chuyển';
    }
    if (normalizedPrompt.contains('sieu thi') ||
        normalizedPrompt.contains('cho')) {
      return 'Chợ, siêu thị';
    }
    if (normalizedPrompt.contains('hoa don') ||
        normalizedPrompt.contains('bill')) {
      return 'Hóa đơn';
    }
    if (normalizedPrompt.contains('giai tri')) {
      return 'Giải trí';
    }
    return 'Ăn uống';
  }

  String _resolveCategory(
    String? categoryFromPrompt,
    TransactionType type,
    FinanceProvider provider,
    String normalizedPrompt,
  ) {
    final custom = provider.customCategories
        .where((item) => item.type == type)
        .map((item) => item.name)
        .toList();

    final typed = (categoryFromPrompt ?? '').trim();
    if (typed.isNotEmpty) {
      final lowerTyped = typed.toLowerCase();
      for (final name in custom) {
        final lower = name.toLowerCase();
        if (lower == lowerTyped ||
            lower.contains(lowerTyped) ||
            lowerTyped.contains(lower)) {
          return name;
        }
      }
      return typed;
    }

    return _fallbackCategoryFor(type, normalizedPrompt);
  }

  Future<String?> _maybeCreateTransactionFromPrompt(String prompt) async {
    final normalized = prompt.trim();
    final lowered = normalized.toLowerCase();
    final reg = RegExp(
      r'^(chi|thu)\s+([0-9][0-9\.,]*)\s*(k|nghin|nghìn|tr|trieu|triệu|vnd|đ|d)?(?:\s+(.+))?$',
      caseSensitive: false,
    );
    final match = reg.firstMatch(lowered);
    if (match == null) {
      return null;
    }

    final verb = (match.group(1) ?? '').toLowerCase();
    final amountRaw = match.group(2) ?? '';
    final unitRaw = match.group(3);
    final categoryRaw = match.group(4);

    final amount = _parseAmountToken(amountRaw, unitRaw);
    if (amount == null) {
      return 'Mình chưa đọc được số tiền. Bạn thử theo mẫu: "chi 50k ăn uống" hoặc "thu 12tr lương" nhé.';
    }

    final finance = context.read<FinanceProvider>();
    final type = verb == 'thu'
        ? TransactionType.income
        : TransactionType.expense;
    final category = _resolveCategory(categoryRaw, type, finance, lowered);

    final tx = FinanceTransaction(
      id: 'trx-moni-${DateTime.now().microsecondsSinceEpoch}',
      title: type == TransactionType.expense
          ? 'Chi tiêu qua chat Moni'
          : 'Thu nhập qua chat Moni',
      amount: amount,
      category: category,
      type: type,
      createdAt: DateTime.now(),
      note: 'Tạo từ Moni chat: $normalized',
      includedInReports: true,
    );

    await finance.addTransaction(tx);

    final sign = type == TransactionType.expense ? '-' : '+';
    return 'Mình đã ghi nhận $sign${_compactCurrency(amount)} vào danh mục "$category".';
  }

  Future<void> _send([String? presetPrompt]) async {
    if (_sending) {
      return;
    }
    final prompt = (presetPrompt ?? _inputController.text).trim();
    if (prompt.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
      _messages.add(
        _MoniChatMessage(
          id: 'user-${DateTime.now().microsecondsSinceEpoch}',
          role: 'user',
          content: prompt,
          createdAt: DateTime.now(),
        ),
      );
      _inputController.clear();
    });
    _scrollToBottom();

    String reply;
    try {
      final structuredReply = await _maybeCreateTransactionFromPrompt(prompt);
      if (structuredReply != null) {
        reply = structuredReply;
      } else {
        reply = await context.read<AIAssistantService>().reply(prompt);
      }
    } catch (_) {
      reply =
          'Hiện tại mình chưa phản hồi được. Bạn thử lại sau vài giây hoặc nhập ngắn gọn hơn nhé.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(
        _MoniChatMessage(
          id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
          role: 'assistant',
          content: reply,
          createdAt: DateTime.now(),
        ),
      );
      _sending = false;
    });
    await _persistHistory();
    _scrollToBottom();
  }

  Widget _buildHeaderBar() {
    return Container(
      color: FinanceColors.appBarTint,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).maybePop(),
              child: Ink(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: FinanceColors.borderSoft),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 24,
                  color: Color(0xFF2F2F36),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Moni',
              style: TextStyle(
                fontSize: 42 / 1.25,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F2F37),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.support_agent_rounded, color: Color(0xFF4F4F58)),
                SizedBox(width: 8),
                SizedBox(
                  height: 18,
                  child: VerticalDivider(
                    color: Color(0xFFD5D2DC),
                    thickness: 1,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.home_outlined, color: Color(0xFF4F4F58)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(FinanceProvider provider) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final monthTransactions = provider.filterTransactions(month: month);
    final monthIncome = monthTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final monthExpense = monthTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final quickIntro =
        'Tháng này: Thu ${_compactCurrency(monthIncome)}  •  '
        'Chi ${_compactCurrency(monthExpense)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF2C7DF), width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/icons/bard.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dạo này tiền bạc ổn không\nMình ơi!',
                  style: TextStyle(
                    color: Color(0xFF1E8FEA),
                    fontSize: 36 / 1.35,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _messages.isEmpty ? _welcomeMessage : _messages.first.content,
            style: const TextStyle(
              color: Color(0xFF4A4A52),
              fontSize: 22 / 1.2,
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              quickIntro,
              style: const TextStyle(
                color: Color(0xFF6D6D76),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ..._quickActions.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _send(text),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F7FC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF6F6F78),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Color(0xFF31313A),
                            fontWeight: FontWeight.w700,
                            fontSize: 20 / 1.2,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF44444D),
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

  Widget _buildSuggestionCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'Gợi ý Moni dành cho bạn',
            style: TextStyle(
              color: Color(0xFF2F2F37),
              fontSize: 28 / 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestedPrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final prompt = _suggestedPrompts[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _send(prompt),
                child: Container(
                  width: 210,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FinanceColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(
                            color: Color(0xFF31313A),
                            fontWeight: FontWeight.w700,
                            fontSize: 20 / 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        children: [
          ..._messages.map((message) {
            return Align(
              alignment: message.isUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? const Color(0xFFFFE8F4)
                      : const Color(0xFFF4F6FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(
                    color: Color(0xFF2F2F37),
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                  ),
                ),
              ),
            );
          }),
          if (_sending)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: 4),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 8, 16, viewInsets + 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FinanceColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Nhập nội dung...',
                  hintStyle: TextStyle(color: Color(0xFF8A8A93)),
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE2E0E8),
            ),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, color: Color(0xFF7D7D86)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    return ColoredBox(
      color: FinanceColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeaderBar(),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                children: [
                  _buildHero(provider),
                  _buildSuggestionCards(),
                  _buildMessagesPanel(),
                ],
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }
}

enum _UtilityFeatureAction {
  addTransaction,
  cashflow,
  classify,
  categories,
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

class _UtilityFeatureEntry {
  const _UtilityFeatureEntry({
    required this.action,
    required this.label,
    required this.icon,
    this.badgeText,
    this.badgeColor,
  });

  final _UtilityFeatureAction action;
  final String label;
  final IconData icon;
  final String? badgeText;
  final Color? badgeColor;
}

class _UtilityReportCardData {
  const _UtilityReportCardData({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.hasUnreadDot = false,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final bool hasUnreadDot;
}

class _FinanceUtilitiesTab extends StatefulWidget {
  const _FinanceUtilitiesTab({required this.onOpenOverview});

  final VoidCallback onOpenOverview;

  @override
  State<_FinanceUtilitiesTab> createState() => _FinanceUtilitiesTabState();
}

class _FinanceUtilitiesTabState extends State<_FinanceUtilitiesTab> {
  static const List<_UtilityFeatureEntry> _features = [
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.addTransaction,
      label: 'Nhập giao dịch',
      icon: Icons.note_add_outlined,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.cashflow,
      label: 'Biến động thu chi',
      icon: Icons.query_stats_rounded,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.classify,
      label: 'Phân loại giao dịch',
      icon: Icons.local_offer_outlined,
      badgeText: '1',
      badgeColor: Color(0xFFFF2D55),
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.categories,
      label: 'Quản lý danh mục',
      icon: Icons.folder_outlined,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.recurring,
      label: 'Giao dịch định kỳ',
      icon: Icons.event_repeat_rounded,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.budget,
      label: 'Ngân sách chi tiêu',
      icon: Icons.savings_outlined,
      badgeText: '+ Xu',
      badgeColor: Color(0xFFFF7A1A),
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.community,
      label: 'Cộng đồng chi tiêu',
      icon: Icons.desktop_windows_outlined,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.addDevice,
      label: 'Thêm vào thiết bị',
      icon: Icons.add_to_home_screen_rounded,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.removeHome,
      label: 'Gỡ khỏi trang chủ',
      icon: Icons.auto_awesome_outlined,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.calendar,
      label: 'Lịch',
      icon: Icons.calendar_month_outlined,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.moni,
      label: 'Moni (AI)',
      icon: Icons.smart_toy_outlined,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.intro,
      label: 'Giới thiệu tính năng',
      icon: Icons.menu_book_outlined,
    ),
    _UtilityFeatureEntry(
      action: _UtilityFeatureAction.transactionLimit,
      label: 'Hạn mức giao dịch',
      icon: Icons.speed_rounded,
    ),
  ];

  static const List<_UtilityReportCardData> _reportCards = [
    _UtilityReportCardData(
      title: 'Tháng',
      subtitle: '2/2026',
      accent: Color(0xFFF3BF17),
      hasUnreadDot: true,
    ),
    _UtilityReportCardData(
      title: 'Tuần:',
      subtitle: '23/3 - 29/3',
      accent: Color(0xFFF3ABD0),
      hasUnreadDot: true,
    ),
    _UtilityReportCardData(
      title: 'Tuần:',
      subtitle: '9/3 - 15/3',
      accent: Color(0xFFC6C1F4),
    ),
  ];

  bool _receiveReportNotification = true;

  void _showHint(String message) {
    showAppToast(context, message: message, type: AppToastType.info);
  }

  Future<void> _showBudgetEditor() async {
    final provider = context.read<FinanceProvider>();
    final controller = TextEditingController(
      text: provider.monthlyBudget.toStringAsFixed(0),
    );

    final nextBudget = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cập nhật ngân sách tháng'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ngân sách mới',
              hintText: 'Ví dụ: 2500000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  return;
                }
                Navigator.pop(ctx, value);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );

    if (nextBudget == null) {
      return;
    }

    await provider.updateBudget(nextBudget);
    if (!mounted) {
      return;
    }
    _showHint('Đã cập nhật ngân sách tháng.');
  }

  void _onFeatureTap(_UtilityFeatureAction action) {
    switch (action) {
      case _UtilityFeatureAction.addTransaction:
        widget.onOpenOverview();
        _showHint('Đã chuyển tới tab Tổng quan để nhập giao dịch.');
        return;
      case _UtilityFeatureAction.budget:
        _showBudgetEditor();
        return;
      case _UtilityFeatureAction.calendar:
        _showHint(
          'Bạn đang xem tab Tiện ích. Vào tab Lịch để xem lịch thu chi.',
        );
        return;
      case _UtilityFeatureAction.moni:
        _showHint('Moni (AI) hiện có trong tab riêng ở thanh điều hướng dưới.');
        return;
      case _UtilityFeatureAction.categories:
        _showHint(
          'Quản lý danh mục hiện hỗ trợ trong luồng tiện ích tài chính.',
        );
        return;
      case _UtilityFeatureAction.classify:
        _showHint(
          'Mở Phân loại giao dịch từ tab Tổng quan -> Tiện ích để xử lý nhanh.',
        );
        return;
      case _UtilityFeatureAction.cashflow:
        _showHint('Biến động thu chi sẽ mở trong bản cập nhật tiếp theo.');
        return;
      case _UtilityFeatureAction.recurring:
        _showHint('Vào tab GĐ định kỳ để quản lý giao dịch lặp lại.');
        return;
      case _UtilityFeatureAction.community:
      case _UtilityFeatureAction.addDevice:
      case _UtilityFeatureAction.removeHome:
      case _UtilityFeatureAction.intro:
      case _UtilityFeatureAction.transactionLimit:
        _showHint('Tính năng đang được hoàn thiện.');
        return;
    }
  }

  Widget _buildHeader() {
    return Container(
      color: FinanceColors.appBarTint,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).maybePop(),
              child: Ink(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: FinanceColors.borderSoft),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 24,
                  color: Color(0xFF2F2F36),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tiện ích',
              style: TextStyle(
                fontSize: 42 / 1.25,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F2F37),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: FinanceColors.border),
            ),
            child: Row(
              children: const [
                Icon(Icons.support_agent_rounded, color: Color(0xFF4F4F58)),
                SizedBox(width: 8),
                SizedBox(
                  height: 18,
                  child: VerticalDivider(
                    color: Color(0xFFD5D2DC),
                    thickness: 1,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.home_outlined, color: Color(0xFF4F4F58)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Báo cáo chi tiêu định kỳ',
            style: TextStyle(
              color: Color(0xFF2F2F37),
              fontSize: 24 / 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _reportCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final data = _reportCards[index];
                return _UtilityReportCard(data: data);
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Nhận thông báo khi có báo cáo chi tiêu',
                  style: TextStyle(
                    color: Color(0xFF5A5A63),
                    fontSize: 19 / 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _receiveReportNotification,
                onChanged: (value) => setState(() {
                  _receiveReportNotification = value;
                }),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF34C759),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEFF7), Color(0xFFFEEAF4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD8EB)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vòng quay Chill Tài\nTrúng tới 1 triệu xu',
                  style: TextStyle(
                    color: Color(0xFF1F1F27),
                    fontSize: 24 / 1.1,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Chơi ngay!',
                  style: TextStyle(
                    color: Color(0xFF2F2F37),
                    fontSize: 19 / 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                _PromoTinyTag(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Positioned(
                  right: 4,
                  top: 8,
                  child: Icon(
                    Icons.savings_outlined,
                    size: 34,
                    color: Color(0xFFF3BF17),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Icon(
                    Icons.savings_outlined,
                    size: 34,
                    color: Color(0xFFF3BF17),
                  ),
                ),
                Icon(
                  Icons.pets_rounded,
                  size: 78,
                  color: FinanceColors.accentPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedToolsPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiện ích nâng cao',
            style: TextStyle(
              color: Color(0xFF2F2F37),
              fontSize: 24 / 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: _features.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
              childAspectRatio: 0.63,
            ),
            itemBuilder: (context, index) {
              final feature = _features[index];
              return _UtilityFeatureTile(
                entry: feature,
                onTap: () => _onFeatureTap(feature.action),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FinanceColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildReportPanel(),
                  _buildPromoBanner(),
                  _buildAdvancedToolsPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoTinyTag extends StatelessWidget {
  const _PromoTinyTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF7A6CE)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF2DC7C3)),
          SizedBox(width: 4),
          Text(
            'Quản Lý\nChi Tiêu',
            style: TextStyle(
              color: Color(0xFF2F2F37),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityReportCard extends StatelessWidget {
  const _UtilityReportCard({required this.data});

  final _UtilityReportCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: data.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.accent.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          if (data.hasUnreadDot)
            const Positioned(
              right: 0,
              top: 0,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Color(0xFFFF2D55),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 86,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.remove_red_eye_rounded,
                  color: data.accent,
                  size: 48,
                ),
              ),
              const Spacer(),
              Text(
                data.title,
                style: const TextStyle(
                  color: Color(0xFF3A3A42),
                  fontSize: 19 / 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                style: const TextStyle(
                  color: Color(0xFF2F2F37),
                  fontSize: 24 / 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UtilityFeatureTile extends StatelessWidget {
  const _UtilityFeatureTile({required this.entry, required this.onTap});

  final _UtilityFeatureEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8FA),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    entry.icon,
                    color: const Color(0xFF23C2C6),
                    size: 44,
                  ),
                ),
                if (entry.badgeText != null)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: entry.badgeColor ?? const Color(0xFFFF2D55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        entry.badgeText!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF505059),
                fontSize: 20 / 1.2,
                fontWeight: FontWeight.w500,
                height: 1.28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _monthLabel(DateTime month) {
  final now = DateTime.now();
  if (month.year == now.year && month.month == now.month) {
    return 'Tháng này';
  }
  return 'Tháng ${month.month}/${month.year}';
}

String _compactCurrency(double amount) {
  final normalized = Formatters.currency(
    amount,
  ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
  return '$normalizedđ';
}
