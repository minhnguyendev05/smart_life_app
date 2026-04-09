import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_core_service.dart';

class FirestoreChatService {
  static const defaultRoomId = 'global';

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
    FirebaseFirestore.instance.collection('chat_rooms');

  DocumentReference<Map<String, dynamic>> _roomDoc(String roomId) =>
    _roomsRef.doc(roomId);

  CollectionReference<Map<String, dynamic>> _membersRef(String roomId) =>
    _roomDoc(roomId).collection('members');

  DocumentReference<Map<String, dynamic>> _memberDoc(String roomId, String userId) =>
    _membersRef(roomId).doc(userId);

  CollectionReference<Map<String, dynamic>> _messagesRef(String roomId) =>
      _roomDoc(roomId).collection('messages');

  DocumentReference<Map<String, dynamic>> _typingRef(String roomId) =>
      _roomDoc(roomId).collection('meta').doc('typing');

  Future<bool> _canManageRoom({
    required String roomId,
    required String actorUserId,
  }) async {
    final actor = await _memberDoc(roomId, actorUserId).get();
    if (!actor.exists) {
      return false;
    }
    final role = actor.data()?['role'] as String? ?? 'member';
    return role == 'owner' || role == 'admin';
  }

  Future<String> _roleOf({
    required String roomId,
    required String userId,
  }) async {
    final snapshot = await _memberDoc(roomId, userId).get();
    if (!snapshot.exists) {
      return 'member';
    }
    return snapshot.data()?['role'] as String? ?? 'member';
  }

  Future<void> ensureDefaultRoom() async {
    if (!FirebaseCoreService.isReady) {
      return;
    }
    final doc = await _roomDoc(defaultRoomId).get();
    if (doc.exists) {
      return;
    }
    await _roomDoc(defaultRoomId).set({
      'name': 'Phòng chung',
      'createdAt': FieldValue.serverTimestamp(),
      'memberCount': 0,
    }, SetOptions(merge: true));
  }

