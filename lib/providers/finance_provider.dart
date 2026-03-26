import 'package:flutter/material.dart';

import '../models/finance_transaction.dart';
import '../services/local_storage_service.dart';

class FinanceProvider extends ChangeNotifier {
  static const _storageKey = 'finance_transactions';

  LocalStorageService? _storage;
  final List<FinanceTransaction> _transactions = [];
  bool _loaded = false;
  double _monthlyBudget = 2500000;

  List<FinanceTransaction> get transactions {
    final sorted = List<FinanceTransaction>.from(_transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  double get monthlyBudget => _monthlyBudget;

  double get totalIncome => _transactions
      .where((e) => e.type == TransactionType.income)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpense => _transactions
      .where((e) => e.type == TransactionType.expense)
      .fold(0, (sum, item) => sum + item.amount);

  double get balance => totalIncome - totalExpense;

  bool get isOverBudget => totalExpense > _monthlyBudget;

  List<FinanceTransaction> filterTransactions({
    TransactionType? type,
    DateTime? month,
  }) {
    return transactions.where((e) {
      final okType = type == null || e.type == type;
      final okMonth = month == null ||
          (e.createdAt.year == month.year && e.createdAt.month == month.month);
      return okType && okMonth;
    }).toList();
  }

  Map<String, double> expenseByCategory({DateTime? month}) {
    final map = <String, double>{};
    final list = filterTransactions(type: TransactionType.expense, month: month);
    for (final item in list) {
      map[item.category] = (map[item.category] ?? 0) + item.amount;
    }
    return map;
  }

  Future<void> attachStorage(LocalStorageService storage) async {
    _storage = storage;
    if (!_loaded) {
      await load();
    }
  }

  Future<void> load() async {
    if (_storage == null) return;
    final raw = await _storage!.readList(_storageKey);
    _transactions
      ..clear()
      ..addAll(raw.map(FinanceTransaction.fromMap));
    _loaded = true;
    notifyListeners();
  }

  Future<void> addTransaction(FinanceTransaction transaction) async {
    _transactions.add(transaction);
    await _persist();
    notifyListeners();
  }

  Future<void> updateBudget(double budget) async {
    _monthlyBudget = budget;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_storage == null) return;
    final mapped = _transactions.map((e) => e.toMap()).toList();
    await _storage!.saveList(_storageKey, mapped);
  }

}
