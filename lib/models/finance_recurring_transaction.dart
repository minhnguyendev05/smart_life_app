import 'package:flutter/material.dart';

import 'finance_transaction.dart';

class FinanceRecurringTransaction {
  const FinanceRecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.fundingSourceId,
    required this.fundingSourceLabel,
    required this.frequency,
    required this.startDate,
    required this.nextDate,
    required this.createdAt,
    this.endDate,
    this.note,
    this.categoryIconCodePoint,
    this.categoryIconFontFamily,
    this.categoryIconFontPackage,
    this.categoryIconMatchTextDirection,
    this.categoryIconColorValue,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String fundingSourceId;
  final String fundingSourceLabel;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDate;
  final DateTime createdAt;
  final String? note;
  final int? categoryIconCodePoint;
  final String? categoryIconFontFamily;
  final String? categoryIconFontPackage;
  final bool? categoryIconMatchTextDirection;
  final int? categoryIconColorValue;

  static String normalizeFundingSourceId(String? sourceId) {
    final normalized = sourceId?.trim() ?? '';
    if (normalized.isEmpty) {
      return 'other_smartlife';
    }
    const knownIds = <String>{
      'smartlife',
      'than_tai',
      'mbbank',
      'group_ae',
      'group_dau',
      'reward_fund',
      'group_hi',
      'other_smartlife',
      'agribank',
    };
    if (knownIds.contains(normalized)) {
      return normalized;
    }
    if (normalized.contains('other')) {
      return 'other_smartlife';
    }
    return 'smartlife';
  }

  IconData? get categoryIcon {
    final codePoint = categoryIconCodePoint;
    if (codePoint == null) {
      return null;
    }
    return IconData(
      codePoint,
      fontFamily: categoryIconFontFamily,
      fontPackage: categoryIconFontPackage,
      matchTextDirection: categoryIconMatchTextDirection ?? false,
    );
  }

  Color? get categoryIconColor {
    final raw = categoryIconColorValue;
    if (raw == null) {
      return null;
    }
    return Color(raw);
  }

  FinanceRecurringTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? fundingSourceId,
    String? fundingSourceLabel,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    DateTime? nextDate,
    DateTime? createdAt,
    String? note,
    bool clearNote = false,
    int? categoryIconCodePoint,
    String? categoryIconFontFamily,
    String? categoryIconFontPackage,
    bool? categoryIconMatchTextDirection,
    int? categoryIconColorValue,
  }) {
    return FinanceRecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      fundingSourceId: fundingSourceId ?? this.fundingSourceId,
      fundingSourceLabel: fundingSourceLabel ?? this.fundingSourceLabel,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      nextDate: nextDate ?? this.nextDate,
      createdAt: createdAt ?? this.createdAt,
      note: clearNote ? null : (note ?? this.note),
      categoryIconCodePoint:
          categoryIconCodePoint ?? this.categoryIconCodePoint,
      categoryIconFontFamily:
          categoryIconFontFamily ?? this.categoryIconFontFamily,
      categoryIconFontPackage:
          categoryIconFontPackage ?? this.categoryIconFontPackage,
      categoryIconMatchTextDirection:
          categoryIconMatchTextDirection ?? this.categoryIconMatchTextDirection,
      categoryIconColorValue:
          categoryIconColorValue ?? this.categoryIconColorValue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'fundingSourceId': fundingSourceId,
      'fundingSourceLabel': fundingSourceLabel,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextDate': nextDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'note': note,
      'categoryIconCodePoint': categoryIconCodePoint,
      'categoryIconFontFamily': categoryIconFontFamily,
      'categoryIconFontPackage': categoryIconFontPackage,
      'categoryIconMatchTextDirection': categoryIconMatchTextDirection,
      'categoryIconColorValue': categoryIconColorValue,
    };
  }

  factory FinanceRecurringTransaction.fromMap(Map<dynamic, dynamic> map) {
    return FinanceRecurringTransaction(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: TransactionType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      category: map['category'] as String? ?? 'Khác',
      fundingSourceId: normalizeFundingSourceId(
        map['fundingSourceId'] as String?,
      ),
      fundingSourceLabel: map['fundingSourceLabel'] as String? ?? 'Ngoài SmartLife',
      frequency: map['frequency'] as String? ?? 'monthly',
      startDate:
          DateTime.tryParse(map['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] as String? ?? ''),
      nextDate:
          DateTime.tryParse(map['nextDate'] as String? ?? '') ?? DateTime.now(),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      note: map['note'] as String?,
      categoryIconCodePoint: (map['categoryIconCodePoint'] as num?)?.toInt(),
      categoryIconFontFamily: map['categoryIconFontFamily'] as String?,
      categoryIconFontPackage: map['categoryIconFontPackage'] as String?,
      categoryIconMatchTextDirection:
          map['categoryIconMatchTextDirection'] as bool?,
      categoryIconColorValue: (map['categoryIconColorValue'] as num?)?.toInt(),
    );
  }
}
