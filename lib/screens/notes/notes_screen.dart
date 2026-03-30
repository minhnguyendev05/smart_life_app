import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';

import '../../models/note_item.dart';
import '../../providers/notes_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/ui_states.dart';
import 'note_edit_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final sync = context.watch<SyncProvider>();
    final filteredNotes = provider.searchNotes(_searchQuery);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, sync),
          _buildSearchBar(),
          Expanded(
            child: filteredNotes.isEmpty
                ? const EmptyStateCard(
                    title: 'Chưa có ghi chú nào',
                    message: 'Hãy nhấn nút + để tạo ghi chú học tập hoặc ghi chú viết tay đầu tiên của bạn.',
                    icon: Icons.note_alt_outlined,
                  )
                : _isGridView
                    ? _buildGridView(filteredNotes)
                    : _buildListView(filteredNotes),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteEditor(context),
        icon: const Icon(Icons.add_task),
        label: const Text('Ghi chú mới'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SyncProvider sync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Text(
            'Ghi chú của tôi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Xem danh sách' : 'Xem lưới',
          ),
          if (sync.isOnline)
            const Tooltip(
              message: 'Đã đồng bộ đám mây',
              child: Icon(Icons.cloud_done_outlined, size: 20, color: Colors.teal),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBar(
        hintText: 'Tìm kiếm tiêu đề hoặc nội dung...',
        onChanged: (v) => setState(() => _searchQuery = v),
        leading: const Icon(Icons.search),
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(
          Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildGridView(List<NoteItem> notes) {
    return MasonryGridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: notes.length,
      itemBuilder: (context, index) => _NoteCard(note: notes[index]),
    );
  }

  Widget _buildListView(List<NoteItem> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _NoteCard(note: notes[index], isList: true),
      ),
    );
  }

  void _openNoteEditor(BuildContext context) {
    final newNote = NoteItem(
      id: 'note-${DateTime.now().millisecondsSinceEpoch}',
      title: '',
      content: '',
      updatedAt: DateTime.now(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(note: newNote, isNew: true),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, this.isList = false});
  final NoteItem note;
  final bool isList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImages = note.imageFiles.isNotEmpty;
    final hasPdf = note.pdfFiles.isNotEmpty;
    final hasHandwriting = note.handwritingImagePath != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: note.isImportant 
              ? theme.colorScheme.primary.withValues(alpha: 0.5) 
              : theme.colorScheme.outlineVariant,
          width: note.isImportant ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteEditScreen(note: note, isNew: false),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImages && !isList)
              Image.network(
                note.imageFiles.first,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (note.pinned)
                        const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                      if (note.pinned) const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          note.title.isEmpty ? 'Không có tiêu đề' : note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isImportant)
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.content.isEmpty ? 'Chưa có nội dung...' : note.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: isList ? 2 : 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hasImages || hasHandwriting)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.image_outlined, size: 14),
                        ),
                      if (hasPdf)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.picture_as_pdf_outlined, size: 14),
                        ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM').format(note.updatedAt),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
