import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_core_service.dart';

class CloudSyncService {
  CollectionReference<Map<String, dynamic>> get _actionsRef =>
      FirebaseFirestore.instance.collection('sync_actions');

  Future<void> syncAction({
    required String actionId,
    required String entity,
    required String entityId,
    required DateTime localUpdatedAt,
    required Map<String, dynamic> payload,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }

    await _actionsRef.doc(actionId).set(
      {
        'actionId': actionId,
        'entity': entity,
        'entityId': entityId,
        'localUpdatedAt': localUpdatedAt.toIso8601String(),
        'payload': payload,
        'syncedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await FirebaseFirestore.instance
        .collection('${entity}_synced')
        .doc(entityId)
        .set(
      {
        ...payload,
        'entityId': entityId,
        'updatedAt': localUpdatedAt.toIso8601String(),
        'lastSyncActionId': actionId,
        'syncedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
