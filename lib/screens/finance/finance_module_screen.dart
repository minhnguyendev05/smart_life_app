import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_recurring_transaction.dart';
import '../../models/finance_transaction.dart';
import '../../providers/finance_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_toast.dart';
import 'finance_screen.dart';
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
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final selected = states.contains(MaterialState.selected);
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
                child: const Icon(Icons.repeat_rounded),
              ),
              selectedIcon: const Icon(Icons.repeat_rounded),
              label: 'GĐ định kỳ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded),
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

class _FinanceCalendarTab extends StatefulWidget {
  const _FinanceCalendarTab();

  @override
  State<_FinanceCalendarTab> createState() => _FinanceCalendarTabState();
}

class _FinanceCalendarTabState extends State<_FinanceCalendarTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final transactions = provider.filterTransactions(month: _month);
    final grouped = _groupByDay(transactions);

    return _FinanceTabContainer(
      title: 'Lịch giao dịch',
      subtitle: 'Theo dõi thu chi theo từng ngày trong tháng',
      children: [
        _MonthSwitcher(
          label: _monthLabel(_month),
          onPrev: () => _moveMonth(-1),
          onNext: () => _moveMonth(1),
        ),
        const SizedBox(height: 12),
        if (grouped.isEmpty)
          const _FinanceEmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'Chưa có giao dịch trong tháng này',
            subtitle: 'Hãy thêm giao dịch ở tab Tổng quan để hiển thị lịch.',
          )
        else
          ...grouped.entries.map(
            (entry) => _buildDayCard(entry.key, entry.value),
          ),
      ],
    );
  }

  Widget _buildDayCard(DateTime day, List<FinanceTransaction> items) {
    final income = items
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final expense = items
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: FinanceDecorations.surfaceCard(radius: FinanceRadius.md),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(
          _dayLabel(day),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF34343B),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Thu: ${_compactCurrency(income)}   •   Chi: ${_compactCurrency(expense)}',
            style: const TextStyle(
              color: Color(0xFF65656E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: items.map((tx) {
          final positive = tx.type == TransactionType.income;
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: positive
                        ? const Color(0xFFE8FFF7)
                        : const Color(0xFFFFF3EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    positive ? Icons.south_rounded : Icons.north_rounded,
                    size: 18,
                    color: positive
                        ? const Color(0xFF2CCF73)
                        : const Color(0xFFF6A93B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${tx.title} • ${tx.category}',
                    style: const TextStyle(
                      color: Color(0xFF3A3A42),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${positive ? '+' : '-'}${_compactCurrency(tx.amount)}',
                  style: TextStyle(
                    color: positive
                        ? const Color(0xFF2CCF73)
                        : const Color(0xFFF6A93B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
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
    });
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
                  _buildListItemTile(item, showMenu: false, showAmount: true),
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
                  onTap:
                      bucket == _RecurringItemBucket.manual &&
                          item.recurring != null
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

class _FinanceMoniTab extends StatelessWidget {
  const _FinanceMoniTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final monthTransactions = provider.filterTransactions(month: month);

    final monthIncome = monthTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final monthExpense = monthTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final balance = monthIncome - monthExpense;
    final savingRate = monthIncome <= 0 ? 0.0 : (balance / monthIncome * 100);

    final byCategory = provider.expenseByCategory(month: month);
    final topCategory = byCategory.entries.isEmpty
        ? null
        : (byCategory.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first;

    final tips = <String>[
      if (topCategory != null)
        'Danh mục chi lớn nhất tháng này là ${topCategory.key}. Hãy đặt trần chi riêng cho nhóm này.',
      if (provider.isOverBudget)
        'Bạn đang vượt ngân sách tháng. Nên hoãn các khoản mua sắm không cấp thiết trong 3-5 ngày tới.',
      if (savingRate >= 20)
        'Tỉ lệ tiết kiệm đang rất tốt (${savingRate.toStringAsFixed(0)}%). Bạn có thể trích quỹ dự phòng.',
      if (savingRate < 0)
        'Dòng tiền đang âm. Ưu tiên cắt giảm khoản có tần suất cao và giá trị nhỏ nhưng lặp lại.',
    ];

    return _FinanceTabContainer(
      title: 'Moni',
      subtitle: 'Trợ lý theo dõi xu hướng chi tiêu thông minh',
      children: [
        _InsightMetricCard(
          title: 'Thu nhập tháng',
          value: _compactCurrency(monthIncome),
          color: const Color(0xFF2CCF73),
          icon: Icons.south_rounded,
        ),
        _InsightMetricCard(
          title: 'Chi tiêu tháng',
          value: _compactCurrency(monthExpense),
          color: const Color(0xFFF6A93B),
          icon: Icons.north_rounded,
        ),
        _InsightMetricCard(
          title: 'Tỉ lệ tiết kiệm',
          value: '${savingRate.toStringAsFixed(0)}%',
          color: const Color(0xFF4B7BEC),
          icon: Icons.pie_chart_outline_rounded,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gợi ý nhanh',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF34343B),
                ),
              ),
              const SizedBox(height: 8),
              if (tips.isEmpty)
                const Text(
                  'Dữ liệu chưa đủ để phân tích sâu. Hãy thêm nhiều giao dịch hơn để nhận gợi ý tốt hơn.',
                  style: TextStyle(
                    color: Color(0xFF6B6B74),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ...tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: FinanceColors.accentSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              color: Color(0xFF3F3F47),
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
}

class _FinanceUtilitiesTab extends StatelessWidget {
  const _FinanceUtilitiesTab({required this.onOpenOverview});

  final VoidCallback onOpenOverview;

  @override
  Widget build(BuildContext context) {
    final monthlyBudget = context.watch<FinanceProvider>().monthlyBudget;

    return _FinanceTabContainer(
      title: 'Tiện ích tài chính',
      subtitle: 'Tác vụ nhanh cho quản lý ngân sách và dữ liệu',
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wallet_outlined,
                color: FinanceColors.accentSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ngân sách tháng hiện tại: ${_compactCurrency(monthlyBudget)}',
                  style: const TextStyle(
                    color: Color(0xFF3D3D45),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          childAspectRatio: 1.15,
          children: [
            _UtilityActionCard(
              icon: Icons.dashboard_customize_outlined,
              title: 'Mở Tổng quan',
              subtitle: 'Quay về tab chính của Finance',
              onTap: onOpenOverview,
            ),
            _UtilityActionCard(
              icon: Icons.tune_rounded,
              title: 'Đổi ngân sách',
              subtitle: 'Cập nhật hạn mức theo tháng',
              onTap: () => _showBudgetEditor(context),
            ),
            _UtilityActionCard(
              icon: Icons.file_download_outlined,
              title: 'Xuất dữ liệu',
              subtitle: 'CSV/PDF sẽ hỗ trợ sớm',
              onTap: () => _showHint(
                context,
                'Tính năng xuất dữ liệu sẽ có ở bản kế tiếp.',
              ),
            ),
            _UtilityActionCard(
              icon: Icons.notifications_active_outlined,
              title: 'Nhắc định kỳ',
              subtitle: 'Tạo nhắc giao dịch lặp lại',
              onTap: () => _showHint(
                context,
                'Tính năng nhắc định kỳ đang được phát triển.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showBudgetEditor(BuildContext context) async {
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
    if (!context.mounted) {
      return;
    }
    _showHint(context, 'Đã cập nhật ngân sách tháng.');
  }

  void _showHint(BuildContext context, String message) {
    showAppToast(context, message: message, type: AppToastType.info);
  }
}

class _FinanceTabContainer extends StatelessWidget {
  const _FinanceTabContainer({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FinanceColors.background,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
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
                        color: FinanceColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: FinanceColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Color(0xFF2F2F36),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6F6F78),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF34343B),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _InsightMetricCard extends StatelessWidget {
  const _InsightMetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6B6B74),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF34343B),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityActionCard extends StatelessWidget {
  const _UtilityActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FinanceColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBF6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: FinanceColors.accentSecondary),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF34343B),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF76767F),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceEmptyState extends StatelessWidget {
  const _FinanceEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF8A8A94)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF3A3A42),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF72727A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

String _dayLabel(DateTime day) {
  final dd = day.day.toString().padLeft(2, '0');
  final mm = day.month.toString().padLeft(2, '0');
  return '$dd/$mm/${day.year}';
}

String _compactCurrency(double amount) {
  final normalized = Formatters.currency(
    amount,
  ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
  return '$normalizedđ';
}
