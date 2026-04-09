import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/note_item.dart';
import 'firebase_core_service.dart';

class FirestoreNoteService {
  CollectionReference<Map<String, dynamic>>? get _notesRef {
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
        .collection('notes');
  }

  Future<List<NoteItem>> loadNotes() async {
    final ref = _notesRef;
    if (ref == null) {
      return [];
    }

    final snap = await ref.orderBy('updatedAt', descending: true).get();
    return snap.docs.map((doc) {
      final row = doc.data();
      final normalized = {...row, 'id': doc.id};
      return NoteItem.fromMap(normalized);
    }).toList();
  }

  Stream<List<NoteItem>> notesStream() {
    final ref = _notesRef;
    if (ref == null) {
      return Stream.value(const <NoteItem>[]);
    }
    return ref.orderBy('updatedAt', descending: true).snapshots().map((snap) {
      return snap.docs.map((doc) {
        final row = doc.data();
        return NoteItem.fromMap({...row, 'id': doc.id});
      }).toList();
    });
  }

  Future<void> saveNote(NoteItem note) async {
    final ref = _notesRef;
    if (ref == null) {
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    await ref.doc(note.id).set({
      ...note.toMap(),
      'uid': uid,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteNote(String id) async {
    final ref = _notesRef;
    if (ref == null) {
      return;
    }
    await ref.doc(id).delete();
  }
}
