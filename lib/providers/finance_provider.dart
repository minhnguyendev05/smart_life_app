import 'package:flutter/material.dart';

import '../models/finance_category.dart';
import '../models/finance_transaction.dart';
import '../services/firestore_finance_category_service.dart';
import '../services/local_storage_service.dart';

class FinanceProvider extends ChangeNotifier {
  static const _transactionsStorageKey = 'finance_transactions';
  static const _categoriesStorageKey = 'finance_custom_categories';

  LocalStorageService? _storage;
  FirestoreFinanceCategoryService? _categoryCloud;
  final List<FinanceTransaction> _transactions = [];
  final List<FinanceCategory> _customCategories = [];
  bool _loaded = false;
  double _monthlyBudget = 0;

  List<FinanceTransaction> get transactions {
    final sorted = List<FinanceTransaction>.from(_transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  List<FinanceCategory> get customCategories {
    final sorted = List<FinanceCategory>.from(_customCategories)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(sorted);
  }

  double get monthlyBudget => _monthlyBudget;

  double get totalIncome => _transactions
      .where((e) => e.type == TransactionType.income && e.includedInReports)
      .fold(0, (sum, item) => sum + item.amount);

  double get totalExpense => _transactions
      .where((e) => e.type == TransactionType.expense && e.includedInReports)
      .fold(0, (sum, item) => sum + item.amount);

  double get balance => totalIncome - totalExpense;

  bool get isOverBudget => totalExpense > _monthlyBudget;

  List<FinanceTransaction> filterTransactions({
    TransactionType? type,
    DateTime? month,
  }) {
    return transactions.where((e) {
      final okType = type == null || e.type == type;
      final okMonth =
          month == null ||
          (e.createdAt.year == month.year && e.createdAt.month == month.month);
      return okType && okMonth && e.includedInReports;
    }).toList();
  }

  Map<String, double> expenseByCategory({DateTime? month}) {
    final map = <String, double>{};
    final list = filterTransactions(
      type: TransactionType.expense,
      month: month,
    );
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

  void attachCategoryCloud(FirestoreFinanceCategoryService cloud) {
    if (identical(_categoryCloud, cloud)) {
      return;
    }
    _categoryCloud = cloud;
    if (_loaded) {
      _syncCategoriesWithCloud();
    }
  }

  Future<void> load() async {
    if (_storage == null) return;
    final raw = await _storage!.readList(_transactionsStorageKey);
    _transactions
      ..clear()
      ..addAll(raw.map(FinanceTransaction.fromMap));

    final categoryRaw = await _storage!.readList(_categoriesStorageKey);
    _customCategories
      ..clear()
      ..addAll(categoryRaw.map(FinanceCategory.fromMap));

    await _syncCategoriesWithCloud();

    _loaded = true;
    notifyListeners();
  }

  Future<void> addTransaction(FinanceTransaction transaction) async {
    _transactions.add(transaction);
    await _persist();
    notifyListeners();
  }

  Future<FinanceTransaction?> updateTransactionCategory({
    required String transactionId,
    required String category,
  }) async {
    return updateTransactionClassification(
      transactionId: transactionId,
      category: category,
      includedInReports: true,
    );
  }

  Future<FinanceTransaction?> updateTransactionClassification({
    required String transactionId,
    String? category,
    bool? includedInReports,
  }) async {
    final normalizedCategory = category?.trim();
    final nextIncludedInReports = includedInReports;

    if ((normalizedCategory == null || normalizedCategory.isEmpty) &&
        nextIncludedInReports == null) {
      return null;
    }

    final index = _transactions.indexWhere((item) => item.id == transactionId);
    if (index < 0) {
      return null;
    }

    final current = _transactions[index];
    final targetCategory =
        (normalizedCategory == null || normalizedCategory.isEmpty)
        ? current.category
        : normalizedCategory;
    final targetIncluded = nextIncludedInReports ?? current.includedInReports;

    if (current.category.trim().toLowerCase() == targetCategory.toLowerCase() &&
        current.includedInReports == targetIncluded) {
      return current;
    }

    final updated = FinanceTransaction(
      id: current.id,
      title: current.title,
      amount: current.amount,
      category: targetCategory,
      type: current.type,
      createdAt: current.createdAt,
      note: current.note,
      includedInReports: targetIncluded,
    );

    _transactions[index] = updated;
    await _persist();
    notifyListeners();
    return updated;
  }

  Future<void> addOrUpdateCustomCategory(FinanceCategory category) async {
    final normalizedName = category.name.trim().toLowerCase();
    final existingByName = _customCategories.indexWhere(
      (item) =>
          item.type == category.type &&
          item.name.trim().toLowerCase() == normalizedName,
    );

    final normalizedCategory = category.copyWith(updatedAt: DateTime.now());
    if (existingByName >= 0) {
      final existing = _customCategories[existingByName];
      _customCategories[existingByName] = normalizedCategory.copyWith(
        id: existing.id,
      );
    } else {
      final existingById = _customCategories.indexWhere(
        (item) => item.id == normalizedCategory.id,
      );
      if (existingById >= 0) {
        _customCategories[existingById] = normalizedCategory;
      } else {
        _customCategories.add(normalizedCategory);
      }
    }

    await _persist();
    await _categoryCloud?.saveCategory(normalizedCategory);
    notifyListeners();
  }

  Future<void> updateBudget(double budget) async {
    _monthlyBudget = budget;
    notifyListeners();
  }

  Future<void> _syncCategoriesWithCloud() async {
    final cloud = _categoryCloud;
    if (cloud == null) {
      return;
    }

    final cloudCategories = await cloud.loadCategories();
    if (cloudCategories.isEmpty) {
      for (final category in _customCategories) {
        await cloud.saveCategory(category);
      }
      return;
    }

    final mergedById = <String, FinanceCategory>{
      for (final item in cloudCategories) item.id: item,
    };

    for (final local in _customCategories) {
      if (mergedById.containsKey(local.id)) {
        continue;
      }
      mergedById[local.id] = local;
      await cloud.saveCategory(local);
    }

    final merged = mergedById.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _customCategories
      ..clear()
      ..addAll(merged);

    if (_storage != null) {
      final mapped = _customCategories.map((e) => e.toMap()).toList();
      await _storage!.saveList(_categoriesStorageKey, mapped);
    }

    notifyListeners();
  }

  Future<void> _persist() async {
    if (_storage == null) return;
    final mappedTransactions = _transactions.map((e) => e.toMap()).toList();
    final mappedCategories = _customCategories.map((e) => e.toMap()).toList();
    await _storage!.saveList(_transactionsStorageKey, mappedTransactions);
    await _storage!.saveList(_categoriesStorageKey, mappedCategories);
  }
}
