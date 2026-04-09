import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/finance_category.dart';
import 'firebase_core_service.dart';

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

  Future<double?> loadBudgetSettings() async {
    final ref = _settingsRef;
    if (ref == null) {
      return null;
    }
    final doc = await ref.get();
    if (!doc.exists) {
      return null;
    }
    final row = doc.data();
    return (row?['monthlyBudget'] as num?)?.toDouble();
  }

  Future<void> saveBudgetSettings(double budget) async {
    final ref = _settingsRef;
    if (ref == null) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await ref.set({
      'uid': uid,
      'monthlyBudget': budget,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
