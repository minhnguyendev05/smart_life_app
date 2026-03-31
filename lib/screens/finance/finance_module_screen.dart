import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance_transaction.dart';
import '../../providers/finance_provider.dart';
import '../../utils/formatters.dart';
import 'finance_screen.dart';

class FinanceModuleScreen extends StatefulWidget {
  const FinanceModuleScreen({super.key});

  @override
  State<FinanceModuleScreen> createState() => _FinanceModuleScreenState();
}

class _FinanceModuleScreenState extends State<FinanceModuleScreen> {
  static const Color _bg = Color(0xFFF4F2F8);
  static const Color _accentPink = Color(0xFFF63FA7);

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3EE)),
      ),
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

class _FinanceRecurringTab extends StatelessWidget {
  const _FinanceRecurringTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final recurring = _buildRecurringCandidates(provider.transactions);

    return _FinanceTabContainer(
      title: 'Giao dịch định kỳ',
      subtitle: 'Phát hiện khoản chi lặp lại để bạn quản lý chủ động hơn',
      children: [
        if (recurring.isEmpty)
          const _FinanceEmptyState(
            icon: Icons.repeat_rounded,
            title: 'Chưa phát hiện mẫu định kỳ',
            subtitle:
                'Khi một giao dịch lặp lại nhiều lần, hệ thống sẽ gợi ý ở đây.',
          )
        else
          ...recurring.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E3EE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBF6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.repeat_rounded,
                      color: Color(0xFFF63FA7),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF32323A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.category} • Khoảng ${item.everyDays} ngày/lần',
                          style: const TextStyle(
                            color: Color(0xFF6A6A72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dự kiến tiếp theo: ${_dayLabel(item.nextDue)}',
                          style: const TextStyle(
                            color: Color(0xFF7A7A82),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _compactCurrency(item.avgAmount),
                    style: const TextStyle(
                      color: Color(0xFF3A3A42),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<_RecurringCandidate> _buildRecurringCandidates(
    List<FinanceTransaction> all,
  ) {
    final grouped = <String, List<FinanceTransaction>>{};
    for (final tx in all) {
      if (tx.type != TransactionType.expense) continue;
      final key = '${tx.title}|${tx.category}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final recurring = <_RecurringCandidate>[];

    for (final entry in grouped.entries) {
      final items = entry.value
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (items.length < 2) continue;

      final intervals = <int>[];
      for (var i = 1; i < items.length; i++) {
        intervals.add(
          items[i].createdAt.difference(items[i - 1].createdAt).inDays.abs(),
        );
      }
      if (intervals.isEmpty) continue;

      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      if (avgInterval < 3 || avgInterval > 70) continue;

      final avgAmount =
          items.fold(0.0, (sum, tx) => sum + tx.amount) / items.length;
      final latest = items.last;
      recurring.add(
        _RecurringCandidate(
          title: latest.title,
          category: latest.category,
          avgAmount: avgAmount,
          everyDays: avgInterval.round(),
          nextDue: latest.createdAt.add(Duration(days: avgInterval.round())),
        ),
      );
    }

    recurring.sort((a, b) => a.nextDue.compareTo(b.nextDue));
    return recurring.take(8).toList();
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
            border: Border.all(color: const Color(0xFFE8E3EE)),
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
                            color: Color(0xFFF63FA7),
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
            border: Border.all(color: const Color(0xFFE8E3EE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wallet_outlined, color: Color(0xFFF63FA7)),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      color: const Color(0xFFF4F2F8),
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE8E3EE)),
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
        border: Border.all(color: const Color(0xFFE8E3EE)),
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
        border: Border.all(color: const Color(0xFFE8E3EE)),
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
            border: Border.all(color: const Color(0xFFE8E3EE)),
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
                child: Icon(icon, color: const Color(0xFFF63FA7)),
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
        border: Border.all(color: const Color(0xFFE8E3EE)),
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

class _RecurringCandidate {
  const _RecurringCandidate({
    required this.title,
    required this.category,
    required this.avgAmount,
    required this.everyDays,
    required this.nextDue,
  });

  final String title;
  final String category;
  final double avgAmount;
  final int everyDays;
  final DateTime nextDue;
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
  )
      .replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '')
      .trim();
  return '$normalizedđ';
}
