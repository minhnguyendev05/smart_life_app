import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_core_service.dart';

class CloudSyncService {
  static const _maxSyncEntityAuditDocs = 300;

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

  CollectionReference<Map<String, dynamic>> _syncEntitiesRef(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sync_entities');
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
      case 'study':
        collectionName = 'study_tasks';
        break;
      case 'finance_recurring':
        collectionName = 'finance_recurring';
        break;
      default:
        collectionName = 'sync_entities';
        break;
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collectionName);
  }

  bool _isDomainProjectionEntity(String entity) {
    return entity == 'finance' ||
        entity == 'study' ||
        entity == 'finance_recurring';
  }

  Map<String, dynamic>? _normalizedProjectionData({
    required String uid,
    required String entity,
    required String entityId,
    required String operation,
    required DateTime localUpdatedAt,
    required Map<String, dynamic> payload,
  }) {
    Map<String, dynamic>? data;
    switch (entity) {
      case 'finance':
        final raw = payload['transaction'];
        if (raw is Map) {
          data = Map<String, dynamic>.from(raw);
        }
        break;
      case 'study':
        final raw = payload['task'];
        if (raw is Map) {
          data = Map<String, dynamic>.from(raw);
        }
        break;
      case 'finance_recurring':
        final raw = payload['recurring'];
        if (raw is Map) {
          data = Map<String, dynamic>.from(raw);
        }
        break;
      default:
        return {
          'uid': uid,
          'entity': entity,
          'entityId': entityId,
          'operation': operation,
          'payload': payload,
          'updatedAt': localUpdatedAt.toIso8601String(),
        };
    }

    if (operation == 'delete') {
      return {
        'uid': uid,
        'id': entityId,
        'isDeleted': true,
        'deletedAt': localUpdatedAt.toIso8601String(),
        'updatedAt': localUpdatedAt.toIso8601String(),
      };
    }

    if (data == null) {
      return null;
    }

    return {
      ...data,
      'uid': uid,
      'id': entityId,
      'updatedAt': localUpdatedAt.toIso8601String(),
    };
  }

  Future<void> _syncStudyBulkImport({
    required String uid,
    required String actionId,
    required DateTime localUpdatedAt,
    required List<dynamic> tasksRaw,
  }) async {
    if (tasksRaw.isEmpty) {
      return;
    }

    final studyRef = _entityProjectionRef(uid: uid, entity: 'study');
    final fallbackUpdatedAt = localUpdatedAt.toIso8601String();
    final batch = FirebaseFirestore.instance.batch();
    var hasWrite = false;

    for (final item in tasksRaw) {
      if (item is! Map) {
        continue;
      }
      final task = Map<String, dynamic>.from(item);
      final taskId = '${task['id'] ?? ''}'.trim();
      if (taskId.isEmpty) {
        continue;
      }

      final updatedAtRaw = task['updatedAt'];
      final updatedAt = updatedAtRaw is String && updatedAtRaw.trim().isNotEmpty
          ? updatedAtRaw
          : fallbackUpdatedAt;

      batch.set(studyRef.doc(taskId), {
        ...task,
        'uid': uid,
        'id': taskId,
        'updatedAt': updatedAt,
        'operation': 'upsert',
        'lastSyncActionId': actionId,
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      hasWrite = true;
    }

    if (!hasWrite) {
      return;
    }
    await batch.commit();
  }

  Future<void> _pruneSyncEntityAudit(String uid) async {
    try {
      final snap = await _syncEntitiesRef(uid)
          .orderBy('updatedAt', descending: true)
          .limit(_maxSyncEntityAuditDocs + 1)
          .get();

      if (snap.docs.length <= _maxSyncEntityAuditDocs) {
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs.skip(_maxSyncEntityAuditDocs)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      // Cleanup best-effort: never fail sync because pruning is blocked.
    }
  }

  Future<void> _safeCleanupSyncedAction({
    required CollectionReference<Map<String, dynamic>> actionRef,
    required String actionId,
  }) async {
    try {
      await actionRef.doc(actionId).delete();
    } catch (_) {
      // Cleanup best-effort: older rules may still block delete.
    }
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
    final tasksRaw = payload['tasks'];
    final isStudyBulkImport =
        entity == 'study' && operation == 'bulkImport' && tasksRaw is List;

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

    if (isStudyBulkImport) {
      await _syncStudyBulkImport(
        uid: uid,
        actionId: actionId,
        localUpdatedAt: localUpdatedAt,
        tasksRaw: tasksRaw,
      );
      await _safeCleanupSyncedAction(actionRef: actionRef, actionId: actionId);
      return;
    }

    final projectionData = _normalizedProjectionData(
      uid: uid,
      entity: entity,
      entityId: entityId,
      operation: operation,
      localUpdatedAt: localUpdatedAt,
      payload: payload,
    );
    if (projectionData == null) {
      await _safeCleanupSyncedAction(actionRef: actionRef, actionId: actionId);
      return;
    }

    final projectionDocId = _isDomainProjectionEntity(entity)
        ? entityId
        : actionId;

    await projectionRef.doc(projectionDocId).set({
      ...projectionData,
      'entityId': entityId,
      'operation': operation,
      'lastSyncActionId': actionId,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!_isDomainProjectionEntity(entity)) {
      await _pruneSyncEntityAudit(uid);
    }
    await _safeCleanupSyncedAction(actionRef: actionRef, actionId: actionId);
  }
}
