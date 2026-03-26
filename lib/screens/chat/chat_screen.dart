import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/cloudinary_upload_service.dart';
import '../../utils/formatters.dart';
import 'direct_messages_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.initialRoomId,
    this.initialDraft,
    this.title,
  });

  final String? initialRoomId;
  final String? initialDraft;
  final String? title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _uploader = CloudinaryUploadService();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.initialDraft ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      chat.setCurrentUser(
        userId: auth.profile.id,
        displayName: auth.profile.email.isEmpty ? 'Bạn' : auth.profile.email,
        isAdmin: auth.isAdmin,
      );
      if (widget.initialRoomId != null) {
        ChatRoom? room;
        for (final candidate in chat.rooms) {
          if (candidate.id == widget.initialRoomId) {
            room = candidate;
            break;
          }
        }
        if (room != null) {
          chat.switchRoom(room);
        } else {
          chat.createRoom(widget.initialRoomId!);
        }
      }
      chat.markSeen();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= 100) {
        context.read<ChatProvider>().loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    context.read<ChatProvider>().setTyping(false);
    _scrollController.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? provider.currentRoomTitle),
        actions: [
          IconButton(
            onPressed: _openDirectMessages,
            icon: const Icon(Icons.alternate_email_outlined),
            tooltip: 'Tin nhắn 1-1',
          ),
          IconButton(
            onPressed: _showRoomMembersSheet,
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: 'Quản trị phòng',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'new-room') {
                _showCreateRoomSheet();
                return;
              }
              ChatRoom? selected;
              for (final room in provider.rooms) {
                if (room.id == value) {
                  selected = room;
                  break;
                }
              }
              if (selected != null) {
                provider.switchRoom(selected);
              }
            },
            itemBuilder: (ctx) {
              final items = provider.rooms.map<PopupMenuEntry<String>>((room) {
                return PopupMenuItem(
                  value: room.id,
                  child: Row(
                    children: [
                      Expanded(child: Text('${room.name} (${room.memberCount})')),
                      if (room.unreadCount > 0)
                        Badge(
                          label: Text('${room.unreadCount}'),
                          child: const SizedBox(width: 12, height: 12),
                        ),
                    ],
                  ),
                );
              }).toList();
              items.add(const PopupMenuDivider());
              items.add(const PopupMenuItem(value: 'new-room', child: Text('Tạo phòng mới')));
              return items;
            },
            icon: const Icon(Icons.groups_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                final msg = provider.messages[index];
                final mine = msg.senderId == provider.myUserId;
                return Align(
                  alignment:
                      mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () => _showReactionMenu(msg.id),
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: 8,
                        top: index == 0 && provider.loadingMore ? 8 : 0,
                      ),
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: mine
                            ? Colors.teal.withValues(alpha: 0.18)
                            : Colors.grey.withValues(alpha: 0.18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0 && provider.loadingMore)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          Text(
                            msg.sender,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(msg.text),
                          if (msg.attachmentUrl != null) ...[
                            const SizedBox(height: 6),
                            if (msg.attachmentType == 'image')
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 140,
                                  height: 100,
                                  child: CachedNetworkImage(
                                    imageUrl: msg.attachmentUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined),
                                  ),
                                ),
                              )
                            else
                              Text(
                                'File đính kèm: ${msg.attachmentUrl}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                          if (msg.reactions.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: msg.reactions.values
                                  .map((emoji) => Text(emoji))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            Formatters.dayTime(msg.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (mine)
                            Text(
                              msg.seen ? 'Đã xem' : 'Đã gửi',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (provider.peerTyping)
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Đang gõ...'),
              ),
            ),
          if (!provider.hasMoreMessages && provider.messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                'Bạn đã xem đến tin nhắn đầu tiên.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (value) {
                        provider.setTyping(value.trim().isNotEmpty);
                      },
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: provider.sendingMessage ? null : _sendAttachment,
                    icon: const Icon(Icons.attach_file),
                  ),
                  IconButton(
                    onPressed: provider.sendingMessage
                        ? null
                        : () {
                      final text = _ctrl.text.trim();
                      if (text.isEmpty) return;
                      context.read<ChatProvider>().send(text);
                      context.read<ChatProvider>().markSeen();
                      _ctrl.clear();
                    },
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendAttachment() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final ext = (file.extension ?? '').toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
    final folder = isImage ? 'smart_chat/images' : 'smart_chat/files';
    final url = await _uploader.uploadBytes(
      bytes: bytes,
      filename: file.name,
      folder: folder,
    );

    if (!mounted) return;

    await context.read<ChatProvider>().sendRich(
          text: isImage ? '[Ảnh]' : '[Tệp] ${file.name}',
          attachmentUrl: url,
          attachmentType: isImage ? 'image' : 'file',
        );
  }

  Future<void> _showReactionMenu(String messageId) async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        final emojis = ['👍', '❤️', '🔥', '😂', '👏'];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            children: emojis.map((e) {
              return ActionChip(
                label: Text(e, style: const TextStyle(fontSize: 20)),
                onPressed: () => Navigator.pop(ctx, e),
              );
            }).toList(),
          ),
        );
      },
    );

    if (emoji == null) return;
    if (!mounted) return;
    await context.read<ChatProvider>().reactToMessage(messageId, emoji);
  }

  Future<void> _showCreateRoomSheet() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ tài khoản admin mới tạo được phòng công khai.')),
      );
      return;
    }

    final ctrl = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: 'Tên phòng'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<ChatProvider>().createRoom(ctrl.text);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Tạo phòng'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDirectMessages() async {
    final roomId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const DirectMessagesScreen()),
    );
    if (!mounted || roomId == null) return;

    final chat = context.read<ChatProvider>();
    ChatRoom? selected;
    for (final room in chat.rooms) {
      if (room.id == roomId) {
        selected = room;
        break;
      }
    }
    if (selected != null) {
      await chat.switchRoom(selected);
    }
  }

  Future<void> _showRoomMembersSheet() async {
    final provider = context.read<ChatProvider>();
    final inviteCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final members = provider.members;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thành viên ${provider.currentRoomTitle}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (provider.canManageMembers)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: inviteCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Mời thành viên (tên)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            await provider.inviteMember(displayName: inviteCtrl.text);
                            inviteCtrl.clear();
                            setModalState(() {});
                          },
                          child: const Text('Mời'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final m = members[index];
                        return ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(m.displayName),
                          subtitle: Text(m.userId),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButton<ChatRoomRole>(
                                value: m.role,
                                items: ChatRoomRole.values
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: provider.canManageMembers && m.userId != provider.myUserId
                                    ? (role) async {
                                        if (role == null) return;
                                        await provider.updateRole(m.userId, role);
                                        setModalState(() {});
                                      }
                                    : null,
                              ),
                              IconButton(
                                onPressed: provider.canManageMembers && m.userId != provider.myUserId
                                    ? () async {
                                        await provider.removeMember(m.userId);
                                        setModalState(() {});
                                      }
                                    : null,
                                icon: const Icon(Icons.person_remove_outlined),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
