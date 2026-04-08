import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.lastSeenAt,
    this.fcmTokens = const <String>[],
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeenAt;
  final List<String> fcmTokens;

  String get displayNameLower => displayName.toLowerCase();
  String get emailLower => email.toLowerCase();

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    List<String>? fcmTokens,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      fcmTokens: fcmTokens ?? this.fcmTokens,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'emailLower': emailLower,
      'displayName': displayName,
      'displayNameLower': displayNameLower,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'fcmTokens': fcmTokens,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'email': email,
      'emailLower': emailLower,
      'displayName': displayName,
      'displayNameLower': displayNameLower,
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      if (fcmTokens.isNotEmpty) 'fcmTokens': fcmTokens,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is DateTime) {
        return value;
      }
      if (value is Timestamp) {
        return value.toDate();
      }
      return DateTime.tryParse(value.toString());
    }

    final tokenList = (map['fcmTokens'] as List?)
            ?.map((token) => '$token')
            .where((token) => token.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      lastSeenAt: parseDate(map['lastSeenAt']),
      fcmTokens: tokenList,
    );
  }

  factory AppUser.empty() {
    return AppUser(
      id: '',
      email: '',
      displayName: '',
    );
  }
}
