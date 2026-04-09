import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/finance_category.dart';
import '../../models/finance_transaction.dart';
import '../../utils/formatters.dart';
import 'finance_styles.dart';

class FinanceSectionHeader extends StatelessWidget {
  const FinanceSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.leadingIcon,
    this.leadingColor = FinanceColors.accentSecondary,
    this.titleStyle = const TextStyle(
      fontSize: 42 / 1.5,
      fontWeight: FontWeight.w900,
      color: FinanceColors.textStrong,
    ),
  });

  final String title;
  final Widget? trailing;
  final IconData? leadingIcon;
  final Color leadingColor;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: FinanceDecorations.iconBadge(
              color: leadingColor,
              alpha: 0.18,
            ),
            child: Icon(leadingIcon, size: 18, color: leadingColor),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(title, style: titleStyle)),
        ?trailing,
      ],
    );
  }
}

class FinanceGradientAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const FinanceGradientAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onHome,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onHome;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildCircleIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? scheme.surfaceContainerHighest : Colors.white)
            .withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? scheme.outlineVariant.withValues(alpha: 0.6)
              : FinanceColors.borderSoft,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: isDark ? scheme.onSurface : FinanceColors.textStrong,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final navigator = Navigator.of(context);
    final homeAction =
        onHome ?? () => navigator.popUntil((route) => route.isFirst);
    final appBarBackground = isDark ? scheme.surface : FinanceColors.appBarTint;
    final gradientColors = isDark
        ? <Color>[
            scheme.surfaceContainerHighest.withValues(alpha: 0.72),
            scheme.surface,
            scheme.surface,
          ]
        : const <Color>[
            FinanceColors.appBarGradientTop,
            FinanceColors.appBarTint,
            FinanceColors.appBarGradientBottom,
          ];

    return AppBar(
      backgroundColor: appBarBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 58,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
        child: _buildCircleIconButton(
          context: context,
          icon: Icons.arrow_back_rounded,
          onPressed: onBack ?? () => navigator.maybePop(),
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
      ),
      title: SizedBox(
        height: 34,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: const TextStyle(
                color: FinanceColors.textStrong,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
          child: _buildCircleIconButton(
            context: context,
            icon: Icons.home_outlined,
            onPressed: homeAction,
          ),
        ),
      ],
    );
  }
}

class FinanceSheetScaffold extends StatelessWidget {
  const FinanceSheetScaffold({
    super.key,
    required this.child,
    this.heightFactor,
    this.backgroundColor = FinanceColors.sheetBackground,
    this.topRadius = FinanceRadius.sheetTop,
    this.showHandle = true,
    this.wrapSafeArea = true,
    this.handlePadding = const EdgeInsets.only(top: 8),
  });

  final Widget child;
  final double? heightFactor;
  final Color backgroundColor;
  final double topRadius;
  final bool showHandle;
  final bool wrapSafeArea;
  final EdgeInsetsGeometry handlePadding;

  @override
  Widget build(BuildContext context) {
    final sheet = Container(
      height: heightFactor == null
          ? null
          : MediaQuery.of(context).size.height * heightFactor!,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      child: Column(
        mainAxisSize: heightFactor == null
            ? MainAxisSize.min
            : MainAxisSize.max,
        children: [
          if (showHandle)
            Padding(
              padding: handlePadding,
              child: Container(
                width: 52,
                height: 6,
                decoration: BoxDecoration(
                  color: FinanceColors.sheetDragHandle,
                  borderRadius: BorderRadius.circular(FinanceRadius.pill),
                ),
              ),
            ),
          if (heightFactor == null) child else Expanded(child: child),
        ],
      ),
    );

    if (!wrapSafeArea) {
      return sheet;
    }
    return SafeArea(top: false, child: sheet);
  }
}

class FinanceSurfaceCard extends StatelessWidget {
  const FinanceSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = FinanceRadius.lg,
    this.borderWidth = 1,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double borderWidth;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? scheme.surface : Colors.white),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              borderColor ??
              (isDark
                  ? scheme.outlineVariant.withValues(alpha: 0.6)
                  : FinanceColors.border),
          width: borderWidth,
        ),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}

