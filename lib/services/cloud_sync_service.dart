import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_core_service.dart';

class CloudSyncService {
  String _resolveUid(String? userId) {
    final typed = userId?.trim();
    if (typed != null && typed.isNotEmpty) {
      return typed;
    }
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  CollectionReference<Map<String, dynamic>> _actionsRefForUser(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sync_outbox');
  }

  CollectionReference<Map<String, dynamic>> _entityProjectionRef({
    required String uid,
    required String entity,
  }) {
    String collectionName;
    switch (entity) {
      case 'finance':
        collectionName = 'finance_transactions';
        break;
      case 'notes':
        collectionName = 'notes';
        break;
      case 'study':
        collectionName = 'study_tasks';
        break;
      case 'finance_category':
        collectionName = 'finance_categories';
        break;
      case 'finance_recurring':
        collectionName = 'finance_recurring';
        break;
      default:
        collectionName = '${entity}_synced';
        break;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collectionName);
  }

  Future<void> syncAction({
    required String actionId,
    required String entity,
    required String entityId,
    required DateTime localUpdatedAt,
    String? userId,
    required Map<String, dynamic> payload,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }

    final uid = _resolveUid(userId);
    if (uid.isEmpty) {
      return;
    }

    final actionRef = _actionsRefForUser(uid);
    final projectionRef = _entityProjectionRef(uid: uid, entity: entity);
    final opRaw = payload['operation'];
    final operation = opRaw is String && opRaw.trim().isNotEmpty
        ? opRaw.trim()
        : 'upsert';

    await actionRef.doc(actionId).set({
      'actionId': actionId,
      'uid': uid,
      'entity': entity,
      'entityId': entityId,
      'operation': operation,
      'localUpdatedAt': localUpdatedAt.toIso8601String(),
      'payload': payload,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await projectionRef.doc(entityId).set({
      ...payload,
      'uid': uid,
      'entityId': entityId,
      'operation': operation,
      'updatedAt': localUpdatedAt.toIso8601String(),
      'lastSyncActionId': actionId,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
