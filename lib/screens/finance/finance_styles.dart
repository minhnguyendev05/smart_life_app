import 'package:flutter/material.dart';

/// Shared design tokens for the Finance feature.
///
/// Keep recurring values here so visual updates can be applied in one place.
class FinanceColors {
  FinanceColors._();

  static const Color background = Color(0xFFF4F2F8);
  static const Color appBarTint = Color(0xFFFBE6F2);
  static const Color appBarGradientTop = Color(0xFFFBD8EA);
  static const Color appBarGradientBottom = Color(0xFFF4F3F8);
  static const Color appBarActionIcon = Color(0xFF4F4F58);
  static const Color appBarActionDivider = Color(0xFFD5D2DC);
  static const Color sheetBackground = Color(0xFFF4F3F8);
  static const Color sheetBackgroundSoft = Color(0xFFF7F6FB);
  static const Color sheetDragHandle = Color(0xFFD8D7DD);
  static const Color sheetCloseIcon = Color(0xFF3D3D45);
  static const Color sheetDivider = Color(0xFFE5E3EB);
  static const Color panelBorder = Color(0xFFE6E2EC);
  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF7F6FB);
  static const Color border = Color(0xFFE8E3EE);
  static const Color borderSoft = Color(0xFFE7E5EC);

  static const Color textPrimary = Color(0xFF32323A);
  static const Color textStrong = Color(0xFF2F2F37);
  static const Color textSecondary = Color(0xFF6E6E78);
  static const Color textMuted = Color(0xFF9E9EA6);

  static const Color accentPrimary = Color(0xFFF12D9D);
  static const Color accentSecondary = Color(0xFFF63FA7);
}

class FinanceRadius {
  FinanceRadius._();

  static const double xs = 10;
  static const double sm = 14;
  static const double md = 16;
  static const double lg = 20;
  static const double sheetTop = 26;
  static const double pill = 999;
}

class FinanceSpacing {
  FinanceSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

class FinanceDecorations {
  FinanceDecorations._();

  static BoxDecoration surfaceCard({
    Color color = FinanceColors.surface,
    double radius = FinanceRadius.md,
    Color borderColor = FinanceColors.border,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
    );
  }

  static BoxDecoration softPanel({double radius = FinanceRadius.md}) {
    return BoxDecoration(
      color: FinanceColors.surfaceSoft,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static BoxDecoration iconBadge({
    required Color color,
    double radius = FinanceRadius.pill,
    double alpha = 0.12,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
