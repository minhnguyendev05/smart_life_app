import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../utils/formatters.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({super.key});

  @override
  State<DirectMessagesScreen> createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn 1-1')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'Bắt đầu DM (nhập tên)',
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
            onSubmitted: (value) async {
              final normalized = value.trim();
              if (normalized.isEmpty) return;
              final userId = normalized
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                  .replaceAll(RegExp(r'-+'), '-')
                  .replaceAll(RegExp(r'^-|-$'), '');
              if (userId.isEmpty) return;
              await provider.openDirectMessage(
                peerUserId: userId,
                peerDisplayName: normalized,
              );
              if (!context.mounted) return;
              Navigator.pop(context, provider.currentRoomId);
            },
          ),
          const SizedBox(height: 16),
          if (provider.directRooms.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.mark_chat_unread_outlined),
                title: Text('Chưa có DM nào'),
                subtitle: Text('Nhập tên ở trên để tạo cuộc trò chuyện 1-1'),
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
