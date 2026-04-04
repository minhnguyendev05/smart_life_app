import 'package:flutter/material.dart';

import 'finance_transaction.dart';

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.type,
    required this.name,
    required this.group,
    required this.iconCodePoint,
    required this.colorValue,
    required this.updatedAt,
    this.iconFontFamily,
    this.iconFontPackage,
    this.iconMatchTextDirection = false,
  });

  final String id;
  final TransactionType type;
  final String name;
  final String group;
  final int iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final bool iconMatchTextDirection;
  final int colorValue;
  final DateTime updatedAt;

  IconData get icon => IconData(
    iconCodePoint,
    fontFamily: iconFontFamily,
    fontPackage: iconFontPackage,
    matchTextDirection: iconMatchTextDirection,
  );

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'group': group,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'iconFontPackage': iconFontPackage,
      'iconMatchTextDirection': iconMatchTextDirection,
      'colorValue': colorValue,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FinanceCategory.fromMap(Map<dynamic, dynamic> map) {
    final parsedType = TransactionType.values.firstWhere(
      (item) => item.name == map['type'],
      orElse: () => TransactionType.expense,
    );
    final updatedAtRaw = map['updatedAt'] as String?;

    return FinanceCategory(
      id:
          map['id'] as String? ??
          buildStableId(
            type: parsedType,
            name: map['name'] as String? ?? 'category',
          ),
      type: parsedType,
      name: map['name'] as String? ?? '',
      group: map['group'] as String? ?? 'Khac',
      iconCodePoint:
          (map['iconCodePoint'] as num?)?.toInt() ??
          Icons.category_outlined.codePoint,
      iconFontFamily: map['iconFontFamily'] as String?,
      iconFontPackage: map['iconFontPackage'] as String?,
      iconMatchTextDirection: map['iconMatchTextDirection'] as bool? ?? false,
      colorValue:
          (map['colorValue'] as num?)?.toInt() ?? const Color(0xFF9E9EA6).value,
      updatedAt: updatedAtRaw == null
          ? DateTime.now()
          : DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
    );
  }

  FinanceCategory copyWith({
    String? id,
    TransactionType? type,
    String? name,
    String? group,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    bool? iconMatchTextDirection,
    int? colorValue,
    DateTime? updatedAt,
  }) {
    return FinanceCategory(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      group: group ?? this.group,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      iconMatchTextDirection:
          iconMatchTextDirection ?? this.iconMatchTextDirection,
      colorValue: colorValue ?? this.colorValue,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String buildStableId({
    required TransactionType type,
    required String name,
  }) {
    final normalized = name.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final asciiSlug = normalized
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
        .replaceAll(RegExp(r'-+'), '-');
    if (asciiSlug.isNotEmpty) {
      return '${type.name}-$asciiSlug';
    }

    var hash = 2166136261;
    for (final code in normalized.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return '${type.name}-${hash.toRadixString(16)}';
  }
}
