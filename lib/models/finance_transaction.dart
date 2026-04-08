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
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime createdAt;
  final String? note;
  final bool includedInReports;

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
    );
  }
}
