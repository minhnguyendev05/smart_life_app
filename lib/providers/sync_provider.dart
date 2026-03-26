import 'package:flutter/material.dart';
import 'dart:async';

import '../services/cloud_sync_service.dart';
import '../services/local_storage_service.dart';

enum SyncActionStatus { queued, syncing, retryScheduled, conflict, done }
enum MergePolicy { lastWriteWins, clientWins, serverWins, manual }

class SyncAction {
  SyncAction({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.localUpdatedAt,
    this.remoteUpdatedAt,
    this.retryCount = 0,
    this.status = SyncActionStatus.queued,
    this.lastError,
    this.payload = const <String, dynamic>{},
  });

  final String id;
  final String entity;
  final String entityId;
  final DateTime localUpdatedAt;
  final DateTime? remoteUpdatedAt;
  final int retryCount;
  final SyncActionStatus status;
  final String? lastError;
  final Map<String, dynamic> payload;

  SyncAction copyWith({
    int? retryCount,
    SyncActionStatus? status,
    String? lastError,
    Map<String, dynamic>? payload,
  }) {
    return SyncAction(
      id: id,
      entity: entity,
      entityId: entityId,
      localUpdatedAt: localUpdatedAt,
      remoteUpdatedAt: remoteUpdatedAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity': entity,
      'entityId': entityId,
      'localUpdatedAt': localUpdatedAt.toIso8601String(),
      'remoteUpdatedAt': remoteUpdatedAt?.toIso8601String(),
      'retryCount': retryCount,
      'status': status.name,
      'lastError': lastError,
      'payload': payload,
    };
  }

  factory SyncAction.fromMap(Map<dynamic, dynamic> map) {
    return SyncAction(
      id: map['id'] as String? ?? 'sync-unknown',
      entity: map['entity'] as String? ?? 'generic',
      entityId: map['entityId'] as String? ?? 'unknown',
      localUpdatedAt: DateTime.tryParse(map['localUpdatedAt'] as String? ?? '') ?? DateTime.now(),
      remoteUpdatedAt: map['remoteUpdatedAt'] == null
          ? null
          : DateTime.tryParse(map['remoteUpdatedAt'] as String? ?? ''),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      status: SyncActionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SyncActionStatus.queued,
      ),
      lastError: map['lastError'] as String?,
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? const {}),
    );
  }
}

class SyncConflict {
  SyncConflict({
    required this.actionId,
    required this.entity,
    required this.entityId,
    required this.localUpdatedAt,
    required this.remoteUpdatedAt,
  });

  final String actionId;
  final String entity;
  final String entityId;
  final DateTime localUpdatedAt;
  final DateTime remoteUpdatedAt;

  Map<String, dynamic> toMap() {
    return {
      'actionId': actionId,
      'entity': entity,
      'entityId': entityId,
      'localUpdatedAt': localUpdatedAt.toIso8601String(),
      'remoteUpdatedAt': remoteUpdatedAt.toIso8601String(),
    };
  }

