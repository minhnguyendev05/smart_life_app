import 'package:flutter/material.dart';
import 'dart:async';

import '../models/finance_category.dart';
import '../models/finance_recurring_transaction.dart';
import '../models/finance_transaction.dart';
import '../services/firestore_finance_category_service.dart';
import '../services/local_storage_service.dart';

class FinanceProvider extends ChangeNotifier {
  static const _transactionsStorageKey = 'finance_transactions';
  static const _categoriesStorageKey = 'finance_custom_categories';
  static const _recurringStorageKey = 'finance_recurring_transactions';
  static const _settingsStorageKey = 'finance_settings';
  static const _storageVersion = 'v2';

  LocalStorageService? _storage;
  FirestoreFinanceCategoryService? _categoryCloud;
  final List<FinanceTransaction> _transactions = [];
  final List<FinanceCategory> _customCategories = [];
  final List<FinanceRecurringTransaction> _recurringTransactions = [];
  final Map<String, double> _customCategoryMonthlyBudgets = {};
  bool _loaded = false;
  double _monthlyBudget = 0;
  bool _hasConfiguredBudget = false;
  String _userScope = 'guest';

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

  List<FinanceRecurringTransaction> get recurringTransactions {
    final sorted = List<FinanceRecurringTransaction>.from(
      _recurringTransactions,
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  FinanceRecurringTransaction? findRecurringById(String recurringId) {
    for (final item in _recurringTransactions) {
      if (item.id == recurringId) {
        return item;
      }
    }
    return null;
  }

  double get monthlyBudget => _monthlyBudget;
  Map<String, double> get customCategoryMonthlyBudgets =>
      Map.unmodifiable(_customCategoryMonthlyBudgets);

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

  void bindUser(String userId) {
    final normalized = _normalizeUserScope(userId);
    if (_userScope == normalized) {
      return;
    }
    _userScope = normalized;
    _loaded = false;
    _transactions.clear();
    _customCategories.clear();
    _recurringTransactions.clear();
    _customCategoryMonthlyBudgets.clear();
    _monthlyBudget = 0;
    _hasConfiguredBudget = false;
    notifyListeners();
    if (_storage != null) {
      unawaited(load());
    }
  }

  void attachCategoryCloud(FirestoreFinanceCategoryService cloud) {
    if (identical(_categoryCloud, cloud)) {
      return;
    }
    _categoryCloud = cloud;
    if (_loaded) {
      unawaited(_syncAllCloudDataSafely());
    }
  }

  String _normalizeUserScope(String userId) {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      return 'guest';
    }
    return trimmed;
  }

  String _storageKey(String baseKey) {
    return 'u:$_userScope:$baseKey:$_storageVersion';
  }

  Future<void> load() async {
    if (_storage == null) return;
    final raw = await _storage!.readList(_storageKey(_transactionsStorageKey));
    _transactions
      ..clear()
      ..addAll(raw.map(FinanceTransaction.fromMap));

    final recurringRaw = await _storage!.readList(
      _storageKey(_recurringStorageKey),
    );
    _recurringTransactions
      ..clear()
      ..addAll(recurringRaw.map(FinanceRecurringTransaction.fromMap));

    final categoryRaw = await _storage!.readList(
      _storageKey(_categoriesStorageKey),
    );
    _customCategories
      ..clear()
      ..addAll(categoryRaw.map(FinanceCategory.fromMap));

    final settingsRaw = await _storage!.readList(
      _storageKey(_settingsStorageKey),
    );
    if (settingsRaw.isNotEmpty) {
      final first = Map<dynamic, dynamic>.from(settingsRaw.first);
      _monthlyBudget = (first['monthlyBudget'] as num?)?.toDouble() ?? 0;
      final configuredRaw = first['budgetConfigured'];
      final totalBudgetConfigured = configuredRaw is bool
          ? configuredRaw
          : _monthlyBudget > 0;
      if (!totalBudgetConfigured) {
        _monthlyBudget = 0;
      }

      final categoryBudgetsRaw = first['categoryMonthlyBudgets'];
      _customCategoryMonthlyBudgets
        ..clear()
        ..addAll(_parseCategoryBudgets(categoryBudgetsRaw));
      _hasConfiguredBudget =
          totalBudgetConfigured || _customCategoryMonthlyBudgets.isNotEmpty;
    } else {
      _monthlyBudget = 0;
      _hasConfiguredBudget = false;
      _customCategoryMonthlyBudgets.clear();
    }

    await _syncAllCloudDataSafely(notifyOnChange: false);

    _loaded = true;
    notifyListeners();
  }

  Future<void> addTransaction(FinanceTransaction transaction) async {
    _transactions.add(transaction);
    await _persist();
    notifyListeners();
  }

  Future<void> addOrUpdateRecurringTransaction(
    FinanceRecurringTransaction recurring,
  ) async {
    final index = _recurringTransactions.indexWhere(
      (item) => item.id == recurring.id,
    );
    if (index >= 0) {
      _recurringTransactions[index] = recurring;
    } else {
      _recurringTransactions.add(recurring);
    }

    await _persist();
    notifyListeners();
  }

  Future<void> removeRecurringTransaction(String recurringId) async {
    _recurringTransactions.removeWhere((item) => item.id == recurringId);
    await _persist();
    notifyListeners();
  }

  Future<FinanceTransaction?> markRecurringTransactionAsPaid({
    required String recurringId,
  }) async {
    final recurringIndex = _recurringTransactions.indexWhere(
      (item) => item.id == recurringId,
    );
    if (recurringIndex < 0) {
      return null;
    }

    final recurring = _recurringTransactions[recurringIndex];
    final normalizedNow = _normalizeDate(DateTime.now());
    final title = recurring.title.trim().isEmpty
        ? (recurring.type == TransactionType.expense
              ? 'Chi tiêu cho ${recurring.category}'
              : 'Thu nhập từ ${recurring.category}')
        : recurring.title.trim();

    final tx = FinanceTransaction(
      id: 'trx-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      amount: recurring.amount,
      category: recurring.category,
      type: recurring.type,
      createdAt: normalizedNow,
      note: recurring.note,
      includedInReports: true,
    );
    _transactions.add(tx);

    final nextBase = recurring.nextDate.isBefore(normalizedNow)
        ? normalizedNow
        : recurring.nextDate;
    _recurringTransactions[recurringIndex] = recurring.copyWith(
      nextDate: _advanceRecurringDate(nextBase, recurring.frequency),
    );

    await _persist();
    notifyListeners();
    return tx;
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

  Future<bool> removeCustomCategoryById(String categoryId) async {
    final normalizedId = categoryId.trim();
    if (normalizedId.isEmpty) {
      return false;
    }

    final existingIndex = _customCategories.indexWhere(
      (item) => item.id == normalizedId,
    );
    if (existingIndex < 0) {
      return false;
    }

    _customCategories.removeAt(existingIndex);
    await _persist();
    await _categoryCloud?.deleteCategory(normalizedId);
    notifyListeners();
    return true;
  }

  Future<void> updateBudget(double budget) async {
    final safeBudget = budget < 0 ? 0.0 : budget;
    _monthlyBudget = safeBudget;
    _hasConfiguredBudget =
        safeBudget > 0 || _customCategoryMonthlyBudgets.isNotEmpty;
    await _persist();
    await _syncBudgetWithCloud(forceWrite: true);
    notifyListeners();
  }

  Future<void> setCategoryBudget({
    required String category,
    required double monthlyBudget,
  }) async {
    final normalizedCategory = category.trim();
    if (normalizedCategory.isEmpty) {
      return;
    }

    final safeBudget = monthlyBudget < 0 ? 0.0 : monthlyBudget;
    if (safeBudget <= 0) {
      _customCategoryMonthlyBudgets.remove(normalizedCategory);
    } else {
      _customCategoryMonthlyBudgets[normalizedCategory] = safeBudget;
    }

    _hasConfiguredBudget =
        _monthlyBudget > 0 || _customCategoryMonthlyBudgets.isNotEmpty;
    await _persist();
    await _syncBudgetWithCloud(forceWrite: true);
    notifyListeners();
  }

  Future<void> removeCategoryBudget(String category) async {
    final normalizedCategory = category.trim();
    if (normalizedCategory.isEmpty) {
      return;
    }

    _customCategoryMonthlyBudgets.remove(normalizedCategory);
    _hasConfiguredBudget =
        _monthlyBudget > 0 || _customCategoryMonthlyBudgets.isNotEmpty;
    await _persist();
    await _syncBudgetWithCloud(forceWrite: true);
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
      await _storage!.saveList(_storageKey(_categoriesStorageKey), mapped);
    }

    notifyListeners();
  }

  Future<void> _syncTransactionsWithCloud({bool notifyOnChange = true}) async {
    final cloud = _categoryCloud;
    if (cloud == null) {
      return;
    }

    var changed = false;

    if (_transactions.isEmpty) {
      final cloudTransactions = await cloud.loadTransactions();
      if (cloudTransactions.isNotEmpty) {
        _transactions
          ..clear()
          ..addAll(cloudTransactions);
        changed = true;
      }
    }

    if (_recurringTransactions.isEmpty) {
      final cloudRecurring = await cloud.loadRecurringTransactions();
      if (cloudRecurring.isNotEmpty) {
        _recurringTransactions
          ..clear()
          ..addAll(cloudRecurring);
        changed = true;
      }
    }

    if (!changed) {
      return;
    }

    await _persistTransactionsAndRecurringOnly();
    if (notifyOnChange) {
      notifyListeners();
    }
  }

  Future<void> _syncAllCloudData({bool notifyOnChange = true}) async {
    await _syncTransactionsWithCloud(notifyOnChange: false);
    await _syncCategoriesWithCloud();
    await _syncBudgetWithCloud();
    if (notifyOnChange) {
      notifyListeners();
    }
  }

  Future<void> _syncAllCloudDataSafely({bool notifyOnChange = true}) async {
    try {
      await _syncAllCloudData(notifyOnChange: notifyOnChange);
    } catch (_) {
      // Keep local-first UX stable if cloud reads are temporarily denied.
    }
  }

  Future<void> _syncBudgetWithCloud({bool forceWrite = false}) async {
    final cloud = _categoryCloud;
    if (cloud == null) {
      return;
    }

    final localHasAnyBudget =
        _monthlyBudget > 0 || _customCategoryMonthlyBudgets.isNotEmpty;
    final cloudSettings = await cloud.loadBudgetSettings();

    if (cloudSettings == null) {
      if (localHasAnyBudget || forceWrite) {
        await cloud.saveBudgetSettings(
          monthlyBudget: _monthlyBudget,
          budgetConfigured: _monthlyBudget > 0,
          categoryMonthlyBudgets: _customCategoryMonthlyBudgets,
        );
      }
      return;
    }

    final cloudHasAnyBudget = cloudSettings.hasAnyBudget;

    if (!forceWrite && !localHasAnyBudget && cloudHasAnyBudget) {
      _monthlyBudget = cloudSettings.budgetConfigured
          ? cloudSettings.monthlyBudget
          : 0;
      _customCategoryMonthlyBudgets
        ..clear()
        ..addAll(cloudSettings.categoryMonthlyBudgets);
      _hasConfiguredBudget =
          _monthlyBudget > 0 || _customCategoryMonthlyBudgets.isNotEmpty;
      await _persist();
      notifyListeners();
      return;
    }

    final needsWrite =
        forceWrite ||
        (cloudSettings.monthlyBudget - _monthlyBudget).abs() > 0.0001 ||
        cloudSettings.budgetConfigured != (_monthlyBudget > 0) ||
        !_isSameCategoryBudgetMap(
          cloudSettings.categoryMonthlyBudgets,
          _customCategoryMonthlyBudgets,
        );

    if (needsWrite) {
      await cloud.saveBudgetSettings(
        monthlyBudget: _monthlyBudget,
        budgetConfigured: _monthlyBudget > 0,
        categoryMonthlyBudgets: _customCategoryMonthlyBudgets,
      );
    }
  }

  Future<void> _persist() async {
    if (_storage == null) return;
    final mappedTransactions = _transactions.map((e) => e.toMap()).toList();
    final mappedCategories = _customCategories.map((e) => e.toMap()).toList();
    final mappedRecurring = _recurringTransactions
        .map((e) => e.toMap())
        .toList();
    await _storage!.saveList(
      _storageKey(_transactionsStorageKey),
      mappedTransactions,
    );
    await _storage!.saveList(
      _storageKey(_categoriesStorageKey),
      mappedCategories,
    );
    await _storage!.saveList(
      _storageKey(_recurringStorageKey),
      mappedRecurring,
    );
    final hasAnyBudget =
        _monthlyBudget > 0 || _customCategoryMonthlyBudgets.isNotEmpty;
    if (hasAnyBudget) {
      await _storage!.saveList(_storageKey(_settingsStorageKey), [
        {
          'monthlyBudget': _monthlyBudget,
          'budgetConfigured': _monthlyBudget > 0,
          'categoryMonthlyBudgets': _customCategoryMonthlyBudgets,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ]);
    } else {
      await _storage!.saveList(_storageKey(_settingsStorageKey), []);
    }
  }

  Future<void> _persistTransactionsAndRecurringOnly() async {
    if (_storage == null) return;
    final mappedTransactions = _transactions.map((e) => e.toMap()).toList();
    final mappedRecurring = _recurringTransactions
        .map((e) => e.toMap())
        .toList();
    await _storage!.saveList(
      _storageKey(_transactionsStorageKey),
      mappedTransactions,
    );
    await _storage!.saveList(
      _storageKey(_recurringStorageKey),
      mappedRecurring,
    );
  }

  Map<String, double> _parseCategoryBudgets(dynamic raw) {
    final result = <String, double>{};
    if (raw is! Map) {
      return result;
    }

    for (final entry in raw.entries) {
      final key = '${entry.key}'.trim();
      if (key.isEmpty) {
        continue;
      }
      final value = entry.value;
      final amount = value is num
          ? value.toDouble()
          : double.tryParse('${value ?? ''}'.trim());
      if (amount == null || amount <= 0) {
        continue;
      }
      result[key] = amount;
    }
    return result;
  }

  bool _isSameCategoryBudgetMap(
    Map<String, double> left,
    Map<String, double> right,
  ) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      final rightValue = right[entry.key];
      if (rightValue == null) {
        return false;
      }
      if ((entry.value - rightValue).abs() > 0.0001) {
        return false;
      }
    }
    return true;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _advanceRecurringDate(DateTime anchor, String frequency) {
    final normalized = _normalizeDate(anchor);

    DateTime addMonthsKeepingDay(DateTime date, int monthDelta) {
      final targetMonthStart = DateTime(date.year, date.month + monthDelta, 1);
      final maxDay = DateUtils.getDaysInMonth(
        targetMonthStart.year,
        targetMonthStart.month,
      );
      final targetDay = date.day > maxDay ? maxDay : date.day;
      return DateTime(targetMonthStart.year, targetMonthStart.month, targetDay);
    }

    switch (frequency) {
      case 'daily':
        return normalized.add(const Duration(days: 1));
      case 'weekly':
        return normalized.add(const Duration(days: 7));
      case 'monthly':
        return addMonthsKeepingDay(normalized, 1);
      case 'yearly':
        return addMonthsKeepingDay(normalized, 12);
      case 'none':
      default:
        return normalized;
    }
  }
}
