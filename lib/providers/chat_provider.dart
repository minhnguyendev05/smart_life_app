import 'dart:async';

import 'package:flutter/material.dart';

import '../services/firestore_chat_service.dart';

enum ChatRoomRole { owner, admin, member }

class ChatMessage {
  ChatMessage({
    required this.id,
    this.senderId,
    required this.sender,
    required this.text,
    required this.createdAt,
    this.attachmentUrl,
    this.attachmentType,
    this.reactions = const <String, String>{},
    this.seen = false,
  });

  final String id;
  final String? senderId;
  final String sender;
  final String text;
  final DateTime createdAt;
  final String? attachmentUrl;
  final String? attachmentType;
  final Map<String, String> reactions;
  final bool seen;
}

class ChatRoomMember {
  ChatRoomMember({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String displayName;
  final ChatRoomRole role;
}

class ChatRoom {
  ChatRoom({
    required this.id,
    required this.name,
    this.memberCount = 1,
    this.myRole = ChatRoomRole.member,
    this.unreadCount = 0,
    this.lastMessage = '',
    this.lastMessageAt,
  });

  final String id;
  final String name;
  final int memberCount;
  final ChatRoomRole myRole;
  final int unreadCount;
  final String lastMessage;
  final DateTime? lastMessageAt;

  ChatRoom copyWith({
    String? id,
    String? name,
    int? memberCount,
    ChatRoomRole? myRole,
    int? unreadCount,
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      memberCount: memberCount ?? this.memberCount,
      myRole: myRole ?? this.myRole,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

class ChatProvider extends ChangeNotifier {
  FirestoreChatService? _cloud;
  bool _cloudLoaded = false;
  StreamSubscription<List<Map<String, dynamic>>>? _messageSub;
  StreamSubscription<List<String>>? _typingSub;
  StreamSubscription<List<Map<String, dynamic>>>? _roomsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _membersSub;

  String _myUserId = 'local-user';
  String _myDisplayName = 'Bạn';
  bool _isCurrentUserAdmin = false;
  bool _isTyping = false;
  bool _sendingMessage = false;
  bool _loadingMore = false;
  bool _hasMoreMessages = true;
  DateTime? _oldestFetchedAt;
  String? _oldestFetchedId;
  static const int _pageSize = 40;
  final Set<String> _typingUsers = <String>{};
  String _currentRoomId = FirestoreChatService.defaultRoomId;
  String _currentRoomTitle = 'Phòng chung';
  List<ChatRoom> _rooms = [
    ChatRoom(
      id: FirestoreChatService.defaultRoomId,
      name: 'Phòng chung',
      memberCount: 64,
      myRole: ChatRoomRole.owner,
    ),
  ];
  List<ChatRoomMember> _members = [];

  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages {
    final sorted = List<ChatMessage>.from(_messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(sorted);
  }

  bool get peerTyping => _typingUsers.any((name) => name != _myDisplayName);
  bool get isTyping => _isTyping;
  bool get sendingMessage => _sendingMessage;
  bool get loadingMore => _loadingMore;
  bool get hasMoreMessages => _hasMoreMessages;
  String get myUserId => _myUserId;
  String get currentRoomId => _currentRoomId;
  String get currentRoomTitle => _currentRoomTitle;
  List<ChatRoom> get rooms => List.unmodifiable(_rooms);
  List<ChatRoom> get directRooms => List.unmodifiable(
    _rooms.where((room) => room.id.startsWith('dm-')).toList()..sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    }),
  );
  List<ChatRoomMember> get members => List.unmodifiable(_members);
  ChatRoomRole get myRole {
    final mine = _members.where((m) => m.userId == _myUserId);
    if (mine.isEmpty) {
      return ChatRoomRole.member;
    }
    return mine.first.role;
  }

  bool get canManageMembers =>
      myRole == ChatRoomRole.owner || myRole == ChatRoomRole.admin;
  bool get canCreateRoom => _isCurrentUserAdmin;

  bool get _hasAuthenticatedUser {
    final normalized = _myUserId.trim();
    return normalized.isNotEmpty && normalized != 'local-user';
  }

  void setCurrentUser({
    required String userId,
    required String displayName,
    required bool isAdmin,
  }) {
    _myUserId = userId.isEmpty ? 'local-user' : userId;
    _myDisplayName = displayName.isEmpty ? 'Bạn' : displayName;
    _isCurrentUserAdmin = isAdmin;
    notifyListeners();
  }

  Future<void> attachCloud(FirestoreChatService service) async {
    _cloud = service;
    if (!_hasAuthenticatedUser) {
      _roomsSub?.cancel();
      _membersSub?.cancel();
      _messageSub?.cancel();
      _typingSub?.cancel();
      _cloudLoaded = false;
      _typingUsers.clear();
      return;
    }

    try {
      await _cloud!.ensureDefaultRoom();
      await _cloud!.ensureMember(
        roomId: _currentRoomId,
        userId: _myUserId,
        displayName: _myDisplayName,
        role: 'owner',
      );
    } catch (_) {
      return;
    }

    _roomsSub?.cancel();
    _roomsSub = _cloud!
        .streamRoomsForUser(_myUserId)
        .listen(
          (rows) {
            if (rows.isEmpty) return;
            _rooms = rows.map((row) {
              return ChatRoom(
                id: row['id'] as String? ?? 'room',
                name: row['name'] as String? ?? 'Room',
                memberCount: (row['memberCount'] as num?)?.toInt() ?? 0,
                myRole: _parseRole(row['myRole'] as String?),
                unreadCount: (row['unreadCount'] as num?)?.toInt() ?? 0,
                lastMessage: row['lastMessage'] as String? ?? '',
                lastMessageAt: _parseCreatedAtNullable(row['lastMessageAt']),
              );
            }).toList();
            notifyListeners();
          },
          onError: (_, __) {
            // Ignore transient permission or index errors and keep local UI alive.
          },
        );

    await _attachRoomStreams(_currentRoomId);
    if (!_cloudLoaded) {
      await loadFromCloud();
    }
  }

  Future<void> _attachRoomStreams(String roomId) async {
    _typingSub?.cancel();
    _messageSub?.cancel();
    _membersSub?.cancel();

    _messageSub = _cloud!
        .streamMessages(roomId: roomId, limit: _pageSize)
        .listen(
          (records) {
            if (records.isEmpty) return;
            final incoming = records
                .map(
                  (row) => ChatMessage(
                    id:
                        row['id'] as String? ??
                        '${row['createdAt']}-${row['sender']}',
                    senderId: row['senderId'] as String?,
                    sender: row['sender'] as String? ?? 'User',
                    text: row['text'] as String? ?? '',
                    createdAt: _parseCreatedAt(row['createdAt']),
                    attachmentUrl: row['attachmentUrl'] as String?,
                    attachmentType: row['attachmentType'] as String?,
                    reactions: Map<String, String>.from(
                      (row['reactions'] as Map?)?.map(
                            (key, value) => MapEntry('$key', '$value'),
                          ) ??
                          {},
                    ),
                    seen: row['seen'] as bool? ?? false,
                  ),
                )
                .toList();
            _mergeMessages(incoming);
            notifyListeners();
          },
          onError: (_, __) {
            // Keep chat page running even if room permissions change remotely.
          },
        );

    _typingSub = _cloud!.streamTypingUsers(roomId: roomId).listen((names) {
      _typingUsers
        ..clear()
        ..addAll(names);
      notifyListeners();
    }, onError: (_, __) {});

    _membersSub = _cloud!.streamMembers(roomId).listen((rows) {
      _members = rows.map((row) {
        return ChatRoomMember(
          userId: row['userId'] as String? ?? '',
          displayName: row['displayName'] as String? ?? 'User',
          role: _parseRole(row['role'] as String?),
        );
      }).toList();

      for (var i = 0; i < _rooms.length; i++) {
        if (_rooms[i].id == roomId) {
          _rooms[i] = _rooms[i].copyWith(
            myRole: myRole,
            memberCount: _members.length,
          );
        }
      }
      notifyListeners();
    }, onError: (_, __) {});
  }

  Future<void> loadFromCloud() async {
    if (_cloud == null) return;
    final records = await _cloud!.fetchMessagePage(
      roomId: _currentRoomId,
      limit: _pageSize,
    );
    if (records.isEmpty) {
      _cloudLoaded = true;
      _hasMoreMessages = false;
      _oldestFetchedAt = null;
      _oldestFetchedId = null;
      return;
    }

    _messages
      ..clear()
      ..addAll(records.map(_toMessage));
    _updatePaginationState(lastBatchSize: records.length);
    _cloudLoaded = true;
    notifyListeners();
  }

  Future<void> switchRoom(ChatRoom room) async {
    _oldestFetchedAt = null;
    _oldestFetchedId = null;
    _hasMoreMessages = true;
    _currentRoomId = room.id;
    _currentRoomTitle = room.name;
    _messages.clear();
    _typingUsers.clear();
    notifyListeners();

    if (_cloud != null) {
      await _cloud!.ensureMember(
        roomId: room.id,
        userId: _myUserId,
        displayName: _myDisplayName,
      );
      await _attachRoomStreams(room.id);
      await loadFromCloud();
      await markSeen();
    }
  }

  Future<void> createRoom(String roomName) async {
    if (!canCreateRoom) {
      return;
    }
    final normalized = roomName.trim();
    if (normalized.isEmpty) return;
    final id = normalized
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (id.isEmpty) return;

    if (_rooms.any((r) => r.id == id)) {
      final existing = _rooms.firstWhere((r) => r.id == id);
      await switchRoom(existing);
      return;
    }

    await _cloud?.createRoom(
      roomId: id,
      roomName: normalized,
      ownerId: _myUserId,
      ownerDisplayName: _myDisplayName,
    );

    final room = ChatRoom(
      id: id,
      name: normalized,
      memberCount: 1,
      myRole: ChatRoomRole.owner,
    );
    _rooms = [room, ..._rooms.where((r) => r.id != id)];
    notifyListeners();
    await switchRoom(room);
  }

  Future<void> loadMoreMessages() async {
    if (_cloud == null ||
        _loadingMore ||
        !_hasMoreMessages ||
        _oldestFetchedAt == null ||
        _oldestFetchedId == null) {
      return;
    }
    _loadingMore = true;
    notifyListeners();
    try {
      final records = await _cloud!.fetchMessagePage(
        roomId: _currentRoomId,
        limit: _pageSize,
        beforeCreatedAt: _oldestFetchedAt,
        beforeMessageId: _oldestFetchedId,
      );
      if (records.isNotEmpty) {
        _mergeMessages(records.map(_toMessage).toList());
      }
      _updatePaginationState(lastBatchSize: records.length);
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> openDirectMessage({
    required String peerUserId,
    required String peerDisplayName,
  }) async {
    final peerId = peerUserId.trim();
    if (peerId.isEmpty || peerId == _myUserId) {
      return;
    }

    final sorted = <String>[_myUserId, peerId]..sort();
    final roomId = 'dm-${sorted[0]}-${sorted[1]}';
    final normalizedPeerName = peerDisplayName.trim().isEmpty
        ? peerId
        : peerDisplayName.trim();
    final roomName = normalizedPeerName;

    await _cloud?.createRoom(
      roomId: roomId,
      roomName: roomName,
      ownerId: _myUserId,
      ownerDisplayName: _myDisplayName,
    );
    await _cloud?.ensureMember(
      roomId: roomId,
      userId: _myUserId,
      displayName: _myDisplayName,
      role: 'owner',
    );
    await _cloud?.ensureMember(
      roomId: roomId,
      userId: peerId,
      displayName: normalizedPeerName,
      role: 'member',
    );

    final room = ChatRoom(
      id: roomId,
      name: roomName,
      memberCount: 2,
      myRole: ChatRoomRole.owner,
    );

    _rooms = [room, ..._rooms.where((r) => r.id != roomId)];
    notifyListeners();
    await switchRoom(room);
  }

  Future<void> inviteMember({required String displayName}) async {
    if (!canManageMembers) return;
    final normalized = displayName.trim();
    if (normalized.isEmpty) return;

    final userId = normalized
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (userId.isEmpty) return;

    await _cloud?.inviteMember(
      roomId: _currentRoomId,
      userId: userId,
      displayName: normalized,
      actorUserId: _myUserId,
    );
  }

  Future<void> removeMember(String userId) async {
    if (!canManageMembers || userId == _myUserId) return;
    await _cloud?.removeMember(
      roomId: _currentRoomId,
      userId: userId,
      actorUserId: _myUserId,
    );
  }

  Future<void> updateRole(String userId, ChatRoomRole role) async {
    if (!canManageMembers) return;
    await _cloud?.updateMemberRole(
      roomId: _currentRoomId,
      userId: userId,
      role: role.name,
      actorUserId: _myUserId,
    );
  }

  Future<void> send(String text) async {
    await sendRich(text: text, attachmentUrl: null, attachmentType: null);
  }

  Future<void> sendRich({
    required String text,
    required String? attachmentUrl,
    required String? attachmentType,
  }) async {
    if (_sendingMessage) {
      return;
    }
    _sendingMessage = true;
    notifyListeners();
    final message = ChatMessage(
      id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
      senderId: _myUserId,
      sender: _myDisplayName,
      text: text,
      createdAt: DateTime.now(),
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );
    try {
      if (_cloud == null) {
        _messages.add(message);
      } else {
        await _cloud!.sendMessage(
          roomId: _currentRoomId,
          sender: message.sender,
          text: message.text,
          senderId: _myUserId,
          attachmentUrl: attachmentUrl,
          attachmentType: attachmentType,
        );
      }
      await setTyping(false);
      notifyListeners();
    } finally {
      _sendingMessage = false;
      notifyListeners();
    }
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    await _cloud?.setReaction(
      roomId: _currentRoomId,
      messageId: messageId,
      userId: _myUserId,
      emoji: emoji,
    );
  }

  Future<void> setTyping(bool value) async {
    _isTyping = value;
    notifyListeners();
    await _cloud?.setTyping(
      roomId: _currentRoomId,
      userId: _myUserId,
      displayName: _myDisplayName,
      isTyping: value,
    );
  }

  Future<void> markSeen() async {
    await _cloud?.markRoomSeen(roomId: _currentRoomId, myUserId: _myUserId);
  }

  DateTime _parseCreatedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTime? _parseCreatedAtNullable(dynamic value) {
    if (value == null) {
      return null;
    }
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  ChatMessage _toMessage(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id'] as String? ?? '${row['createdAt']}-${row['sender']}',
      senderId: row['senderId'] as String?,
      sender: row['sender'] as String? ?? 'User',
      text: row['text'] as String? ?? '',
      createdAt: _parseCreatedAt(row['createdAt']),
      attachmentUrl: row['attachmentUrl'] as String?,
      attachmentType: row['attachmentType'] as String?,
      reactions: Map<String, String>.from(
        (row['reactions'] as Map?)?.map(
              (key, value) => MapEntry('$key', '$value'),
            ) ??
            {},
      ),
      seen: row['seen'] as bool? ?? false,
    );
  }

  void _mergeMessages(List<ChatMessage> incoming) {
    final merged = <String, ChatMessage>{
      for (final msg in _messages) msg.id: msg,
    };
    for (final msg in incoming) {
      merged[msg.id] = msg;
    }
    final next = merged.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _messages
      ..clear()
      ..addAll(next);
    if (_messages.isNotEmpty) {
      _oldestFetchedAt = _messages.first.createdAt;
      _oldestFetchedId = _messages.first.id;
    }
  }

  void _updatePaginationState({required int lastBatchSize}) {
    _hasMoreMessages = lastBatchSize >= _pageSize;
    if (_messages.isNotEmpty) {
      _oldestFetchedAt = _messages.first.createdAt;
      _oldestFetchedId = _messages.first.id;
    }
  }

  ChatRoomRole _parseRole(String? role) {
    return ChatRoomRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => ChatRoomRole.member,
    );
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _roomsSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }
}
