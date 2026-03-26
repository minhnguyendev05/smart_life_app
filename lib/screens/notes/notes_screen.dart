import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../models/note_item.dart';
import '../../providers/notes_provider.dart';
import '../../providers/sync_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_states.dart';
import 'note_edit_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';

  void _openNoteEditor({NoteItem? note}) {
    final isNew = note == null;
    final target = note ??
        NoteItem(
          id: 'note-${DateTime.now().microsecondsSinceEpoch}',
          title: '',
          content: '',
          updatedAt: DateTime.now(),
        );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(note: target, isNew: isNew),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final viewNotes = provider.searchNotes(_query);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text(
                'Ghi chú đa phương tiện',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openNoteEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Tạo mới'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Search bar
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Tìm ghi chú theo tiêu đề/nội dung',
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Empty state
        if (viewNotes.isEmpty)
          const EmptyStateCard(
            title: 'Chưa có ghi chú',
            message: 'Hãy tạo ghi chú mới để bắt đầu.',
            icon: Icons.note_add_outlined,
          ),
        // Note items
        ...viewNotes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.96, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Slidable(
                key: ValueKey(note.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) {
                        provider.removeNote(note.id);
                        context.read<SyncProvider>().queueAction(
                              entity: 'notes',
                              entityId: note.id,
                              payload: {
                                'operation': 'delete',
                                'deleted': true,
                                'noteId': note.id,
                                'deletedAt': DateTime.now().toIso8601String(),
                              },
                            );
                      },
                      icon: Icons.delete_outline,
                      label: 'Xoá',
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ],
                ),
                startActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) async {
                        final syncProvider = context.read<SyncProvider>();
                        await provider.togglePin(note.id);
                        if (!mounted) return;
                        syncProvider.queueAction(
                              entity: 'notes',
                              entityId: note.id,
                              payload: {
                                'operation': 'togglePin',
                                'note': note.copyWith(pinned: !note.pinned).toMap(),
                              },
                            );
                      },
                      icon: note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      label: note.pinned ? 'Bỏ ghim' : 'Ghim',
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ],
                ),
                child: _buildNoteCard(context, note, scheme),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteItem note, ColorScheme scheme) {
    final hasImages = note.imageFiles.isNotEmpty || note.imagePath != null;
    final hasPdfs = note.pdfFiles.isNotEmpty || note.pdfPath != null;
    final imageUrl = note.imageFiles.isNotEmpty
        ? note.imageFiles.first
        : note.imagePath;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: note.isImportant
            ? const BorderSide(color: Colors.amber, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openNoteEditor(note: note),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Thumbnail or icon
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                )
              else
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.sticky_note_2_outlined,
                    color: scheme.primary,
                  ),
                ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (note.pinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(Icons.push_pin, size: 14, color: scheme.tertiary),
                          ),
                        if (note.isImportant)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.star, size: 14, color: Colors.amber),
                          ),
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Không có tiêu đề' : note.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: note.title.isEmpty
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.content.isEmpty ? 'Chưa có nội dung' : note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          Formatters.dayTime(note.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                        if (hasImages) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.image_outlined, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            '${note.imageFiles.isNotEmpty ? note.imageFiles.length : 1}',
                            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                          ),
                        ],
                        if (hasPdfs) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.picture_as_pdf_outlined, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 2),
                          Text(
                            '${note.pdfFiles.isNotEmpty ? note.pdfFiles.length : 1}',
                            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                          ),
                        ],
                        if (note.handwritingImagePath != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.draw_outlined, size: 14, color: scheme.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
