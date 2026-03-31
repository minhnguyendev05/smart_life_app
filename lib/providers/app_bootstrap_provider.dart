import 'package:flutter/material.dart';

import 'finance_provider.dart';
import 'notes_provider.dart';
import 'study_provider.dart';

class AppBootstrapProvider extends ChangeNotifier {
  StudyProvider? _study;
  FinanceProvider? _finance;
  NotesProvider? _notes;

  bool _initialized = false;
  bool get initialized => _initialized;

  void bind(
    StudyProvider study,
    FinanceProvider finance,
    NotesProvider notes,
  ) {
    _study = study;
    _finance = finance;
    _notes = notes;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_initialized) {
      return;
    }
    try {
      await _study?.load();
      await _finance?.load();
      await _notes?.load();
    } catch (_) {
      // Keep app usable even if a data source fails to load.
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }
}
