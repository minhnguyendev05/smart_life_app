import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/finance_category.dart';
import '../models/finance_recurring_transaction.dart';
import '../models/finance_transaction.dart';
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
  static void _debugLogIgnoredLoadError(
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    assert(() {
      developer.log(
        message,
        name: 'FirestoreFinanceCategoryService',
        error: error,
        stackTrace: stackTrace,
      );
      return true;
    }());
  }

  CollectionReference<Map<String, dynamic>>? get _systemCategoriesRef {
    if (!FirebaseCoreService.isReady) {
      return null;
    }
    return FirebaseFirestore.instance.collection('finance_system_categories');
  }

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

  CollectionReference<Map<String, dynamic>>? get _transactionsRef {
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
        .collection('finance_transactions');
  }

  CollectionReference<Map<String, dynamic>>? get _recurringRef {
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
        .collection('finance_recurring');
  }

  CollectionReference<Map<String, dynamic>>? get _syncEntitiesRef {
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
        .collection('sync_entities');
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

  Future<void> ensureSystemCategories(
    Iterable<FinanceCategory> categories,
  ) async {
    final ref = _systemCategoriesRef;
    if (ref == null) {
      return;
    }

    final normalized = categories
        .map((item) => item.copyWith(isSystem: true))
        .toList(growable: false);
    if (normalized.isEmpty) {
      return;
    }

    final existing = await ref.get();
    final existingIds = existing.docs.map((doc) => doc.id).toSet();
    if (existingIds.length >= normalized.length &&
        normalized.every((item) => existingIds.contains(item.id))) {
      return;
    }

    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    for (final category in normalized) {
      if (existingIds.contains(category.id)) {
        continue;
      }
      batch.set(ref.doc(category.id), {
        ...category.toMap(),
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<FinanceTransaction>> loadTransactions() async {
    final ref = _transactionsRef;
    if (ref == null) {
      return const <FinanceTransaction>[];
    }

    final snap = await ref.get();
    final rows = <FinanceTransaction>[];
    for (final doc in snap.docs) {
      final raw = doc.data();
      if (raw['isDeleted'] == true) {
        continue;
      }

      final map = Map<String, dynamic>.from(raw);
      final id = (map['id'] as String?)?.trim();
      map['id'] = (id == null || id.isEmpty) ? doc.id : id;

      try {
        rows.add(FinanceTransaction.fromMap(map));
      } catch (error, stackTrace) {
        _debugLogIgnoredLoadError(
          'Skipping malformed finance transaction document: ${doc.id}',
          error,
          stackTrace,
        );
      }
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (rows.isNotEmpty) {
      return rows;
    }

    final legacyRef = _syncEntitiesRef;
    if (legacyRef == null) {
      return rows;
    }

    QuerySnapshot<Map<String, dynamic>> legacySnap;
    try {
      legacySnap = await legacyRef.where('entity', isEqualTo: 'finance').get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return rows;
      }
      return rows;
    } catch (error, stackTrace) {
      _debugLogIgnoredLoadError(
        'Failed to load legacy finance transactions.',
        error,
        stackTrace,
      );
      return rows;
    }
    for (final doc in legacySnap.docs) {
      final raw = doc.data();
      if (raw['isDeleted'] == true || raw['operation'] == 'delete') {
        continue;
      }

      Map<String, dynamic>? payload;
      final rawPayload = raw['payload'];
      if (rawPayload is Map && rawPayload['transaction'] is Map) {
        payload = Map<String, dynamic>.from(rawPayload['transaction'] as Map);
      } else if (raw['title'] != null &&
          raw['amount'] != null &&
          raw['category'] != null &&
          raw['type'] != null &&
          raw['createdAt'] != null) {
        payload = Map<String, dynamic>.from(raw);
      }

      if (payload == null) {
        continue;
      }

      final candidateId = (payload['id'] as String?)?.trim();
      final entityId = (raw['entityId'] as String?)?.trim();
      payload['id'] = (candidateId != null && candidateId.isNotEmpty)
          ? candidateId
          : (entityId != null && entityId.isNotEmpty)
          ? entityId
          : doc.id;

      try {
        rows.add(FinanceTransaction.fromMap(payload));
      } catch (error, stackTrace) {
        _debugLogIgnoredLoadError(
          'Skipping malformed legacy finance transaction document: ${doc.id}',
          error,
          stackTrace,
        );
      }
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
  }

  Future<List<FinanceRecurringTransaction>> loadRecurringTransactions() async {
    final ref = _recurringRef;
    if (ref == null) {
      return const <FinanceRecurringTransaction>[];
    }

    final snap = await ref.get();
    final rows = <FinanceRecurringTransaction>[];
    for (final doc in snap.docs) {
      final raw = doc.data();
      if (raw['isDeleted'] == true) {
        continue;
      }

      final map = Map<String, dynamic>.from(raw);
      final id = (map['id'] as String?)?.trim();
      map['id'] = (id == null || id.isEmpty) ? doc.id : id;

      try {
        rows.add(FinanceRecurringTransaction.fromMap(map));
      } catch (error, stackTrace) {
        _debugLogIgnoredLoadError(
          'Skipping malformed recurring transaction document: ${doc.id}',
          error,
          stackTrace,
        );
      }
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (rows.isNotEmpty) {
      return rows;
    }

    final legacyRef = _syncEntitiesRef;
    if (legacyRef == null) {
      return rows;
    }

    QuerySnapshot<Map<String, dynamic>> legacySnap;
    try {
      legacySnap = await legacyRef
          .where('entity', isEqualTo: 'finance_recurring')
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return rows;
      }
      return rows;
    } catch (error, stackTrace) {
      _debugLogIgnoredLoadError(
        'Failed to load legacy recurring transactions.',
        error,
        stackTrace,
      );
      return rows;
    }
    for (final doc in legacySnap.docs) {
      final raw = doc.data();
      if (raw['isDeleted'] == true || raw['operation'] == 'delete') {
        continue;
      }

      Map<String, dynamic>? payload;
      final rawPayload = raw['payload'];
      if (rawPayload is Map && rawPayload['recurring'] is Map) {
        payload = Map<String, dynamic>.from(rawPayload['recurring'] as Map);
      } else if (raw['title'] != null &&
          raw['amount'] != null &&
          raw['category'] != null &&
          raw['type'] != null) {
        payload = Map<String, dynamic>.from(raw);
      }

      if (payload == null) {
        continue;
      }

      final candidateId = (payload['id'] as String?)?.trim();
      final entityId = (raw['entityId'] as String?)?.trim();
      payload['id'] = (candidateId != null && candidateId.isNotEmpty)
          ? candidateId
          : (entityId != null && entityId.isNotEmpty)
          ? entityId
          : doc.id;

      try {
        rows.add(FinanceRecurringTransaction.fromMap(payload));
      } catch (error, stackTrace) {
        _debugLogIgnoredLoadError(
          'Skipping malformed legacy recurring transaction document: ${doc.id}',
          error,
          stackTrace,
        );
      }
    }

    rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return rows;
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
        final amount = value is num
            ? value.toDouble()
            : double.tryParse('${value ?? ''}'.trim());
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