  Future<void> ensureMember({
    required String roomId,
    required String userId,
    required String displayName,
    String role = 'member',
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }

    final room = await _roomDoc(roomId).get();
    if (!room.exists) {
      await _roomDoc(roomId).set({
        'name': roomId,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 0,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await _memberDoc(roomId, userId).set({
      'userId': userId,
      'displayName': displayName,
      'role': role,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final memberSnapshot = await _membersRef(roomId).get();
    await _roomDoc(roomId).set({
      'memberCount': memberSnapshot.docs.length,
    }, SetOptions(merge: true));
  }

  Future<void> createRoom({
    required String roomId,
    required String roomName,
    required String ownerId,
    required String ownerDisplayName,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }

    await _roomDoc(roomId).set({
      'name': roomName,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': ownerId,
      'memberCount': 1,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _memberDoc(roomId, ownerId).set({
      'userId': ownerId,
      'displayName': ownerDisplayName,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> inviteMember({
    required String roomId,
    required String userId,
    required String displayName,
    required String actorUserId,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }
    final allowed = await _canManageRoom(
      roomId: roomId,
      actorUserId: actorUserId,
    );
    if (!allowed) {
      return;
    }

    await _memberDoc(roomId, userId).set({
      'userId': userId,
      'displayName': displayName,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final memberSnapshot = await _membersRef(roomId).get();
    await _roomDoc(roomId).set({
      'memberCount': memberSnapshot.docs.length,
    }, SetOptions(merge: true));
  }

  Future<void> removeMember({
    required String roomId,
    required String userId,
    required String actorUserId,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }
    final allowed = await _canManageRoom(
      roomId: roomId,
      actorUserId: actorUserId,
    );
    if (!allowed) {
      return;
    }

    final actorRole = await _roleOf(roomId: roomId, userId: actorUserId);
    final targetRole = await _roleOf(roomId: roomId, userId: userId);
    if (targetRole == 'owner' && actorRole != 'owner') {
      return;
    }

    await _memberDoc(roomId, userId).delete();
    final memberSnapshot = await _membersRef(roomId).get();
    await _roomDoc(roomId).set({
      'memberCount': memberSnapshot.docs.length,
    }, SetOptions(merge: true));
  }

  Future<void> updateMemberRole({
    required String roomId,
    required String userId,
    required String role,
    required String actorUserId,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }
    final allowed = await _canManageRoom(
      roomId: roomId,
      actorUserId: actorUserId,
    );
    if (!allowed) {
      return;
    }

    final actorRole = await _roleOf(roomId: roomId, userId: actorUserId);
    final targetRole = await _roleOf(roomId: roomId, userId: userId);
    if (actorUserId == userId) {
      return;
    }
    if (actorRole == 'admin' && (targetRole == 'owner' || role == 'owner' || role == 'admin')) {
      return;
    }
    if (actorRole != 'owner' && targetRole == 'owner') {
      return;
    }

    await _memberDoc(roomId, userId).set(
      {
        'role': role,
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<Map<String, dynamic>>> streamRoomsForUser(String userId) {
    if (!FirebaseCoreService.isReady) {
      return const Stream.empty();
    }

    return _roomsRef.orderBy('lastMessageAt', descending: true).snapshots().asyncMap((snap) async {
      final rows = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final row = doc.data();
        final member = await _memberDoc(doc.id, userId).get();
        if (!member.exists) {
          continue;
        }

        var resolvedRoomName = row['name'] as String? ?? doc.id;
        if (doc.id.startsWith('dm-')) {
          final memberSnapshot = await _membersRef(doc.id).limit(10).get();
          for (final memberDoc in memberSnapshot.docs) {
            final memberRow = memberDoc.data();
            final memberUserId = memberRow['userId'] as String? ?? memberDoc.id;
            if (memberUserId == userId) {
              continue;
            }
            final peerDisplayName = (memberRow['displayName'] as String?)?.trim();
            resolvedRoomName =
                (peerDisplayName != null && peerDisplayName.isNotEmpty)
                    ? peerDisplayName
                    : memberUserId;
            break;
          }
        }

        final unread = await _messagesRef(doc.id)
            .where('seen', isEqualTo: false)
            .where('senderId', isNotEqualTo: userId)
            .limit(99)
            .get();

        final role = member.data()?['role'] as String? ?? 'member';
        final lastMessageAtRaw = row['lastMessageAt'];
        final lastMessageAt = lastMessageAtRaw is Timestamp
            ? lastMessageAtRaw.toDate().toIso8601String()
            : null;

        rows.add({
          'id': doc.id,
          'name': resolvedRoomName,
          'memberCount': (row['memberCount'] as num?)?.toInt() ?? 0,
          'createdBy': row['createdBy'] as String?,
          'myRole': role,
          'lastMessage': row['lastMessage'] as String? ?? '',
          'lastMessageAt': lastMessageAt,
          'unreadCount': unread.docs.length,
        });
      }
      return rows;
    });
  }

  Stream<List<Map<String, dynamic>>> streamMembers(String roomId) {
    if (!FirebaseCoreService.isReady) {
      return const Stream.empty();
    }

    return _membersRef(roomId).snapshots().map((snap) {
      return snap.docs.map((doc) {
        final row = doc.data();
        return {
          'userId': row['userId'] as String? ?? doc.id,
          'displayName': row['displayName'] as String? ?? doc.id,
          'role': row['role'] as String? ?? 'member',
        };
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> fetchRecent({
    String roomId = defaultRoomId,
    int limit = 50,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return [];
    }

    final snapshot = await _messagesRef(roomId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .get();

    return snapshot.docs.map((e) {
      final row = e.data();
      final createdAt = row['createdAt'];
      final dateTime = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();

      return {
        'id': e.id,
        'senderId': row['senderId'],
        'sender': row['sender'],
        'text': row['text'],
        'attachmentUrl': row['attachmentUrl'],
        'attachmentType': row['attachmentType'],
        'audioDurationSec': (row['audioDurationSec'] as num?)?.toInt(),
        'reactions': row['reactions'],
        'seen': row['seen'],
        'createdAt': dateTime.toIso8601String(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> fetchMessagePage({
    String roomId = defaultRoomId,
    int limit = 40,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return [];
    }

    var query = _messagesRef(roomId)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);

    if (beforeCreatedAt != null && beforeMessageId != null) {
      query = query.startAfter([
        Timestamp.fromDate(beforeCreatedAt),
        beforeMessageId,
      ]);
    }

    final snapshot = await query.get();
    final rows = snapshot.docs.map((doc) {
      final row = doc.data();
      final ts = row['createdAt'];
      final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
      return {
        'id': doc.id,
        'senderId': row['senderId'] as String? ?? '',
        'sender': row['sender'] as String? ?? 'User',
        'text': row['text'] as String? ?? '',
        'attachmentUrl': row['attachmentUrl'] as String?,
        'attachmentType': row['attachmentType'] as String?,
        'audioDurationSec': (row['audioDurationSec'] as num?)?.toInt(),
        'reactions': row['reactions'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        'seen': row['seen'] as bool? ?? false,
        'createdAt': dt.toIso8601String(),
      };
    }).toList();

    return rows;
  }

  Future<void> sendMessage({
    String roomId = defaultRoomId,
    required String sender,
    required String text,
    required String senderId,
    String? attachmentUrl,
    String? attachmentType,
    int? audioDurationSec,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }

    await _messagesRef(roomId).add({
      'senderId': senderId,
      'sender': sender,
      'text': text,
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'audioDurationSec': audioDurationSec,
      'reactions': <String, dynamic>{},
      'createdAt': Timestamp.now(),
      'seen': false,
    });

    await _roomDoc(roomId).set(
      {
        'lastMessage': text,
        'lastMessageAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setReaction({
    String roomId = defaultRoomId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }
    await _messagesRef(roomId).doc(messageId).set(
      {
        'reactions': {
          userId: emoji,
        },
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<Map<String, dynamic>>> streamMessages({
    String roomId = defaultRoomId,
    int limit = 100,
  }) {
    if (!FirebaseCoreService.isReady) {
      return const Stream.empty();
    }

    return _messagesRef(roomId)
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final row = doc.data();
        final ts = row['createdAt'];
        final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
        return {
          'id': doc.id,
          'senderId': row['senderId'] as String? ?? '',
          'sender': row['sender'] as String? ?? 'User',
          'text': row['text'] as String? ?? '',
          'attachmentUrl': row['attachmentUrl'] as String?,
          'attachmentType': row['attachmentType'] as String?,
          'audioDurationSec': (row['audioDurationSec'] as num?)?.toInt(),
          'reactions': row['reactions'] as Map<String, dynamic>? ?? const <String, dynamic>{},
          'seen': row['seen'] as bool? ?? false,
          'createdAt': dt.toIso8601String(),
        };
      }).toList();
    });
  }

  Future<void> markRoomSeen({
    String roomId = defaultRoomId,
    required String myUserId,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }
    final snapshot = await _messagesRef(roomId).where('seen', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      final senderId = doc.data()['senderId'] as String? ?? '';
      if (senderId != myUserId) {
        batch.update(doc.reference, {'seen': true});
      }
    }
    await batch.commit();
  }

  Future<void> setTyping({
    String roomId = defaultRoomId,
    required String userId,
    required String displayName,
    required bool isTyping,
  }) async {
    if (!FirebaseCoreService.isReady) {
      return;
    }

    await _typingRef(roomId).set(
      {
        userId: {
          'displayName': displayName,
          'typing': isTyping,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<String>> streamTypingUsers({String roomId = defaultRoomId}) {
    if (!FirebaseCoreService.isReady) {
      return const Stream.empty();
    }

    return _typingRef(roomId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) {
        return <String>[];
      }

      final names = <String>[];
      for (final entry in data.entries) {
        final row = entry.value;
        if (row is Map<String, dynamic>) {
          final typing = row['typing'] as bool? ?? false;
          final updatedAt = row['updatedAt'];
          final updatedAtDate = updatedAt is Timestamp ? updatedAt.toDate() : null;
          final isFresh = updatedAtDate != null &&
              DateTime.now().difference(updatedAtDate) <= const Duration(seconds: 20);
          if (typing && isFresh) {
            names.add(row['displayName'] as String? ?? entry.key);
          }
        }
      }
      return names;
    });
  }
}
