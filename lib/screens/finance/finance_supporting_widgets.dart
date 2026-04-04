part of 'finance_screen.dart';

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
    this.hasCustomBudget = false,
  });

  final String title;
  final double allocated;
  final double spent;
  final IconData icon;
  final Color accentColor;
  final bool isTotal;
  final TransactionType type;
  final bool hasCustomBudget;

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
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = info.remaining;
    final hasConfiguredBudget = info.allocated > 0;
    final overBudget = hasConfiguredBudget && info.isOverBudget;
    final remainingRatio = info.allocated <= 0
        ? 0.0
        : (remaining / info.allocated).clamp(0.0, 1.0).toDouble();
    final statusBg = !hasConfiguredBudget
        ? const Color(0xFFF1F2F5)
        : overBudget
        ? const Color(0xFFFFF1EA)
        : const Color(0xFFEAF8EF);
    final statusColor = !hasConfiguredBudget
        ? const Color(0xFF5E5E67)
        : overBudget
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
            border: Border.all(color: FinanceColors.border),
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
                    color: FinanceColors.textStrong,
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
                          !hasConfiguredBudget
                              ? const Color(0xFFE6E4EB)
                              : overBudget
                              ? const Color(0xFFE6E4EB)
                              : info.accentColor,
                        ),
                      ),
                    ),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: !hasConfiguredBudget
                            ? const Color(0xFFF2F1F6)
                            : overBudget
                            ? const Color(0xFFF2F1F6)
                            : const Color(0xFFF3FAFA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        info.icon,
                        color: !hasConfiguredBudget
                            ? const Color(0xFF9A9AA4)
                            : overBudget
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
                !hasConfiguredBudget
                    ? 'Chưa đặt'
                    : overBudget
                    ? 'Vượt'
                    : 'Còn lại',
                style: const TextStyle(fontSize: 18, color: Color(0xFF707079)),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 32,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _format(hasConfiguredBudget ? remaining.abs() : 0),
                    style: TextStyle(
                      fontSize: 42 / 2,
                      fontWeight: FontWeight.w900,
                      color: !hasConfiguredBudget
                          ? const Color(0xFF7B7B85)
                          : overBudget
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
                          !hasConfiguredBudget
                              ? Icons.pending_outlined
                              : overBudget
                              ? Icons.local_fire_department_rounded
                              : Icons.verified_user_rounded,
                          size: 18,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          !hasConfiguredBudget
                              ? 'Chưa đặt'
                              : overBudget
                              ? 'Đã vượt'
                              : 'Tốt',
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
            border: Border.all(color: FinanceColors.border),
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
