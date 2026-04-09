import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/finance_category.dart';
import 'firebase_core_service.dart';

class FinanceBudgetSettings {
  const FinanceBudgetSettings({
    required this.monthlyBudget,
    required this.budgetConfigured,
    required this.categoryMonthlyBudgets,
  });

  final double monthlyBudget;
  final bool budgetConfigured;
  final Map<String, double> categoryMonthlyBudgets;

  bool get hasAnyBudget =>
      budgetConfigured || categoryMonthlyBudgets.isNotEmpty;
}

class FirestoreFinanceCategoryService {
  CollectionReference<Map<String, dynamic>>? get _categoriesRef {
    if (!FirebaseCoreService.isReady) {
      return null;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('finance_categories');
  }

  DocumentReference<Map<String, dynamic>>? get _settingsRef {
    if (!FirebaseCoreService.isReady) {
      return null;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('finance_settings')
        .doc('main');
  }

  Future<List<FinanceCategory>> loadCategories() async {
    final ref = _categoriesRef;
    if (ref == null) {
      return const <FinanceCategory>[];
    }

    final snap = await ref.get();
    final rows = snap.docs.map((doc) {
      final row = doc.data();
      return FinanceCategory.fromMap({...row, 'id': doc.id});
    }).toList();

    rows.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return rows;
  }

  Future<void> saveCategory(FinanceCategory category) async {
    final ref = _categoriesRef;
    if (ref == null) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await ref.doc(category.id).set({
      'uid': uid,
      ...category.toMap(),
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) async {
    final ref = _categoriesRef;
    if (ref == null || id.trim().isEmpty) {
      return;
    }
    await ref.doc(id).delete();
  }

  Future<FinanceBudgetSettings?> loadBudgetSettings() async {
    final ref = _settingsRef;
    if (ref == null) {
      return null;
    }
    final doc = await ref.get();
    if (!doc.exists) {
      return null;
    }
    final row = doc.data();

    final monthlyBudget = (row?['monthlyBudget'] as num?)?.toDouble() ?? 0;
    final budgetConfiguredRaw = row?['budgetConfigured'];
    final budgetConfigured = budgetConfiguredRaw is bool
        ? budgetConfiguredRaw
        : monthlyBudget > 0;

    final categoryRaw = row?['categoryMonthlyBudgets'];
    final categoryBudgets = <String, double>{};
    if (categoryRaw is Map) {
      for (final entry in categoryRaw.entries) {
        final key = '${entry.key}'.trim();
        if (key.isEmpty) {
          continue;
        }
        final value = entry.value;
        final amount = value is num ? value.toDouble() : null;
        if (amount == null || amount <= 0) {
          continue;
        }
        categoryBudgets[key] = amount;
      }
    }

    return FinanceBudgetSettings(
      monthlyBudget: budgetConfigured ? monthlyBudget : 0,
      budgetConfigured: budgetConfigured,
      categoryMonthlyBudgets: categoryBudgets,
    );
  }

  Future<void> saveBudgetSettings({
    required double monthlyBudget,
    required bool budgetConfigured,
    required Map<String, double> categoryMonthlyBudgets,
  }) async {
    final ref = _settingsRef;
    if (ref == null) {
      return;
    }

    final sanitizedCategoryBudgets = <String, double>{};
    for (final entry in categoryMonthlyBudgets.entries) {
      final key = entry.key.trim();
      final value = entry.value;
      if (key.isEmpty || value <= 0) {
        continue;
      }
      sanitizedCategoryBudgets[key] = value;
    }

    final hasAnyBudget =
        budgetConfigured || sanitizedCategoryBudgets.isNotEmpty;
    if (!hasAnyBudget) {
      await ref.delete();
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await ref.set({
      'uid': uid,
      'monthlyBudget': budgetConfigured ? monthlyBudget : 0,
      'budgetConfigured': budgetConfigured,
      'categoryMonthlyBudgets': sanitizedCategoryBudgets,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
