import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class FinanceTransaction {
  FinanceTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.createdAt,
    this.note,
    this.includedInReports = true,
    this.fundingSourceId = 'other_smartlife',
    this.fundingSourceLabel = 'Ngoài SmartLife',
    this.categoryIconCodePoint,
    this.categoryIconFontFamily,
    this.categoryIconFontPackage,
    this.categoryIconMatchTextDirection,
    this.categoryIconColorValue,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime createdAt;
  final String? note;
  final bool includedInReports;
  final String fundingSourceId;
  final String fundingSourceLabel;
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

  FinanceTransaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    TransactionType? type,
    DateTime? createdAt,
    String? note,
    bool? includedInReports,
    String? fundingSourceId,
    String? fundingSourceLabel,
    int? categoryIconCodePoint,
    String? categoryIconFontFamily,
    String? categoryIconFontPackage,
    bool? categoryIconMatchTextDirection,
    int? categoryIconColorValue,
  }) {
    return FinanceTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      includedInReports: includedInReports ?? this.includedInReports,
      fundingSourceId: normalizeFundingSourceId(
        fundingSourceId ?? this.fundingSourceId,
      ),
      fundingSourceLabel: fundingSourceLabel ?? this.fundingSourceLabel,
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
      'category': category,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
      'includedInReports': includedInReports,
      'fundingSourceId': fundingSourceId,
      'fundingSourceLabel': fundingSourceLabel,
      'categoryIconCodePoint': categoryIconCodePoint,
      'categoryIconFontFamily': categoryIconFontFamily,
      'categoryIconFontPackage': categoryIconFontPackage,
      'categoryIconMatchTextDirection': categoryIconMatchTextDirection,
      'categoryIconColorValue': categoryIconColorValue,
    };
  }

  factory FinanceTransaction.fromMap(Map<dynamic, dynamic> map) {
    return FinanceTransaction(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      note: map['note'] as String?,
      includedInReports: map['includedInReports'] as bool? ?? true,
      fundingSourceId: normalizeFundingSourceId(
        map['fundingSourceId'] as String?,
      ),
      fundingSourceLabel:
          map['fundingSourceLabel'] as String? ?? 'Ngoài SmartLife',
      categoryIconCodePoint: (map['categoryIconCodePoint'] as num?)?.toInt(),
      categoryIconFontFamily: map['categoryIconFontFamily'] as String?,
      categoryIconFontPackage: map['categoryIconFontPackage'] as String?,
      categoryIconMatchTextDirection:
          map['categoryIconMatchTextDirection'] as bool?,
      categoryIconColorValue: (map['categoryIconColorValue'] as num?)?.toInt(),
    );
  }
}
