import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'firebase_core_service.dart';
import 'local_storage_service.dart';

class AppUserService {
  static const _cacheKey = 'app_users_cache_v1';

  final LocalStorageService _storage = LocalStorageService();
  final Map<String, AppUser> _memoryCache = <String, AppUser>{};
  bool _cacheHydrated = false;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      FirebaseFirestore.instance.collection('app_users');

  Future<void> _hydrateCacheIfNeeded() async {
    if (_cacheHydrated) {
      return;
    }

    final rows = await _storage.readList(_cacheKey);
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final user = AppUser.fromMap(map);
      if (user.id.isNotEmpty) {
        _memoryCache[user.id] = user;
      }
    }
    _cacheHydrated = true;
  }

  Future<void> _persistCache() async {
    final values = _memoryCache.values
        .map((user) => user.toMap())
        .toList(growable: false);
    await _storage.saveList(_cacheKey, values);
  }

  Future<AppUser?> fetchById(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return null;
    }

    await _hydrateCacheIfNeeded();
    final cached = _memoryCache[normalized];

    if (!FirebaseCoreService.isReady) {
      return cached;
    }

    final doc = await _usersRef.doc(normalized).get();
    if (!doc.exists) {
      return cached;
    }

    final user = AppUser.fromMap(<String, dynamic>{
      'id': doc.id,
      ...doc.data() ?? <String, dynamic>{},
    });
    _memoryCache[user.id] = user;
    await _persistCache();
    return user;
  }

  Future<AppUser> ensureUserFromAuth(
    User authUser, {
    String? preferredName,
  }) async {
    await _hydrateCacheIfNeeded();

    final fallbackName =
        authUser.displayName?.trim().isNotEmpty == true ? authUser.displayName!.trim() : null;
    final computedName = preferredName?.trim().isNotEmpty == true
        ? preferredName!.trim()
        : (fallbackName ?? authUser.email?.split('@').first ?? 'User');
    final user = AppUser(
      id: authUser.uid,
      email: authUser.email ?? '',
      displayName: computedName,
      avatarUrl: authUser.photoURL,
      updatedAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );

    if (FirebaseCoreService.isReady) {
      await _usersRef.doc(authUser.uid).set(
        {
          ...user.toFirestoreMap(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      final fresh = await fetchById(authUser.uid);
      if (fresh != null) {
        return fresh;
      }
    }

    _memoryCache[user.id] = user;
    await _persistCache();
    return user;
  }

  Future<AppUser?> updateProfile({
    required String userId,
    required String displayName,
    String? avatarUrl,
  }) async {
    await _hydrateCacheIfNeeded();

    final normalizedId = userId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }

    final cached = _memoryCache[normalizedId];
    final effectiveEmail = cached?.email ?? '';
    final normalizedName = displayName.trim();

    final next = AppUser(
      id: normalizedId,
      email: effectiveEmail,
      displayName: normalizedName,
      avatarUrl: avatarUrl ?? cached?.avatarUrl,
      createdAt: cached?.createdAt,
      updatedAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
      fcmTokens: cached?.fcmTokens ?? const <String>[],
    );

    if (FirebaseCoreService.isReady) {
      await _usersRef.doc(normalizedId).set(next.toFirestoreMap(), SetOptions(merge: true));
      final fresh = await fetchById(normalizedId);
      if (fresh != null) {
        return fresh;
      }
    }

    _memoryCache[normalizedId] = next;
    await _persistCache();
    return next;
  }

  Future<void> saveFcmToken({required String userId, required String token}) async {
    final normalizedUserId = userId.trim();
    final normalizedToken = token.trim();
    if (normalizedUserId.isEmpty || normalizedToken.isEmpty) {
      return;
    }

    await _hydrateCacheIfNeeded();
    final current = _memoryCache[normalizedUserId];
    final tokens = <String>{...?(current?.fcmTokens), normalizedToken}.toList();

    if (FirebaseCoreService.isReady) {
      await _usersRef.doc(normalizedUserId).set(
        {
          'fcmTokens': tokens,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    if (current != null) {
      _memoryCache[normalizedUserId] = current.copyWith(
        fcmTokens: tokens,
        updatedAt: DateTime.now(),
      );
      await _persistCache();
    }
  }

  Future<List<AppUser>> searchUsers({
    required String query,
    String? currentUserId,
    int limit = 15,
  }) async {
    final q = query.trim().toLowerCase();
    await _hydrateCacheIfNeeded();

    if (q.isEmpty) {
      return _memoryCache.values
          .where((u) => u.id != currentUserId)
          .take(limit)
          .toList(growable: false);
    }

    if (!FirebaseCoreService.isReady) {
      return _searchFromCache(q, currentUserId, limit);
    }

    final results = <String, AppUser>{};

    Future<void> queryByField(String field) async {
      final snap = await _usersRef
          .orderBy(field)
          .startAt([q])
          .endAt(['$q\uf8ff'])
          .limit(limit)
          .get();
      for (final doc in snap.docs) {
        final user = AppUser.fromMap(<String, dynamic>{
          'id': doc.id,
          ...doc.data(),
        });
        if (user.id.isNotEmpty && user.id != currentUserId) {
          results[user.id] = user;
          _memoryCache[user.id] = user;
        }
      }
    }

    await Future.wait([
      queryByField('displayNameLower'),
      queryByField('emailLower'),
    ]);

    if (results.isEmpty) {
      return _searchFromCache(q, currentUserId, limit);
    }

    await _persistCache();
    final values = results.values.toList(growable: false)
      ..sort((a, b) => a.displayNameLower.compareTo(b.displayNameLower));
    return values.take(limit).toList(growable: false);
  }

  List<AppUser> _searchFromCache(String q, String? currentUserId, int limit) {
    final hits = _memoryCache.values.where((u) {
      if (u.id == currentUserId) {
        return false;
      }
      return u.displayNameLower.contains(q) || u.emailLower.contains(q);
    }).toList(growable: false)
      ..sort((a, b) => a.displayNameLower.compareTo(b.displayNameLower));
    return hits.take(limit).toList(growable: false);
  }
}