class FinanceOptionTile extends StatelessWidget {
  const FinanceOptionTile({
    super.key,
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = EdgeInsets.zero,
    this.backgroundColor = FinanceColors.surface,
    this.selectedBackgroundColor = const Color(0xFFFFF1F8),
    this.borderColor = FinanceColors.borderSoft,
    this.selectedBorderColor = FinanceColors.accentPrimary,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(FinanceRadius.sm),
    ),
    this.borderWidth = 1,
    this.selectedBorderWidth = 1.5,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color borderColor;
  final Color selectedBorderColor;
  final BorderRadius borderRadius;
  final double borderWidth;
  final double selectedBorderWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? selectedBackgroundColor : backgroundColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: selected ? selectedBorderColor : borderColor,
              width: selected ? selectedBorderWidth : borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class FinanceClassifyHelper {
  FinanceClassifyHelper._();

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

  static bool isPendingClassification(FinanceTransaction transaction) {
    if (!transaction.includedInReports) {
      return false;
    }
    final normalized = transaction.category.trim().toLowerCase();
    return _uncategorizedAliases.contains(normalized);
  }

  static List<FinanceTransaction> pendingTransactions(
    Iterable<FinanceTransaction> source,
  ) {
    final pending = source.where(isPendingClassification).toList();
    pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pending;
  }

  static int pendingCount(Iterable<FinanceTransaction> source) {
    var count = 0;
    for (final transaction in source) {
      if (isPendingClassification(transaction)) {
        count++;
      }
    }
    return count;
  }
}

class FinanceCategoryChoiceTile extends StatelessWidget {
  const FinanceCategoryChoiceTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
    this.width,
    this.height,
    this.iconSize = 20,
    this.labelFontSize = 13,
    this.labelHeight = 18,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(FinanceRadius.sm),
    ),
    this.padding = const EdgeInsets.fromLTRB(6, 8, 6, 8),
    this.backgroundColor = FinanceColors.surface,
    this.selectedBackgroundColor = const Color(0xFFFFF1F8),
    this.unselectedBorderColor = const Color(0xFFE1DCEA),
    this.selectedBorderColor = FinanceColors.accentPrimary,
    this.borderWidth = 1.1,
    this.selectedBorderWidth = 1.8,
    this.showSelectedIconBadge = false,
    this.selectedIconBadgeColor = const Color(0xFFF2F1F5),
    this.selectedIconBadgeSize = 40,
    this.unselectedIconColor,
    this.selectedIconColor,
    this.unselectedLabelColor,
    this.unselectedLabelWeight,
    this.labelMaxLines = 1,
    this.iconToLabelSpacing = 6,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;
  final double? width;
  final double? height;
  final double iconSize;
  final double labelFontSize;
  final double labelHeight;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color unselectedBorderColor;
  final Color selectedBorderColor;
  final double borderWidth;
  final double selectedBorderWidth;
  final bool showSelectedIconBadge;
  final Color selectedIconBadgeColor;
  final double selectedIconBadgeSize;
  final Color? unselectedIconColor;
  final Color? selectedIconColor;
  final Color? unselectedLabelColor;
  final FontWeight? unselectedLabelWeight;
  final int labelMaxLines;
  final double iconToLabelSpacing;

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = enabled && selected;
    final defaultUnselectedColor = FinanceColors.textStrong;
    final iconColor = !enabled
        ? FinanceColors.textMuted
        : effectiveSelected
        ? (selectedIconColor ?? unselectedIconColor ?? defaultUnselectedColor)
        : (unselectedIconColor ?? defaultUnselectedColor);
    final labelColor = !enabled
        ? FinanceColors.textMuted
        : effectiveSelected
        ? FinanceColors.accentPrimary
        : (unselectedLabelColor ?? defaultUnselectedColor);

    Widget iconWidget = Icon(icon, color: iconColor, size: iconSize);
    if (showSelectedIconBadge) {
      iconWidget = Container(
        width: selectedIconBadgeSize,
        height: selectedIconBadgeSize,
        decoration: BoxDecoration(
          color: effectiveSelected
              ? selectedIconBadgeColor
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      );
    }

    final tile = FinanceOptionTile(
      onTap: enabled ? onTap : null,
      selected: effectiveSelected,
      padding: padding,
      backgroundColor: backgroundColor,
      selectedBackgroundColor: selectedBackgroundColor,
      borderColor: unselectedBorderColor,
      selectedBorderColor: selectedBorderColor,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      selectedBorderWidth: selectedBorderWidth,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            SizedBox(height: iconToLabelSpacing),
            SizedBox(
              width: double.infinity,
              height: labelHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: labelMaxLines,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: effectiveSelected
                        ? FontWeight.w800
                        : (unselectedLabelWeight ?? FontWeight.w600),
                    fontSize: labelFontSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (width == null && height == null) {
      return tile;
    }

    return SizedBox(width: width, height: height, child: tile);
  }
}

class FinanceCategoryGroupCard extends StatelessWidget {
  const FinanceCategoryGroupCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.categories,
    required this.selectedCategory,
    required this.iconForCategory,
    required this.onSelect,
    this.iconColorForCategory,
    this.enabled = true,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.radius = FinanceRadius.md,
    this.gridCrossAxisCount = 4,
    this.gridCrossAxisSpacing = 8,
    this.gridMainAxisSpacing = 10,
    this.gridChildAspectRatio = 0.82,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> categories;
  final String? selectedCategory;
  final IconData Function(String category) iconForCategory;
  final Color Function(String category)? iconColorForCategory;
  final ValueChanged<String> onSelect;
  final bool enabled;
  final EdgeInsetsGeometry margin;
  final double radius;
  final int gridCrossAxisCount;
  final double gridCrossAxisSpacing;
  final double gridMainAxisSpacing;
  final double gridChildAspectRatio;

  bool _isSelectedCategory(String category) {
    final current = selectedCategory;
    if (current == null) {
      return false;
    }
    return category.trim().toLowerCase() == current.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: FinanceColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 21 / 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            itemCount: categories.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCrossAxisCount,
              crossAxisSpacing: gridCrossAxisSpacing,
              mainAxisSpacing: gridMainAxisSpacing,
              childAspectRatio: gridChildAspectRatio,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final iconColor = iconColorForCategory?.call(category);
              return FinanceCategoryChoiceTile(
                label: category,
                icon: iconForCategory(category),
                selected: _isSelectedCategory(category),
                enabled: enabled,
                iconSize: 34,
                labelFontSize: 14,
                labelHeight: 34,
                labelMaxLines: 2,
                iconToLabelSpacing: 8,
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                backgroundColor: Colors.transparent,
                selectedBackgroundColor: const Color(0xFFFFEEF8),
                unselectedBorderColor: Colors.transparent,
                selectedBorderColor: FinanceColors.accentPrimary,
                borderWidth: 1,
                selectedBorderWidth: 2,
                showSelectedIconBadge: false,
                unselectedIconColor: iconColor,
                selectedIconColor: iconColor,
                onTap: () => onSelect(category),
              );
            },
          ),
        ],
      ),
    );
  }
}

class FinanceTransactionVisual {
  const FinanceTransactionVisual({
    required this.leadingIcon,
    required this.leadingColor,
    required this.categoryIcon,
    required this.categoryColor,
  });

  final IconData leadingIcon;
  final Color leadingColor;
  final IconData categoryIcon;
  final Color categoryColor;
}

class FinanceTransactionVisualResolver {
  FinanceTransactionVisualResolver._();

  static FinanceCategory? _findCustomCategory({
    required String category,
    required TransactionType type,
    required List<FinanceCategory> customCategories,
  }) {
    final normalizedName = category.trim().toLowerCase();
    if (normalizedName.isEmpty) {
      return null;
    }

    for (final item in customCategories) {
      if (item.type != type) {
        continue;
      }
      if (item.name.trim().toLowerCase() == normalizedName) {
        return item;
      }
    }
    return null;
  }

  static bool _containsAny(String source, List<String> fragments) {
    for (final fragment in fragments) {
      if (source.contains(fragment)) {
        return true;
      }
    }
    return false;
  }

