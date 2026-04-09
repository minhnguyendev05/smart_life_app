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

class FinanceCategoryVisual {
  const FinanceCategoryVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class FinanceCategoryVisualCatalog {
  FinanceCategoryVisualCatalog._();

  static FinanceCategoryVisual? resolve(
    String category, {
    required bool isExpense,
  }) {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return isExpense ? _resolveExpense(normalized) : _resolveIncome(normalized);
  }

  static IconData iconFor(
    String category, {
    required bool isExpense,
    required IconData fallbackIcon,
  }) {
    return resolve(category, isExpense: isExpense)?.icon ?? fallbackIcon;
  }

  static Color colorFor(
    String category, {
    required bool isExpense,
    required Color fallbackColor,
  }) {
    return resolve(category, isExpense: isExpense)?.color ?? fallbackColor;
  }

  static bool _containsAny(String source, List<String> fragments) {
    for (final fragment in fragments) {
      if (source.contains(fragment)) {
        return true;
      }
    }
    return false;
  }

  static FinanceCategoryVisual? _resolveExpense(String normalized) {
    if (_containsAny(normalized, ['chợ', 'cho', 'siêu thị', 'sieu thi'])) {
      return const FinanceCategoryVisual(
        icon: Icons.shopping_basket_outlined,
        color: Color(0xFFF6A43C),
      );
    }
    if (_containsAny(normalized, ['ăn', 'an uong', 'uong'])) {
      return const FinanceCategoryVisual(
        icon: Icons.restaurant_rounded,
        color: Color(0xFFFF7E45),
      );
    }
    if (_containsAny(normalized, ['di chuyển', 'di chuyen', 'xe'])) {
      return const FinanceCategoryVisual(
        icon: Icons.directions_car_filled_outlined,
        color: Color(0xFF64AFE8),
      );
    }
    if (_containsAny(normalized, ['mua sắm', 'mua sam', 'shop'])) {
      return const FinanceCategoryVisual(
        icon: Icons.shopping_cart_outlined,
        color: Color(0xFFF6A83A),
      );
    }
    if (_containsAny(normalized, ['giải trí', 'giai tri'])) {
      return const FinanceCategoryVisual(
        icon: Icons.movie_creation_outlined,
        color: Color(0xFFF58AAE),
      );
    }
    if (_containsAny(normalized, ['làm đẹp', 'lam dep'])) {
      return const FinanceCategoryVisual(
        icon: Icons.face_retouching_natural_outlined,
        color: Color(0xFFF26AB8),
      );
    }
    if (_containsAny(normalized, ['sức khỏe', 'suc khoe', 'y tế', 'y te'])) {
      return const FinanceCategoryVisual(
        icon: Icons.favorite_outline_rounded,
        color: Color(0xFFF66079),
      );
    }
    if (_containsAny(normalized, ['hóa đơn', 'hoa don', 'bill'])) {
      return const FinanceCategoryVisual(
        icon: Icons.receipt_long_outlined,
        color: Color(0xFF47C7A8),
      );
    }
    if (_containsAny(normalized, ['nhà cửa', 'nha cua', 'nhà'])) {
      return const FinanceCategoryVisual(
        icon: Icons.home_work_outlined,
        color: Color(0xFFA79CF7),
      );
    }
    if (_containsAny(normalized, ['người thân', 'nguoi than'])) {
      return const FinanceCategoryVisual(
        icon: Icons.child_care_outlined,
        color: Color(0xFFF06CB8),
      );
    }
    if (_containsAny(normalized, ['đầu tư', 'dau tu'])) {
      return const FinanceCategoryVisual(
        icon: Icons.savings_outlined,
        color: Color(0xFF45C5AE),
      );
    }
    if (_containsAny(normalized, ['học', 'hoc'])) {
      return const FinanceCategoryVisual(
        icon: Icons.menu_book_outlined,
        color: Color(0xFF9189F5),
      );
    }
    if (_containsAny(normalized, ['từ thiện', 'tu thien'])) {
      return const FinanceCategoryVisual(
        icon: Icons.volunteer_activism_outlined,
        color: Color(0xFFF477BF),
      );
    }
    if (_containsAny(normalized, ['khác', 'khac', 'other'])) {
      return const FinanceCategoryVisual(
        icon: Icons.grid_view_rounded,
        color: FinanceColors.accentPrimary,
      );
    }
    return null;
  }

  static FinanceCategoryVisual? _resolveIncome(String normalized) {
    if (_containsAny(normalized, ['kinh doanh', 'bán', 'ban'])) {
      return const FinanceCategoryVisual(
        icon: Icons.storefront_outlined,
        color: Color(0xFF2C9BFF),
      );
    }
    if (_containsAny(normalized, ['lương', 'luong'])) {
      return const FinanceCategoryVisual(
        icon: Icons.badge_outlined,
        color: Color(0xFF48B86F),
      );
    }
    if (_containsAny(normalized, ['thưởng', 'thuong'])) {
      return const FinanceCategoryVisual(
        icon: Icons.workspace_premium_outlined,
        color: Color(0xFFF8A540),
      );
    }
    if (_containsAny(normalized, ['freelance', 'tự do', 'tu do'])) {
      return const FinanceCategoryVisual(
        icon: Icons.laptop_mac_outlined,
        color: Color(0xFF7C8CFF),
      );
    }
    if (_containsAny(normalized, [
      'hỗ trợ',
      'ho tro',
      'gia đình',
      'gia dinh',
    ])) {
      return const FinanceCategoryVisual(
        icon: Icons.favorite_border_rounded,
        color: Color(0xFFF06CB8),
      );
    }
    if (_containsAny(normalized, ['lợi nhuận', 'loi nhuan'])) {
      return const FinanceCategoryVisual(
        icon: Icons.savings_outlined,
        color: Color(0xFF45C5AE),
      );
    }
    if (_containsAny(normalized, ['trợ cấp', 'tro cap'])) {
      return const FinanceCategoryVisual(
        icon: Icons.volunteer_activism_outlined,
        color: Color(0xFFF26AB8),
      );
    }
    if (_containsAny(normalized, ['thu hồi', 'thu hoi'])) {
      return const FinanceCategoryVisual(
        icon: Icons.refresh_rounded,
        color: Color(0xFF64AFE8),
      );
    }
    if (_containsAny(normalized, ['khác', 'khac', 'other'])) {
      return const FinanceCategoryVisual(
        icon: Icons.grid_view_rounded,
        color: Color(0xFF8E8EA0),
      );
    }
    return null;
  }
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
