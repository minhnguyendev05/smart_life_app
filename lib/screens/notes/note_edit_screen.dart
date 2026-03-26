import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/note_item.dart';
import '../../providers/notes_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/cloudinary_upload_service.dart';
import '../../services/pdf_optimization_service.dart';
import 'handwriting_note_screen.dart';
import 'note_media_preview_screen.dart';
import 'pdf_stream_viewer_screen.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({
    super.key,
    required this.note,
    required this.isNew,
  });

  final NoteItem note;
  final bool isNew;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;
  bool _isPopping = false;
  final _imagePicker = ImagePicker();
  final _uploader = CloudinaryUploadService();
  final _pdfOptimizer = PdfOptimizationService();

  late List<String> _imageFiles;
  late List<String> _pdfFiles;
  String? _handwritingImagePath;
  bool _isImportant = false;
  bool _pinned = false;
  bool _uploading = false;

  // Track initial state
  late String _initialTitle;
  late String _initialContent;
  late List<String> _initialImages;
  late List<String> _initialPdfs;
  late String? _initialHandwriting;
  late bool _initialImportant;
  late bool _initialPinned;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _imageFiles = List.from(widget.note.imageFiles);
    _pdfFiles = List.from(widget.note.pdfFiles);
    _handwritingImagePath = widget.note.handwritingImagePath;
    _isImportant = widget.note.isImportant;
    _pinned = widget.note.pinned;

    // Legacy: migrate single imagePath/pdfPath to lists
    if (widget.note.imagePath != null && !_imageFiles.contains(widget.note.imagePath)) {
      _imageFiles.insert(0, widget.note.imagePath!);
    }
    if (widget.note.pdfPath != null && !_pdfFiles.contains(widget.note.pdfPath)) {
      _pdfFiles.insert(0, widget.note.pdfPath!);
    }

    _initialTitle = widget.note.title;
    _initialContent = widget.note.content;
    _initialImages = List.from(_imageFiles);
    _initialPdfs = List.from(_pdfFiles);
    _initialHandwriting = _handwritingImagePath;
    _initialImportant = _isImportant;
    _initialPinned = _pinned;

    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    if (_titleController.text.trim() != _initialTitle) return true;
    if (_contentController.text.trim() != _initialContent) return true;
    if (_imageFiles.length != _initialImages.length) return true;
    for (int i = 0; i < _imageFiles.length; i++) {
      if (_imageFiles[i] != _initialImages[i]) return true;
    }
    if (_pdfFiles.length != _initialPdfs.length) return true;
    for (int i = 0; i < _pdfFiles.length; i++) {
      if (_pdfFiles[i] != _initialPdfs[i]) return true;
    }
    if (_handwritingImagePath != _initialHandwriting) return true;
    if (_isImportant != _initialImportant) return true;
    if (_pinned != _initialPinned) return true;
    return false;
  }

  NoteItem _buildNote() {
    return widget.note.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      updatedAt: DateTime.now(),
      imageFiles: _imageFiles,
      pdfFiles: _pdfFiles,
      handwritingImagePath: _handwritingImagePath,
      isImportant: _isImportant,
      pinned: _pinned,
      imagePath: _imageFiles.isNotEmpty ? _imageFiles.first : null,
      pdfPath: _pdfFiles.isNotEmpty ? _pdfFiles.first : null,
    );
  }

  Future<void> _autoSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (widget.isNew && title.isEmpty && content.isEmpty && _imageFiles.isEmpty && _pdfFiles.isEmpty && _handwritingImagePath == null) {
      return;
    }

    if (!_hasChanges()) return;

    final note = _buildNote();
    try {
      setState(() => _isSaving = true);
      final provider = context.read<NotesProvider>();
      final syncProvider = context.read<SyncProvider>();

      if (widget.isNew) {
        await provider.addNote(note);
      } else {
        await provider.updateNote(note);
      }
      syncProvider.queueAction(
        entity: 'notes',
        entityId: note.id,
        payload: {
          'operation': 'upsert',
          'note': note.toMap(),
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi lưu ghi chú: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveAndPop() async {
    if (_isPopping) return;
    _isPopping = true;
    try {
      await _autoSave();
      if (mounted) Navigator.pop(context);
    } finally {
      _isPopping = false;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _uploading = true);
      final url = await _uploader.uploadBytes(
        bytes: bytes,
        filename: file.name,
        folder: 'smart_note/images',
      );
      if (url != null) {
        setState(() => _imageFiles.add(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi tải ảnh: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      setState(() => _uploading = true);
      final url = await _uploader.uploadBytes(
        bytes: bytes,
        filename: photo.name,
        folder: 'smart_note/images',
      );
      if (url != null) {
        setState(() => _imageFiles.add(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi chụp ảnh: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickPdf() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _uploading = true);
      final compressedBytes = await _pdfOptimizer.compressPdf(
        bytes: bytes,
        filename: file.name,
      );
      final url = await _uploader.uploadBytes(
        bytes: compressedBytes,
        filename: file.name,
        folder: 'smart_note/documents',
      );
      if (url != null) {
        setState(() => _pdfFiles.add(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi tải PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openHandwriting() async {
    final bytes = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HandwritingNoteScreen()),
    );
    if (bytes == null || bytes is! List<int>) return;

    setState(() => _uploading = true);
    try {
      final url = await _uploader.uploadBytes(
        bytes: bytes,
        filename: 'handwriting-${DateTime.now().millisecondsSinceEpoch}.png',
        folder: 'smart_note/handwriting',
      );
      if (url != null) {
        setState(() => _handwritingImagePath = url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi lưu viết tay: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildImageWidget(String imagePath) {
    final uri = Uri.tryParse(imagePath);
    final isRemote = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (isRemote) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            const Icon(Icons.image_not_supported_outlined),
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return const Icon(Icons.image_not_supported_outlined);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _isSaving ? null : _saveAndPop,
          ),
          title: Text(widget.isNew ? 'Tạo ghi chú' : 'Soạn ghi chú'),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
              tooltip: _pinned ? 'Bỏ ghim' : 'Ghim ghi chú',
              onPressed: () => setState(() => _pinned = !_pinned),
            ),
            IconButton(
              icon: Icon(
                _isImportant ? Icons.star : Icons.star_outline,
                color: _isImportant ? Colors.amber : null,
              ),
              tooltip: _isImportant ? 'Bỏ đánh dấu quan trọng' : 'Đánh dấu quan trọng',
              onPressed: () => setState(() => _isImportant = !_isImportant),
            ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Lưu',
                onPressed: _saveAndPop,
              ),
          ],
        ),
        body: Column(
          children: [
            if (_uploading)
              const LinearProgressIndicator(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tiêu đề',
                          hintStyle: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      Divider(height: 1, color: scheme.outlineVariant),
                      const SizedBox(height: 12),
                      // Content
                      TextField(
                        controller: _contentController,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: scheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập nội dung ghi chú...',
                          hintStyle: TextStyle(
                            color: scheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        minLines: 8,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      // Handwriting preview
                      if (_handwritingImagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: scheme.outline),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      const Text('📝 Viết tay'),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: () {
                                          setState(() => _handwritingImagePath = null);
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 150,
                                  width: double.infinity,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                    child: _buildImageWidget(_handwritingImagePath!),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Image gallery
                      if (_imageFiles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imageFiles.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => NoteMediaPreviewScreen(
                                                heroTag: 'note-img-$index',
                                                imageUrl: _imageFiles[index],
                                                title: 'Ảnh ${index + 1}',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: scheme.outline),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          width: 100,
                                          height: 100,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(9),
                                            child: _buildImageWidget(_imageFiles[index]),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          onPressed: () {
                                            setState(() => _imageFiles.removeAt(index));
                                          },
                                          style: IconButton.styleFrom(
                                            backgroundColor: scheme.error,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(24, 24),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      // PDF list
                      if (_pdfFiles.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: scheme.outline),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    '📄 PDF (${_pdfFiles.length})',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                ..._pdfFiles.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final url = entry.value;
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.picture_as_pdf_outlined),
                                    title: Text(
                                      'PDF ${index + 1}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.open_in_new, size: 18),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => PdfStreamViewerScreen(
                                                  url: url,
                                                  title: 'PDF ${index + 1}',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 18),
                                          onPressed: () {
                                            setState(() => _pdfFiles.removeAt(index));
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom action bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant),
                ),
                color: scheme.surface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Tooltip(
                      message: 'Thêm ảnh từ thư viện',
                      child: IconButton.filledTonal(
                        onPressed: _uploading ? null : _pickImage,
                        icon: const Icon(Icons.image_outlined),
                      ),
                    ),
                    Tooltip(
                      message: 'Chụp ảnh',
                      child: IconButton.filledTonal(
                        onPressed: _uploading ? null : _takePhoto,
                        icon: const Icon(Icons.camera_alt_outlined),
                      ),
                    ),
                    Tooltip(
                      message: 'Viết tay',
                      child: IconButton.filledTonal(
                        onPressed: _uploading ? null : _openHandwriting,
                        icon: const Icon(Icons.draw_outlined),
                      ),
                    ),
                    Tooltip(
                      message: 'Thêm PDF',
                      child: IconButton.filledTonal(
                        onPressed: _uploading ? null : _pickPdf,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
