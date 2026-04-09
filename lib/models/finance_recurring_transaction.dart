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
    return FinanceTransaction.normalizeFundingSourceId(sourceId);
  }

  static int? _readNullableInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    return null;
  }

  static bool? _readNullableBool(dynamic raw) {
    if (raw is bool) {
      return raw;
    }
    if (raw is num) {
      return raw != 0;
    }
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return null;
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
      fundingSourceId: normalizeFundingSourceId(
        fundingSourceId ?? this.fundingSourceId,
      ),
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
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: TransactionType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => TransactionType.expense,
      ),
      category: map['category']?.toString() ?? 'Khác',
      fundingSourceId: normalizeFundingSourceId(
        map['fundingSourceId']?.toString(),
      ),
      fundingSourceLabel:
          map['fundingSourceLabel']?.toString() ??
          FinanceTransaction.defaultFundingSourceLabel,
      frequency: map['frequency']?.toString() ?? 'monthly',
      startDate:
          DateTime.tryParse(map['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(map['endDate']?.toString() ?? ''),
      nextDate:
          DateTime.tryParse(map['nextDate']?.toString() ?? '') ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      note: map['note']?.toString(),
      categoryIconCodePoint: _readNullableInt(map['categoryIconCodePoint']),
      categoryIconFontFamily: map['categoryIconFontFamily']?.toString(),
      categoryIconFontPackage: map['categoryIconFontPackage']?.toString(),
      categoryIconMatchTextDirection: _readNullableBool(
        map['categoryIconMatchTextDirection'],
      ),
      categoryIconColorValue: _readNullableInt(map['categoryIconColorValue']),
    );
  }
}
