import 'package:flutter/material.dart';
import 'dart:async';

import '../models/note_item.dart';
import '../services/firestore_note_service.dart';
import '../services/local_storage_service.dart';

class NotesProvider extends ChangeNotifier {
  static const _storageKey = 'note_items';

  LocalStorageService? _storage;
  FirestoreNoteService? _cloud;
  StreamSubscription<List<NoteItem>>? _notesSub;
  final List<NoteItem> _notes = [];
  bool _loaded = false;

  List<NoteItem> get notes {
    final sorted = List<NoteItem>.from(_notes)
      ..sort((a, b) {
        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return List.unmodifiable(sorted);
  }

  Future<void> attachStorage(LocalStorageService storage) async {
    _storage = storage;
    if (!_loaded) {
      await load();
    }
  }

  void attachCloud(FirestoreNoteService cloud) {
    _cloud = cloud;
    _notesSub?.cancel();
    _notesSub = _cloud!.notesStream().listen((cloudNotes) async {
      if (cloudNotes.isEmpty) {
        if (_notes.isNotEmpty) {
          for (final item in _notes) {
            await _cloud?.saveNote(item);
          }
        }
        return;
      }

      _notes
        ..clear()
        ..addAll(cloudNotes);
      await _persist();
      notifyListeners();
    });
  }

  Future<void> load() async {
    if (_storage == null) return;
    final raw = await _storage!.readList(_storageKey);
    _notes
      ..clear()
      ..addAll(raw.map(NoteItem.fromMap));
    if (_notes.isEmpty) {
      final cloudNotes = await _cloud?.loadNotes() ?? [];
      if (cloudNotes.isNotEmpty) {
        _notes.addAll(cloudNotes);
      }
    } else if (_cloud != null) {
      final cloudNotes = await _cloud!.loadNotes();
      if (cloudNotes.isEmpty) {
        for (final item in _notes) {
          await _cloud?.saveNote(item);
        }
      }
    }

    if (_notes.isNotEmpty) {
      await _persist();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> addNote(NoteItem note) async {
    final existing = _notes.indexWhere((e) => e.id == note.id);
    if (existing >= 0) {
      _notes[existing] = note;
    } else {
      _notes.add(note);
    }
    await _persist();
    await _cloud?.saveNote(note);
    notifyListeners();
  }

  Future<void> removeNote(String id) async {
    _notes.removeWhere((e) => e.id == id);
    await _persist();
    await _cloud?.deleteNote(id);
    notifyListeners();
  }

  Future<void> updateNote(NoteItem updated) async {
    final index = _notes.indexWhere((e) => e.id == updated.id);
    if (index < 0) return;
    _notes[index] = updated;
    await _persist();
    await _cloud?.saveNote(updated);
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    final index = _notes.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final current = _notes[index];
    _notes[index] = current.copyWith(
      pinned: !current.pinned,
      updatedAt: DateTime.now(),
    );
    await _persist();
    await _cloud?.saveNote(_notes[index]);
    notifyListeners();
  }

  List<NoteItem> searchNotes(String query) {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) {
      return notes;
    }
    return notes.where((e) {
      return e.title.toLowerCase().contains(key) ||
          e.content.toLowerCase().contains(key);
    }).toList();
  }

  Future<void> _persist() async {
    if (_storage == null) return;
    final mapped = _notes.map((e) => e.toMap()).toList();
    await _storage!.saveList(_storageKey, mapped);
  }

  @override
  void dispose() {
    _notesSub?.cancel();
    super.dispose();
  }
}