  static FinanceCategoryVisual resolveCategoryVisual({
    required String category,
    required TransactionType type,
    List<FinanceCategory> customCategories = const <FinanceCategory>[],
    IconData? fallbackIcon,
    Color? fallbackColor,
  }) {
    final custom = _findCustomCategory(
      category: category,
      type: type,
      customCategories: customCategories,
    );
    if (custom != null) {
      return FinanceCategoryVisual(icon: custom.icon, color: custom.color);
    }

    final isExpense = type == TransactionType.expense;
    return FinanceCategoryVisual(
      icon: FinanceCategoryVisualCatalog.iconFor(
        category,
        isExpense: isExpense,
        fallbackIcon:
            fallbackIcon ??
            (isExpense
                ? Icons.account_balance_wallet_outlined
                : Icons.payments_outlined),
      ),
      color: FinanceCategoryVisualCatalog.colorFor(
        category,
        isExpense: isExpense,
        fallbackColor:
            fallbackColor ??
            (isExpense ? const Color(0xFF47C7A8) : const Color(0xFF58A5FF)),
      ),
    );
  }

  static FinanceTransactionVisual resolveTransaction({
    required FinanceTransaction transaction,
    List<FinanceCategory> customCategories = const <FinanceCategory>[],
  }) {
    final categoryVisual = resolveCategoryVisual(
      category: transaction.category,
      type: transaction.type,
      customCategories: customCategories,
    );

    var leadingIcon = categoryVisual.icon;
    var leadingColor = categoryVisual.color;

    final normalizedText = '${transaction.title} ${transaction.note ?? ''}'
        .toLowerCase();
    if (_containsAny(normalizedText, [
      'viettel',
      'điện thoại',
      'dien thoai',
      'nạp',
      'nap',
      'sim',
      'data',
    ])) {
      leadingIcon = Icons.smartphone_rounded;
      leadingColor = const Color(0xFF2B8EF7);
    } else if (_containsAny(normalizedText, [
      'chuyển khoản',
      'chuyen khoan',
      'chuyển',
      'chuyen',
      'ngân hàng',
      'ngan hang',
      'bank',
    ])) {
      leadingIcon = Icons.send_to_mobile_rounded;
      leadingColor = const Color(0xFFFF6576);
    } else if (_containsAny(normalizedText, [
      'thần tài',
      'than tai',
      'tiết kiệm',
      'tiet kiem',
    ])) {
      leadingIcon = Icons.savings_rounded;
      leadingColor = const Color(0xFFF98900);
    }

    return FinanceTransactionVisual(
      leadingIcon: leadingIcon,
      leadingColor: leadingColor,
      categoryIcon: categoryVisual.icon,
      categoryColor: categoryVisual.color,
    );
  }
}

class FinanceFundingSourceOption {
  const FinanceFundingSourceOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
}

class FinanceFundingSourceCatalog {
  FinanceFundingSourceCatalog._();

  static const List<FinanceFundingSourceOption> options = [
    FinanceFundingSourceOption(
      id: FinanceTransaction.smartLifeFundingSourceId,
      label: 'Ví SmartLife',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Color(0xFFFFFFFF),
      iconBackground: Color(0xFFB00078),
    ),
    FinanceFundingSourceOption(
      id: 'than_tai',
      label: 'Túi Thần Tài',
      icon: Icons.savings_rounded,
      iconColor: Color(0xFFFFA300),
      iconBackground: Color(0xFFFFF4D6),
    ),
    FinanceFundingSourceOption(
      id: 'mbbank',
      label: 'MBBank',
      icon: Icons.account_balance_rounded,
      iconColor: Color(0xFF0057B8),
      iconBackground: Color(0xFFEAF2FF),
    ),
    FinanceFundingSourceOption(
      id: 'group_ae',
      label: 'Quỹ Ae mình cứ thế thôi',
      icon: Icons.groups_rounded,
      iconColor: FinanceColors.accentPrimary,
      iconBackground: Color(0xFFFFEDF7),
    ),
    FinanceFundingSourceOption(
      id: 'group_dau',
      label: 'Quỹ Đấu',
      icon: Icons.groups_rounded,
      iconColor: FinanceColors.accentPrimary,
      iconBackground: Color(0xFFFFEDF7),
    ),
    FinanceFundingSourceOption(
      id: 'reward_fund',
      label: 'Quỹ Tiền thưởng',
      icon: Icons.groups_rounded,
      iconColor: FinanceColors.accentPrimary,
      iconBackground: Color(0xFFFFEDF7),
    ),
    FinanceFundingSourceOption(
      id: 'group_hi',
      label: 'Quỹ Hi',
      icon: Icons.groups_rounded,
      iconColor: FinanceColors.accentPrimary,
      iconBackground: Color(0xFFFFEDF7),
    ),
    FinanceFundingSourceOption(
      id: FinanceTransaction.defaultFundingSourceId,
      label: FinanceTransaction.defaultFundingSourceLabel,
      icon: Icons.account_balance_wallet_outlined,
      iconColor: Color(0xFF2DC7C3),
      iconBackground: Color(0xFFEAF7F6),
    ),
    FinanceFundingSourceOption(
      id: 'agribank',
      label: 'Agribank',
      icon: Icons.account_balance_outlined,
      iconColor: Color(0xFF08764C),
      iconBackground: Color(0xFFE7F8F0),
    ),
  ];

  static FinanceFundingSourceOption? findById(String sourceId) {
    final normalized = FinanceTransaction.normalizeFundingSourceId(sourceId);
    for (final option in options) {
      if (option.id == normalized) {
        return option;
      }
    }
    return null;
  }
}