  factory SyncConflict.fromMap(Map<dynamic, dynamic> map) {
    return SyncConflict(
      actionId: map['actionId'] as String? ?? 'unknown',
      entity: map['entity'] as String? ?? 'generic',
      entityId: map['entityId'] as String? ?? 'unknown',
      localUpdatedAt: DateTime.tryParse(map['localUpdatedAt'] as String? ?? '') ?? DateTime.now(),
      remoteUpdatedAt: DateTime.tryParse(map['remoteUpdatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class SyncProvider extends ChangeNotifier {
  static const _queueKey = 'sync_queue_v2';
  static const _conflictKey = 'sync_conflicts_v2';
  static const _policyKey = 'sync_merge_policy_v2';

  LocalStorageService? _storage;
  CloudSyncService? _cloud;
  bool _loaded = false;
  bool _isOnline = true;
  DateTime? _lastSyncAt;
  final List<SyncAction> _queue = [];
  final List<SyncConflict> _conflicts = [];
  Timer? _autoSyncTimer;
  bool _syncInProgress = false;
  final Map<String, MergePolicy> _mergePolicies = {
    'study': MergePolicy.clientWins,
    'finance': MergePolicy.lastWriteWins,
    'notes': MergePolicy.manual,
    'generic': MergePolicy.lastWriteWins,
  };

  bool get isOnline => _isOnline;
  DateTime? get lastSyncAt => _lastSyncAt;
  int get pendingActions => _queue.where((e) => e.status != SyncActionStatus.done).length;
  int get conflictCount => _conflicts.length;
  List<SyncAction> get queuedActions => List.unmodifiable(_queue);
  List<SyncConflict> get conflicts => List.unmodifiable(_conflicts);
  Map<String, MergePolicy> get mergePolicies => Map.unmodifiable(_mergePolicies);

  Future<void> attachStorage(LocalStorageService storage) async {
    _storage = storage;
    if (!_loaded) {
      await _load();
    }
  }

  void attachCloud(CloudSyncService cloud) {
    _cloud = cloud;
  }

  void setOnline(bool value) {
    _isOnline = value;
    if (_isOnline) {
      _scheduleAutoSync();
    }
    notifyListeners();
  }

  void setMergePolicy(String entity, MergePolicy policy) {
    _mergePolicies[entity] = policy;
    _persist();
    notifyListeners();
  }

  void queueAction({
    String entity = 'generic',
    String entityId = 'unknown',
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
    Map<String, dynamic> payload = const <String, dynamic>{},
  }) {
    final now = localUpdatedAt ?? DateTime.now();
    final id = 'sync-${now.microsecondsSinceEpoch}';

    final hasConflict = remoteUpdatedAt != null && remoteUpdatedAt.isAfter(now);
    final action = SyncAction(
      id: id,
      entity: entity,
      entityId: entityId,
      localUpdatedAt: now,
      remoteUpdatedAt: remoteUpdatedAt,
      status: hasConflict ? SyncActionStatus.conflict : SyncActionStatus.queued,
      payload: payload,
    );
    _queue.add(action);

    if (hasConflict) {
      _conflicts.add(
        SyncConflict(
          actionId: id,
          entity: entity,
          entityId: entityId,
          localUpdatedAt: now,
          remoteUpdatedAt: remoteUpdatedAt,
        ),
      );
    }

    _persist();
    notifyListeners();
    _scheduleAutoSync();
  }

  void resolveConflict(String actionId, {required bool keepLocal}) {
    final idx = _queue.indexWhere((e) => e.id == actionId);
    if (idx < 0) return;
    _queue[idx] = _queue[idx].copyWith(
      status: keepLocal ? SyncActionStatus.queued : SyncActionStatus.done,
      lastError: keepLocal ? null : 'Skipped local change by user choice',
    );
    _conflicts.removeWhere((e) => e.actionId == actionId);
    _persist();
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (!_isOnline) return;
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
    for (var i = 0; i < _queue.length; i++) {
      var action = _queue[i];
      if (action.status == SyncActionStatus.done) {
        continue;
      }

      if (action.status == SyncActionStatus.conflict) {
        final policy = _mergePolicies[action.entity] ?? _mergePolicies['generic']!;
        if (policy == MergePolicy.manual) {
          continue;
        }
        if (policy == MergePolicy.serverWins) {
          _queue[i] = action.copyWith(
            status: SyncActionStatus.done,
            lastError: 'Server version kept by policy',
          );
          _conflicts.removeWhere((c) => c.actionId == action.id);
          continue;
        }
        if (policy == MergePolicy.clientWins) {
          _queue[i] = action.copyWith(status: SyncActionStatus.queued, lastError: null);
          _conflicts.removeWhere((c) => c.actionId == action.id);
          action = _queue[i];
        }
        if (policy == MergePolicy.lastWriteWins) {
          final remoteAt = action.remoteUpdatedAt;
          final keepLocal = remoteAt == null || action.localUpdatedAt.isAfter(remoteAt);
          _queue[i] = action.copyWith(
            status: keepLocal ? SyncActionStatus.queued : SyncActionStatus.done,
            lastError: keepLocal ? null : 'Server won by last-write-wins',
          );
          _conflicts.removeWhere((c) => c.actionId == action.id);
          action = _queue[i];
          if (!keepLocal) {
            continue;
          }
        }
      }

      if (action.status == SyncActionStatus.done) {
        continue;
      }

      _queue[i] = action.copyWith(status: SyncActionStatus.syncing);
      notifyListeners();
      try {
        if (_cloud != null) {
          await _cloud!.syncAction(
            actionId: action.id,
            entity: action.entity,
            entityId: action.entityId,
            localUpdatedAt: action.localUpdatedAt,
            payload: action.payload,
          );
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 180));
        }

        _queue[i] = action.copyWith(
          status: SyncActionStatus.done,
          lastError: null,
        );
      } catch (e) {
        _queue[i] = action.copyWith(
          retryCount: action.retryCount + 1,
          status: SyncActionStatus.retryScheduled,
          lastError: 'Sync failed: $e',
        );
      }
    }

    for (var i = 0; i < _queue.length; i++) {
      final action = _queue[i];
      if (action.status == SyncActionStatus.retryScheduled && action.retryCount <= 3) {
        _queue[i] = action.copyWith(status: SyncActionStatus.queued);
      }
    }

    _lastSyncAt = DateTime.now();
    await _persist();
    notifyListeners();
    } finally {
      _syncInProgress = false;
    }
  }

  void _scheduleAutoSync() {
    if (!_isOnline || _storage == null) return;
    final hasPending = _queue.any((e) => e.status != SyncActionStatus.done);
    if (!hasPending) return;
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer(const Duration(milliseconds: 800), () {
      unawaited(syncNow());
    });
  }

  Future<void> _load() async {
    if (_storage == null) return;
    final queueRaw = await _storage!.readList(_queueKey);
    final conflictRaw = await _storage!.readList(_conflictKey);
    final policyRaw = await _storage!.readList(_policyKey);

    _queue
      ..clear()
      ..addAll(queueRaw.map(SyncAction.fromMap));
    _conflicts
      ..clear()
      ..addAll(conflictRaw.map(SyncConflict.fromMap));

    if (policyRaw.isNotEmpty) {
      final first = Map<dynamic, dynamic>.from(policyRaw.first);
      for (final entry in first.entries) {
        final entity = '${entry.key}';
        final policyName = '${entry.value}';
        _mergePolicies[entity] = MergePolicy.values.firstWhere(
          (e) => e.name == policyName,
          orElse: () => MergePolicy.lastWriteWins,
        );
      }
    }

    _loaded = true;
    _scheduleAutoSync();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_storage == null) return;
    await _storage!.saveList(
      _queueKey,
      _queue.map((e) => e.toMap()).toList(),
    );
    await _storage!.saveList(
      _conflictKey,
      _conflicts.map((e) => e.toMap()).toList(),
    );
    await _storage!.saveList(
      _policyKey,
      [
        _mergePolicies.map((key, value) => MapEntry(key, value.name)),
      ],
    );
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
