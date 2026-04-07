import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