class FinanceFundingSourceVisual {
  const FinanceFundingSourceVisual({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
}

class FinanceFundingSourceVisualResolver {
  FinanceFundingSourceVisualResolver._();

  static FinanceFundingSourceVisual _toVisual(
    FinanceFundingSourceOption option, {
    String? labelOverride,
  }) {
    return FinanceFundingSourceVisual(
      label: labelOverride ?? option.label,
      icon: option.icon,
      iconColor: option.iconColor,
      iconBackground: option.iconBackground,
    );
  }

  static FinanceFundingSourceVisual resolve(
    String sourceId, {
    String? fallbackLabel,
  }) {
    final normalized = FinanceTransaction.normalizeFundingSourceId(sourceId);

    final known = FinanceFundingSourceCatalog.findById(normalized);
    if (known != null) {
      return _toVisual(known);
    }
    if (normalized.startsWith('group_') || normalized == 'reward_fund') {
      return _toVisual(
        const FinanceFundingSourceOption(
          id: 'group_unknown',
          label: 'Quỹ nhóm',
          icon: Icons.groups_rounded,
          iconColor: FinanceColors.accentPrimary,
          iconBackground: Color(0xFFFFEDF7),
        ),
        labelOverride: fallbackLabel?.trim().isNotEmpty == true
            ? fallbackLabel!.trim()
            : 'Quỹ nhóm',
      );
    }

    return _toVisual(
      const FinanceFundingSourceOption(
        id: FinanceTransaction.defaultFundingSourceId,
        label: FinanceTransaction.defaultFundingSourceLabel,
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Color(0xFF2DC7C3),
        iconBackground: Color(0xFFEAF7F6),
      ),
      labelOverride: (fallbackLabel == null || fallbackLabel.trim().isEmpty)
          ? FinanceTransaction.defaultFundingSourceLabel
          : fallbackLabel.trim(),
    );
  }
}

class FinanceCategorySelectChip extends StatelessWidget {
  const FinanceCategorySelectChip({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.borderColor,
    this.onTap,
    this.maxWidth,
    this.maxVisualWidth = 220,
    this.minTextModeWidth = 82,
    this.showChevron = true,
    this.backgroundColor = Colors.white,
    this.labelColor = const Color(0xFF3B3B43),
    this.labelFontSize = 18 / 1.2,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double? maxWidth;
  final double maxVisualWidth;
  final double minTextModeWidth;
  final bool showChevron;
  final Color backgroundColor;
  final Color labelColor;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    const horizontalPadding = 12.0;
    const compactHorizontalPadding = 10.0;
    const iconSize = 22.0;
    const iconGap = 6.0;
    const arrowGap = 2.0;
    const arrowSize = 22.0;
    const compactArrowGap = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        var available = maxWidth;
        if (available == null || !available.isFinite || available <= 0) {
          final fromConstraints = constraints.maxWidth;
          available = fromConstraints.isFinite
              ? fromConstraints
              : maxVisualWidth;
        }

        final allowedMaxWidth = available < maxVisualWidth
            ? available
            : maxVisualWidth;
        final showText = allowedMaxWidth >= minTextModeWidth;
        final compactWidth =
            (compactHorizontalPadding * 2) +
            iconSize +
            (showChevron ? compactArrowGap + arrowSize : 0);
        final resolvedWidth = showText
            ? allowedMaxWidth
            : compactWidth.clamp(36.0, allowedMaxWidth).toDouble();

        final border = borderColor ?? iconColor.withValues(alpha: 0.72);

        final chipContent = Container(
          padding: EdgeInsets.fromLTRB(
            showText ? horizontalPadding : compactHorizontalPadding,
            8,
            showText ? horizontalPadding : compactHorizontalPadding,
            8,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: iconColor, size: iconSize),
              if (showText) ...[
                const SizedBox(width: iconGap),
                Expanded(
                  child: SizedBox(
                    height: 20,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: labelColor,
                          fontWeight: FontWeight.w700,
                          fontSize: labelFontSize,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showChevron) const SizedBox(width: arrowGap),
              ] else if (showChevron) ...[
                const SizedBox(width: compactArrowGap),
              ],
              if (showChevron)
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF6D6D76),
                  size: arrowSize,
                ),
            ],
          ),
        );

        final wrapped = SizedBox(width: resolvedWidth, child: chipContent);
        if (onTap == null) {
          return wrapped;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: wrapped,
          ),
        );
      },
    );
  }
}

class FinanceLedgerTransactionRow extends StatelessWidget {
  const FinanceLedgerTransactionRow({
    super.key,
    required this.title,
    required this.category,
    required this.amountText,
    required this.amountColor,
    required this.leadingIcon,
    required this.leadingIconColor,
    required this.categoryIcon,
    required this.categoryIconColor,
    this.leadingIconSize = 36,
    this.leadingSize = 64,
    this.showCategoryChevron = true,
    this.showBottomDivider = false,
    this.onCategoryTap,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
  });

  final String title;
  final String category;
  final String amountText;
  final Color amountColor;
  final IconData leadingIcon;
  final Color leadingIconColor;
  final IconData categoryIcon;
  final Color categoryIconColor;
  final double leadingIconSize;
  final double leadingSize;
  final bool showCategoryChevron;
  final bool showBottomDivider;
  final VoidCallback? onCategoryTap;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final isWide = constraints.maxWidth >= 430;
        final amountSlotWidth = isNarrow ? 80.0 : 96.0;
        final chipTargetWidth = isNarrow ? 122.0 : (isWide ? 176.0 : 154.0);

        return Container(
          padding: padding,
          decoration: BoxDecoration(
            border: showBottomDivider
                ? const Border(
                    bottom: BorderSide(color: Color(0xFFE7E5EC), width: 1),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: leadingSize,
                height: leadingSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2DFE8)),
                ),
                child: Icon(
                  leadingIcon,
                  color: leadingIconColor,
                  size: leadingIconSize,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2F2F37),
                        fontWeight: FontWeight.w800,
                        fontSize: 24 / 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, innerConstraints) {
                        final chipMaxWidth =
                            innerConstraints.maxWidth < chipTargetWidth
                            ? innerConstraints.maxWidth
                            : chipTargetWidth;
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FinanceCategorySelectChip(
                            label: category,
                            icon: categoryIcon,
                            iconColor: categoryIconColor,
                            borderColor: categoryIconColor.withValues(
                              alpha: 0.72,
                            ),
                            showChevron: showCategoryChevron,
                            onTap: onCategoryTap,
                            maxWidth: chipMaxWidth,
                            maxVisualWidth: 220,
                            minTextModeWidth: 82,
                            labelColor: const Color(0xFF74737C),
                            labelFontSize: 13,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: amountSlotWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 26,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        amountText,
                        style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 24 / 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class FinanceTransactionDetailRow extends StatelessWidget {
  const FinanceTransactionDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.hasDivider = true,
  });

  final String label;
  final Widget value;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark
        ? scheme.onSurfaceVariant
        : const Color(0xFF707079);
    final dividerColor = isDark
        ? scheme.outlineVariant.withValues(alpha: 0.6)
        : const Color(0xFFE4E3EA);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(child: value),
            ],
          ),
        ),
        if (hasDivider) Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }
}

