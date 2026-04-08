import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_states.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    context.read<AuthProvider>().clearSearchResults();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nhắn riêng')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'Tìm user',
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 350), () {
                if (!mounted) {
                  return;
                }
                context.read<AuthProvider>().searchUsers(value);
              });
            },
          ),
          const SizedBox(height: 16),
          if (auth.searchingUsers) ...const [
            LoadingSkeletonCard(lines: 2),
            SizedBox(height: 8),
            LoadingSkeletonCard(lines: 2),
          ],
          if (!auth.searchingUsers && auth.searchResults.isNotEmpty) ...[
            const Text(
              'Kết quả tìm kiếm',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...auth.searchResults.map(
              (user) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase(),
                    ),
                  ),
                  title: Text(user.displayName),
                  subtitle: Text(user.email),
                  trailing: const Icon(Icons.send_outlined),
                  onTap: () async {
                    await provider.openDirectMessage(
                      peerUserId: user.id,
                      peerDisplayName: user.displayName,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pop(context, provider.currentRoomId);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (provider.directRooms.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.mark_chat_unread_outlined),
                title: Text('Chưa có ai ở đây cả'),
                subtitle: Text('Nhập tên ở trên để tâm sự thầm kín'),
              ),
            ),
          ...provider.directRooms.map(
            (room) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.alternate_email_outlined),
                ),
                title: Text(room.name),
                subtitle: Text(
                  room.lastMessage.isEmpty
                      ? room.id
                      : '${room.lastMessage}\n${room.lastMessageAt == null ? '' : Formatters.dayTime(room.lastMessageAt!)}',
                ),
                isThreeLine: room.lastMessage.isNotEmpty,
                trailing: room.unreadCount > 0
                    ? Badge(
                        label: Text('${room.unreadCount}'),
                        child: const Icon(Icons.chevron_right),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, room.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
