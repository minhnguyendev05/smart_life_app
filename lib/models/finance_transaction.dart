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
    this.fundingSourceId = defaultFundingSourceId,
    this.fundingSourceLabel = defaultFundingSourceLabel,
    this.categoryIconCodePoint,
    this.categoryIconFontFamily,
    this.categoryIconFontPackage,
    this.categoryIconMatchTextDirection,
    this.categoryIconColorValue,
  });

  static const String smartLifeFundingSourceId = 'smartlife';
  static const String defaultFundingSourceId = 'other_smartlife';
  static const String defaultFundingSourceLabel = 'Ngoài SmartLife';
  static const Set<String> knownFundingSourceIds = <String>{
    smartLifeFundingSourceId,
    'than_tai',
    'mbbank',
    'group_ae',
    'group_dau',
    'reward_fund',
    'group_hi',
    defaultFundingSourceId,
    'agribank',
  };

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
    final normalized = sourceId?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) {
      return defaultFundingSourceId;
    }
    if (normalized == 'momo') {
      return smartLifeFundingSourceId;
    }
    if (knownFundingSourceIds.contains(normalized)) {
      return normalized;
    }
    if (normalized.contains('other')) {
      return defaultFundingSourceId;
    }
    return smartLifeFundingSourceId;
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

  static DateTime _readDateTime(dynamic raw) {
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
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
    bool clearCategoryIconSnapshot = false,
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
      categoryIconCodePoint: clearCategoryIconSnapshot
          ? null
          : (categoryIconCodePoint ?? this.categoryIconCodePoint),
      categoryIconFontFamily: clearCategoryIconSnapshot
          ? null
          : (categoryIconFontFamily ?? this.categoryIconFontFamily),
      categoryIconFontPackage: clearCategoryIconSnapshot
          ? null
          : (categoryIconFontPackage ?? this.categoryIconFontPackage),
      categoryIconMatchTextDirection: clearCategoryIconSnapshot
          ? null
          : (categoryIconMatchTextDirection ??
                this.categoryIconMatchTextDirection),
      categoryIconColorValue: clearCategoryIconSnapshot
          ? null
          : (categoryIconColorValue ?? this.categoryIconColorValue),
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
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: map['category']?.toString() ?? 'Khác',
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type']?.toString(),
        orElse: () => TransactionType.expense,
      ),
      createdAt: _readDateTime(map['createdAt']),
      note: map['note']?.toString(),
      includedInReports: _readNullableBool(map['includedInReports']) ?? true,
      fundingSourceId: normalizeFundingSourceId(
        map['fundingSourceId']?.toString(),
      ),
      fundingSourceLabel:
          map['fundingSourceLabel']?.toString() ?? defaultFundingSourceLabel,
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