class FinanceTransactionDetailActionRow extends StatelessWidget {
  const FinanceTransactionDetailActionRow({
    super.key,
    required this.onDelete,
    required this.onEdit,
    this.deleteActionLabel = 'Xoá',
    this.editActionLabel = 'Chỉnh sửa',
  });

  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final String deleteActionLabel;
  final String editActionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final actionColor = isDark ? scheme.onSurface : const Color(0xFF2F2F37);
    final dividerColor = isDark
        ? scheme.outlineVariant.withValues(alpha: 0.6)
        : const Color(0xFFE1DFE7);

    return FinanceSurfaceCard(
      radius: 20,
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, color: actionColor),
              label: Text(
                deleteActionLabel,
                style: TextStyle(
                  color: actionColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20 / 1.2,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: VerticalDivider(color: dividerColor, thickness: 1),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: actionColor),
              label: Text(
                editActionLabel,
                style: TextStyle(
                  color: actionColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20 / 1.2,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(20),
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

class FinanceTransactionDetailScreen extends StatelessWidget {
  const FinanceTransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.leadingIcon,
    required this.leadingColor,
    required this.categoryIcon,
    required this.categoryColor,
    this.hideAmount = false,
    this.onDelete,
    this.onEdit,
    this.deleteActionLabel = 'Xoá',
    this.editActionLabel = 'Chỉnh sửa',
  });

  final FinanceTransaction transaction;
  final IconData leadingIcon;
  final Color leadingColor;
  final IconData categoryIcon;
  final Color categoryColor;
  final bool hideAmount;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onEdit;
  final String deleteActionLabel;
  final String editActionLabel;

  String _money(double value) {
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  String _dateTime(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = isDark ? scheme.surface : FinanceColors.background;
    final cardBackground = isDark ? scheme.surface : Colors.white;
    final primaryTextColor = isDark
        ? scheme.onSurface
        : const Color(0xFF2F2F37);
    final secondaryTextColor = isDark
        ? scheme.onSurfaceVariant
        : const Color(0xFF6B6B74);
    final titlePanelColor = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : const Color(0xFFF3F3F6);
    final titlePanelBorderColor = isDark
        ? scheme.outlineVariant.withValues(alpha: 0.5)
        : const Color(0xFFE7E5EC);
    final valueTextStyle = TextStyle(
      color: primaryTextColor,
      fontWeight: FontWeight.w800,
      fontSize: 20 / 1.2,
    );

    final isIncome = transaction.type == TransactionType.income;
    final amountText = hideAmount
        ? '******'
        : '${isIncome ? '+' : '-'}${_money(transaction.amount)}';
    final note = transaction.note?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final fundingVisual = FinanceFundingSourceVisualResolver.resolve(
      transaction.fundingSourceId,
      fallbackLabel: transaction.fundingSourceLabel,
    );
    final resolvedCategoryIcon = transaction.categoryIcon ?? categoryIcon;
    final resolvedCategoryColor =
        transaction.categoryIconColor ?? categoryColor;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: const FinanceGradientAppBar(title: 'Chi tiết giao dịch'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              FinanceSurfaceCard(
                margin: const EdgeInsets.only(top: 42),
                padding: const EdgeInsets.fromLTRB(16, 54, 16, 16),
                radius: 20,
                child: Column(
                  children: [
                    Text(
                      isIncome ? 'Thu nhập' : 'Chi tiêu',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 22 / 1.15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      amountText,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 30 / 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: titlePanelColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: titlePanelBorderColor),
                      ),
                      child: Text(
                        transaction.title.trim().isEmpty
                            ? '-'
                            : transaction.title.trim(),
                        style: TextStyle(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FinanceTransactionDetailRow(
                      label: 'Nguồn tiền',
                      value: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: fundingVisual.iconBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              fundingVisual.icon,
                              size: 20,
                              color: fundingVisual.iconColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              fundingVisual.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: valueTextStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FinanceTransactionDetailRow(
                      label: 'Thời gian',
                      value: Text(
                        _dateTime(transaction.createdAt),
                        style: valueTextStyle,
                      ),
                    ),
                    FinanceTransactionDetailRow(
                      label: 'Danh mục',
                      value: Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                        decoration: BoxDecoration(
                          color: resolvedCategoryColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: cardBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                resolvedCategoryIcon,
                                color: resolvedCategoryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                transaction.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: valueTextStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    FinanceTransactionDetailRow(
                      label: 'Báo cáo',
                      value: Text(
                        transaction.includedInReports
                            ? 'Có tính vào báo cáo'
                            : 'Không tính vào báo cáo',
                        textAlign: TextAlign.right,
                        style: valueTextStyle,
                      ),
                      hasDivider: hasNote,
                    ),
                    if (hasNote)
                      FinanceTransactionDetailRow(
                        label: 'Ghi chú',
                        value: Text(
                          note,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        hasDivider: false,
                      ),
                    const SizedBox(height: 14),
                    FinanceTransactionDetailActionRow(
                      onDelete: onDelete == null
                          ? null
                          : () => onDelete!.call(),
                      onEdit: onEdit == null ? null : () => onEdit!.call(),
                      deleteActionLabel: deleteActionLabel,
                      editActionLabel: editActionLabel,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: leadingColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(color: cardBackground, width: 6),
                      boxShadow: [
                        BoxShadow(
                          color: leadingColor.withValues(alpha: 0.22),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: leadingColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(leadingIcon, color: Colors.white, size: 24),
                      ),
                    ),
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

class FinancePrimaryActionButton extends StatelessWidget {
  const FinancePrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 54,
    this.expand = true,
    this.backgroundColor = FinanceColors.accentPrimary,
    this.disabledBackgroundColor = const Color(0xFFE2E0E8),
    this.foregroundColor = Colors.white,
    this.disabledForegroundColor = const Color(0xFFAFAFB7),
    this.textStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    this.borderRadius = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final bool expand;
  final Color backgroundColor;
  final Color disabledBackgroundColor;
  final Color foregroundColor;
  final Color disabledForegroundColor;
  final TextStyle textStyle;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        disabledBackgroundColor: disabledBackgroundColor,
        foregroundColor: foregroundColor,
        disabledForegroundColor: disabledForegroundColor,
        textStyle: textStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(label),
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: button,
    );
  }
}

class FinanceOutlineActionButton extends StatelessWidget {
  const FinanceOutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconSize = 28,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    this.borderRadius = 14,
    this.sideColor = FinanceColors.accentPrimary,
    this.foregroundColor = FinanceColors.accentPrimary,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.textStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color sideColor;
  final Color foregroundColor;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      side: BorderSide(color: sideColor),
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding,
      textStyle: textStyle,
    );

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: iconSize),
        label: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}

class FinanceCreateCategoryButton extends StatelessWidget {
  const FinanceCreateCategoryButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FinanceOutlineActionButton(
      label: 'Tạo mới',
      onPressed: onPressed,
      icon: Icons.add_circle_outline,
      iconSize: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      borderRadius: 18,
      sideColor: const Color(0xFFE2DFE8),
      foregroundColor: FinanceColors.textStrong,
      backgroundColor: Colors.white,
      disabledBackgroundColor: Colors.white,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: FinanceColors.textStrong,
      ),
    );
  }
}

class FinanceBottomBarSurface extends StatelessWidget {
  const FinanceBottomBarSurface({
    super.key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.topBorderColor,
  });

  final Widget child;
  final Color backgroundColor;
  final Color? topBorderColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Container(
        decoration: topBorderColor == null
            ? null
            : BoxDecoration(
                border: Border(top: BorderSide(color: topBorderColor!)),
              ),
        child: child,
      ),
    );
  }
}

class FinanceMoneySuggestionChips extends StatelessWidget {
  const FinanceMoneySuggestionChips({
    super.key,
    required this.onSelected,
    this.suggestions = const [100000, 1000000, 10000000],
    this.topPadding = 10,
    this.expanded = false,
  });

  final ValueChanged<double> onSelected;
  final List<double> suggestions;
  final double topPadding;
  final bool expanded;

  String _money(double value) {
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  @override
  Widget build(BuildContext context) {
    final tiles = suggestions.map((amount) {
      return SizedBox(
        height: 46,
        child: FinanceOptionTile(
          onTap: () => onSelected(amount),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          borderRadius: BorderRadius.circular(999),
          borderColor: const Color(0xFFE0DFE6),
          backgroundColor: const Color(0xFFF2F2F5),
          selectedBackgroundColor: const Color(0xFFF2F2F5),
          selectedBorderColor: const Color(0xFFE0DFE6),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _money(amount),
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF383840),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();

    final child = expanded
        ? Row(
            children: List.generate(tiles.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == tiles.length - 1 ? 0 : 8,
                  ),
                  child: tiles[index],
                ),
              );
            }),
          )
        : Wrap(spacing: 10, runSpacing: 8, children: tiles);

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: child,
    );
  }
}

class FinanceCurvedDualTabBar extends StatelessWidget {
  const FinanceCurvedDualTabBar({
    super.key,
    this.leftIcon,
    required this.leftLabel,
    this.rightIcon,
    required this.rightLabel,
    required this.selectedIndex,
    required this.onChanged,
    this.tabHeight = 50,
  }) : assert(selectedIndex == 0 || selectedIndex == 1);

  final IconData? leftIcon;
  final String leftLabel;
  final IconData? rightIcon;
  final String rightLabel;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double tabHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FinanceColors.borderSoft),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: selectedIndex == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: tabWidth,
                  height: tabHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _FinancePillTabItem(
                      icon: leftIcon,
                      label: leftLabel,
                      active: selectedIndex == 0,
                      onTap: () => onChanged(0),
                      tabHeight: tabHeight,
                    ),
                  ),
                  Expanded(
                    child: _FinancePillTabItem(
                      icon: rightIcon,
                      label: rightLabel,
                      active: selectedIndex == 1,
                      onTap: () => onChanged(1),
                      tabHeight: tabHeight,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FinancePillTabItem extends StatelessWidget {
  const _FinancePillTabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.tabHeight,
  });

  final IconData? icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final double tabHeight;

  @override
  Widget build(BuildContext context) {
    final activeColor = FinanceColors.accentPrimary;
    final inactiveColor = FinanceColors.textStrong;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: tabHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFFFE6F4) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: active ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: active ? activeColor : inactiveColor,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 16,
                ),
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceModalSheetHeader extends StatelessWidget {
  const FinanceModalSheetHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.showDivider = true,
  });

  final String title;
  final VoidCallback onClose;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 52,
          height: 6,
          decoration: BoxDecoration(
            color: FinanceColors.sheetDragHandle,
            borderRadius: BorderRadius.circular(FinanceRadius.pill),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 10, 10),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: FinanceColors.textStrong,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 36),
                color: FinanceColors.sheetCloseIcon,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: FinanceColors.sheetDivider,
          ),
      ],
    );
  }
}

