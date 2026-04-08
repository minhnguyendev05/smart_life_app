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

    await ref.doc(category.id).set({
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
}
