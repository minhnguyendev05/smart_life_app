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
import '../../services/text_recognition_service.dart';
import 'handwriting_note_screen.dart';
import 'note_media_preview_screen.dart';
import 'pdf_stream_viewer_screen.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, required this.note, required this.isNew});

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
  final _textRecognizer = TextRecognitionService();

  late List<String> _imageFiles;
  late List<String> _pdfFiles;
  String? _handwritingImagePath;
  bool _isImportant = false;
  bool _pinned = false;
  bool _uploading = false;
  String? _password;

  late String _initialTitle;
  late String _initialContent;
  late List<String> _initialImages;
  late List<String> _initialPdfs;
  late String? _initialHandwriting;
  late bool _initialImportant;
  late bool _initialPinned;
  late String? _initialPassword;

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
    _password = widget.note.password;

    _initialTitle = widget.note.title;
    _initialContent = widget.note.content;
    _initialImages = List.from(_imageFiles);
    _initialPdfs = List.from(_pdfFiles);
    _initialHandwriting = _handwritingImagePath;
    _initialImportant = _isImportant;
    _initialPinned = _pinned;
    _initialPassword = _password;

    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _textRecognizer.dispose();
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
    if (_password != _initialPassword) return true;
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
      password: _password,
      imagePath: _imageFiles.isNotEmpty ? _imageFiles.first : null,
      pdfPath: _pdfFiles.isNotEmpty ? _pdfFiles.first : null,
    );
  }

  Future<void> _autoSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (widget.isNew &&
        title.isEmpty &&
        content.isEmpty &&
        _imageFiles.isEmpty &&
        _pdfFiles.isEmpty &&
        _handwritingImagePath == null)
      return;
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
        payload: {'operation': 'upsert', 'note': note.toMap()},
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Lỗi lưu ghi chú: $e')));
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

  Future<void> _deleteNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final provider = context.read<NotesProvider>();
      await provider.removeNote(widget.note.id);
      _isPopping = true;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Lỗi: $e')));
    }
  }

  Future<void> _showPasswordDialog() async {
    final controller = TextEditingController(text: _password);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mật khẩu ghi chú'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nhập mật khẩu (để trống để bỏ khóa)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _password),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result != null)
      setState(() => _password = result.isEmpty ? null : result);
  }

  Future<void> _pickImage() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      if (file.bytes == null) return;
      setState(() => _uploading = true);
      final url = await _uploader.uploadBytes(
        bytes: file.bytes!,
        filename: file.name,
        folder: 'smart_note/images',
      );
      if (url != null) setState(() => _imageFiles.add(url));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      setState(() => _uploading = true);
      final url = await _uploader.uploadBytes(
        bytes: bytes,
        filename: photo.name,
        folder: 'smart_note/images',
      );
      if (url != null) setState(() => _imageFiles.add(url));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _recognizeTextFromImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh tài liệu'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final photo = await _imagePicker.pickImage(source: source);
      if (photo == null) return;

      setState(() => _uploading = true);
      final recognizedText = await _textRecognizer.processImage(photo.path);

      if (recognizedText != null && recognizedText.trim().isNotEmpty) {
        _contentController.text =
            '${_contentController.text}\n\n$recognizedText'.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã trích xuất văn bản thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Không tìm thấy văn bản trong ảnh.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Lỗi OCR: $e')));
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
      if (file.bytes == null) return;
      setState(() => _uploading = true);
      final url = await _uploader.uploadBytes(
        bytes: file.bytes!,
        filename: file.name,
        folder: 'smart_note/documents',
      );
      if (url != null) setState(() => _pdfFiles.add(url));
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
    final url = await _uploader.uploadBytes(
      bytes: bytes,
      filename: 'hw-${DateTime.now().ms}.png',
      folder: 'smart_note/handwriting',
    );
    if (url != null) setState(() => _handwritingImagePath = url);
    if (mounted) setState(() => _uploading = false);
  }

  Widget _buildImageWidget(String path) => CachedNetworkImage(
    imageUrl: path,
    fit: BoxFit.cover,
    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _saveAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isNew ? 'Tạo mới' : 'Chỉnh sửa'),
          actions: [
            if (!widget.isNew)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _deleteNote,
              ),
            IconButton(
              icon: Icon(
                _isImportant ? Icons.star : Icons.star_outline,
                color: _isImportant ? Colors.amber : null,
              ),
              onPressed: () => setState(() => _isImportant = !_isImportant),
              tooltip: 'Quan trọng',
            ),
            IconButton(
              icon: Icon(_password != null ? Icons.lock : Icons.lock_open),
              onPressed: _showPasswordDialog,
            ),
            IconButton(
              icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
              onPressed: () => setState(() => _pinned = !_pinned),
            ),
            IconButton(icon: const Icon(Icons.check), onPressed: _saveAndPop),
          ],
        ),
        body: Column(
          children: [
            if (_uploading) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Tiêu đề',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: 'Nội dung...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    minLines: 5,
                  ),
                  if (_handwritingImagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteMediaPreviewScreen(
                              imageUrl: _handwritingImagePath!,
                              title: 'Bản vẽ tay',
                              heroTag: 'hw',
                            ),
                          ),
                        ),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: scheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildImageWidget(_handwritingImagePath!),
                          ),
                        ),
                      ),
                    ),
                  ..._imageFiles.map(
                    (url) => Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteMediaPreviewScreen(
                              imageUrl: url,
                              title: 'Ảnh đính kèm',
                              heroTag: url,
                            ),
                          ),
                        ),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: scheme.outlineVariant),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildImageWidget(url),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ..._pdfFiles.map(
                    (url) => ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      ),
                      title: const Text('Tài liệu PDF'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PdfStreamViewerScreen(url: url, title: 'Xem PDF'),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _pdfFiles.remove(url)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.document_scanner),
                    tooltip: 'Quét chữ từ ảnh',
                    onPressed: _recognizeTextFromImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _takePhoto,
                  ),
                  IconButton(
                    icon: const Icon(Icons.draw),
                    onPressed: _openHandwriting,
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: _pickPdf,
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

extension on DateTime {
  int get ms => millisecondsSinceEpoch;
}