class FinanceAdvancedBarChart extends StatelessWidget {
  const FinanceAdvancedBarChart({
    super.key,
    required this.barGroups,
    required this.labels,
    required this.selectedIndex,
    required this.onSelectIndex,
    required this.minY,
    required this.maxY,
    required this.interval,
    this.alignment = BarChartAlignment.spaceAround,
    this.groupsSpace = 8,
    this.leftReservedSize = 40,
    this.bottomReservedSize = 34,
    this.labelWidth,
    this.extraLinesData,
    this.leftLabelBuilder,
    this.bottomLabelHeight = 18,
  });

  final List<BarChartGroupData> barGroups;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;
  final double minY;
  final double maxY;
  final double interval;
  final BarChartAlignment alignment;
  final double groupsSpace;
  final double leftReservedSize;
  final double bottomReservedSize;
  final double? labelWidth;
  final ExtraLinesData? extraLinesData;
  final String Function(double value)? leftLabelBuilder;
  final double bottomLabelHeight;

  String _defaultLeftLabel(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  Widget _singleLineFittedText(
    String text, {
    required TextStyle style,
    required double height,
    Alignment alignment = Alignment.center,
    TextAlign textAlign = TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final resolvedSelectedIndex = barGroups.isEmpty
        ? -1
        : selectedIndex.clamp(0, barGroups.length - 1).toInt();
    final resolvedLabelWidth = labelWidth ?? (labels.length >= 6 ? 44.0 : 90.0);

    return BarChart(
      BarChartData(
        minY: minY,
        maxY: maxY,
        alignment: alignment,
        groupsSpace: groupsSpace,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFE5E8EE), strokeWidth: 1),
        ),
        extraLinesData: extraLinesData,
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Color(0xFF8A8D95), width: 1.2),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          allowTouchBarBackDraw: true,
          touchExtraThreshold: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions) {
              return;
            }
            final touched = response?.spot;
            if (touched == null) {
              return;
            }
            final index = touched.touchedBarGroupIndex;
            if (index < 0 || index >= barGroups.length) {
              return;
            }
            onSelectIndex(index);
          },
        ),
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
              interval: interval,
              reservedSize: leftReservedSize,
              getTitlesWidget: (value, meta) {
                return _singleLineFittedText(
                  leftLabelBuilder?.call(value) ?? _defaultLeftLabel(value),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4F4F58),
                    fontWeight: FontWeight.w500,
                  ),
                  alignment: Alignment.centerRight,
                  textAlign: TextAlign.right,
                  height: 16,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: bottomReservedSize,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length) {
                  return const SizedBox.shrink();
                }
                final isCurrent = index == resolvedSelectedIndex;
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelectIndex(index),
                    child: SizedBox(
                      width: resolvedLabelWidth,
                      child: _singleLineFittedText(
                        labels[index],
                        style: TextStyle(
                          fontSize: 14,
                          color: isCurrent
                              ? const Color(0xFF1A78EE)
                              : const Color(0xFF3F3F47),
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                        height: bottomLabelHeight,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }
}

class FinanceStandardBarChartPoint {
  const FinanceStandardBarChartPoint({
    required this.label,
    required this.amount,
    this.secondaryAmount = 0,
  });

  final String label;
  final double amount;
  final double secondaryAmount;
}

class FinanceStandardBarChart extends StatelessWidget {
  const FinanceStandardBarChart({
    super.key,
    required this.points,
    required this.average,
    required this.caption,
    this.hideAmounts = false,
    this.referenceLineValue,
    this.referenceLineColor,
    this.selectedIndex = -1,
    this.onSelectIndex,
    this.activeBarColor = const Color(0xFF2A8EF5),
    this.inactiveBarColor = const Color(0xFFB7D0E8),
    this.secondaryBarColor = const Color(0xFF75AFE6),
    this.showReferenceLine = true,
    this.showReferenceLabel = true,
    this.showSelectedGuideLine = true,
    this.showSelectedValueBubble = true,
    this.valueFormatter,
    this.captionFooter,
  });

  final List<FinanceStandardBarChartPoint> points;
  final double average;
  final bool hideAmounts;
  final String caption;
  final double? referenceLineValue;
  final Color? referenceLineColor;
  final int selectedIndex;
  final ValueChanged<int>? onSelectIndex;
  final Color activeBarColor;
  final Color inactiveBarColor;
  final Color secondaryBarColor;
  final bool showReferenceLine;
  final bool showReferenceLabel;
  final bool showSelectedGuideLine;
  final bool showSelectedValueBubble;
  final String Function(double value)? valueFormatter;
  final Widget? captionFooter;

  String _money(double value) {
    if (hideAmounts) {
      return '******';
    }
    if (valueFormatter != null) {
      return valueFormatter!(value);
    }
    final raw = Formatters.currency(
      value,
    ).replaceAll(RegExp(r'\s*VND\s*', caseSensitive: false), '').trim();
    return '$rawđ';
  }

  @override
  Widget build(BuildContext context) {
    final referenceValue = referenceLineValue ?? average;
    final lineColor = referenceLineColor ?? FinanceColors.accentPrimary;
    final hasSecondarySeries = points.any((item) => item.secondaryAmount > 0);
    final resolvedSelectedIndex = points.isEmpty
        ? -1
        : (selectedIndex >= 0 && selectedIndex < points.length
              ? selectedIndex
              : points.length - 1);

    final maxValue = [
      referenceValue,
      ...points.map((item) => item.amount),
      ...points.map((item) => item.secondaryAmount),
      1.0,
    ].fold<double>(0.0, (max, value) => value > max ? value : max);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FinanceColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 246,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const chartHeight = 182.0;
                const topReserved = 52.0;
                final barAreaHeight = chartHeight - topReserved;
                final avgTop =
                    topReserved +
                    (barAreaHeight -
                        (referenceValue / maxValue * barAreaHeight));
                final dashedTop = avgTop.clamp(topReserved, chartHeight - 2);
                final labelTop = (avgTop - 18).clamp(4.0, chartHeight - 24);
                final hasSelection =
                    resolvedSelectedIndex >= 0 &&
                    resolvedSelectedIndex < points.length;
                final selectedPoint = hasSelection
                    ? points[resolvedSelectedIndex]
                    : null;
                final selectedPrimaryAmount = selectedPoint?.amount ?? 0.0;
                final selectedPeakAmount = hasSelection
                    ? (selectedPoint!.secondaryAmount > selectedPoint.amount
                          ? selectedPoint.secondaryAmount
                          : selectedPoint.amount)
                    : 0.0;
                final selectedBarHeight = selectedPeakAmount > 0
                    ? (selectedPeakAmount / maxValue * barAreaHeight)
                          .clamp(12.0, barAreaHeight)
                          .toDouble()
                    : 0.0;
                final slotWidth = points.isEmpty
                    ? constraints.maxWidth
                    : constraints.maxWidth / points.length;
                final slotInnerWidth = (slotWidth - 8)
                    .clamp(18.0, 68.0)
                    .toDouble();
                final secondaryBarWidth = hasSecondarySeries
                    ? (slotInnerWidth * 0.32).clamp(9.0, 18.0).toDouble()
                    : 0.0;
                final gapBetweenBars = hasSecondarySeries
                    ? (slotInnerWidth * 0.12).clamp(3.0, 6.0).toDouble()
                    : 0.0;
                final primaryBarWidth = hasSecondarySeries
                    ? (slotInnerWidth - secondaryBarWidth - gapBetweenBars)
                          .clamp(14.0, 34.0)
                          .toDouble()
                    : slotInnerWidth;
                final selectedCenterX = hasSelection
                    ? slotWidth * resolvedSelectedIndex + slotWidth / 2
                    : 0.0;
                final selectedLabelTop = 0.0;
                final selectedBarTop = selectedPeakAmount > 0
                    ? chartHeight - selectedBarHeight
                    : chartHeight - 2;
                const selectedBubbleVerticalPadding = 5.0;
                const selectedBubbleTextSize = 17 / 1.15;
                final selectedLineTop =
                    (showSelectedValueBubble
                            ? selectedLabelTop +
                                  (selectedBubbleVerticalPadding * 2) +
                                  selectedBubbleTextSize
                            : topReserved)
                        .clamp(0.0, chartHeight)
                        .toDouble();
                final selectedLineHeight = (selectedBarTop - selectedLineTop)
                    .clamp(0.0, chartHeight)
                    .toDouble();
                const selectedLabelWidth = 118.0;
                final selectedLabelLeft = hasSelection
                    ? (selectedCenterX - selectedLabelWidth / 2).clamp(
                        4.0,
                        constraints.maxWidth - selectedLabelWidth - 4,
                      )
                    : 0.0;
                const labelRowHeight = 30.0;

                return Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(points.length, (index) {
                                final point = points[index];
                                final primaryValue = point.amount;
                                final secondaryValue = point.secondaryAmount;
                                final hasPrimary = primaryValue > 0;
                                final hasSecondary =
                                    hasSecondarySeries && secondaryValue > 0;
                                final primaryHeight = hasPrimary
                                    ? (primaryValue / maxValue * barAreaHeight)
                                          .clamp(12.0, barAreaHeight)
                                          .toDouble()
                                    : 0.0;
                                final secondaryHeight = hasSecondary
                                    ? (secondaryValue /
                                              maxValue *
                                              barAreaHeight)
                                          .clamp(12.0, barAreaHeight)
                                          .toDouble()
                                    : 0.0;
                                final selected = index == resolvedSelectedIndex;

                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onSelectIndex == null
                                        ? null
                                        : () => onSelectIndex!(index),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: (hasPrimary || hasSecondary)
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  if (hasSecondarySeries)
                                                    Container(
                                                      width: secondaryBarWidth,
                                                      height: secondaryHeight,
                                                      decoration: BoxDecoration(
                                                        color: hasSecondary
                                                            ? secondaryBarColor
                                                            : Colors
                                                                  .transparent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
                                                      ),
                                                    ),
                                                  if (hasSecondarySeries)
                                                    SizedBox(
                                                      width: gapBetweenBars,
                                                    ),
                                                  Container(
                                                    width: primaryBarWidth,
                                                    height: primaryHeight,
                                                    decoration: BoxDecoration(
                                                      color: hasPrimary
                                                          ? (selected
                                                                ? activeBarColor
                                                                : inactiveBarColor)
                                                          : Colors.transparent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const SizedBox(height: 0),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Stack(
                                children: [
                                  if (showReferenceLine)
                                    Positioned(
                                      left: 4,
                                      right: 4,
                                      top: dashedTop,
                                      child: _FinanceDashedHorizontalLine(
                                        color: lineColor,
                                        dashWidth: 10,
                                        gapWidth: 6,
                                        height: 2,
                                      ),
                                    ),
                                  if (showReferenceLine && showReferenceLabel)
                                    Positioned(
                                      left: 0,
                                      top: labelTop,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: lineColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                  if (showSelectedGuideLine &&
                                      hasSelection &&
                                      selectedLineHeight > 0)
                                    Positioned(
                                      left: (selectedCenterX - 0.8).clamp(
                                        0.0,
                                        constraints.maxWidth - 1.6,
                                      ),
                                      top: selectedLineTop,
                                      child: _FinanceDashedVerticalLine(
                                        color: const Color(0xFF8FC4FA),
                                        dashHeight: 8,
                                        gapHeight: 4,
                                        width: 2,
                                        height: selectedLineHeight,
                                      ),
                                    ),
                                  if (showSelectedValueBubble && hasSelection)
                                    Positioned(
                                      left: selectedLabelLeft,
                                      top: selectedLabelTop,
                                      child: Container(
                                        width: selectedLabelWidth,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF8FC4FA),
                                            width: 2,
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            _money(selectedPrimaryAmount),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFF1A78EE),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 17 / 1.15,
                                            ),
                                          ),
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
                    const SizedBox(height: 8),
                    SizedBox(
                      height: labelRowHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: List.generate(points.length, (index) {
                          final point = points[index];
                          final selected = index == resolvedSelectedIndex;
                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onSelectIndex == null
                                  ? null
                                  : () => onSelectIndex!(index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.center,
                                    child: Text(
                                      point.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.visible,
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
                                  ),
                                ),
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
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FinanceDashedHorizontalLine(
                  color: lineColor,
                  dashWidth: 7,
                  gapWidth: 4,
                  height: 2,
                  width: 32,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: SizedBox(
                    height: 20,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Text(
                        caption,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6D6D76),
                          fontSize: 18 / 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (captionFooter != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: captionFooter!,
            ),
          ],
        ],
      ),
    );
  }
}

class _FinanceDashedHorizontalLine extends StatelessWidget {
  const _FinanceDashedHorizontalLine({
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

class _FinanceDashedVerticalLine extends StatelessWidget {
  const _FinanceDashedVerticalLine({
    required this.color,
    required this.dashHeight,
    required this.gapHeight,
    required this.width,
    required this.height,
  });

  final Color color;
  final double dashHeight;
  final double gapHeight;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safeHeight = height.clamp(0.0, double.infinity).toDouble();
    final safeDashHeight = dashHeight <= 0 ? 1.0 : dashHeight;
    final safeGapHeight = gapHeight < 0 ? 0.0 : gapHeight;
    final segments = <Widget>[];
    var remaining = safeHeight;
    var guard = 0;

    while (remaining > 0 && guard < 500) {
      var segmentHeight = remaining < safeDashHeight
          ? remaining
          : safeDashHeight;
      remaining -= segmentHeight;

      // Avoid ending with a trailing empty gap by extending the last dash.
      if (remaining > 0 && remaining <= safeGapHeight) {
        segmentHeight += remaining;
        remaining = 0;
      }

      segments.add(
        Container(width: width, height: segmentHeight, color: color),
      );

      if (remaining <= 0) {
        break;
      }

      final gap = remaining < safeGapHeight ? remaining : safeGapHeight;
      if (gap > 0) {
        segments.add(SizedBox(height: gap));
        remaining -= gap;
      }

      guard++;
    }

    return SizedBox(
      width: width,
      height: safeHeight,
      child: Column(children: segments),
    );
  }
}
