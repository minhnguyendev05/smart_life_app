import 'package:flutter/material.dart';

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
        if (trailing != null) trailing!,
      ],
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
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      side: BorderSide(color: sideColor),
      foregroundColor: foregroundColor,
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
            color: const Color(0xFFD8D7DD),
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
                color: const Color(0xFF3D3D45),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E3EB)),
      ],
    );
  }
}
