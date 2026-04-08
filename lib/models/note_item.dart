class NoteItem {
  NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    DateTime? createdAt,
    this.imagePath,
    this.pdfPath,
    this.pinned = false,
    this.colorValue,
    this.tags = const [],
    this.imageFiles = const [],
    this.pdfFiles = const [],
    this.handwritingImagePath,
    this.isImportant = false,
    this.password,
  }) : createdAt = createdAt ?? updatedAt;

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imagePath;
  final String? pdfPath;
  final bool pinned;
  final int? colorValue;
  final List<String> tags;
  final List<String> imageFiles;
  final List<String> pdfFiles;
  final String? handwritingImagePath;
  final bool isImportant;
  final String? password;

  bool get isLocked => password != null && password!.isNotEmpty;

  NoteItem copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imagePath,
    String? pdfPath,
    bool? pinned,
    int? colorValue,
    List<String>? tags,
    List<String>? imageFiles,
    List<String>? pdfFiles,
    String? handwritingImagePath,
    bool? isImportant,
    String? password,
  }) {
    return NoteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath ?? this.imagePath,
      pdfPath: pdfPath ?? this.pdfPath,
      pinned: pinned ?? this.pinned,
      colorValue: colorValue ?? this.colorValue,
      tags: tags ?? this.tags,
      imageFiles: imageFiles ?? this.imageFiles,
      pdfFiles: pdfFiles ?? this.pdfFiles,
      handwritingImagePath: handwritingImagePath ?? this.handwritingImagePath,
      isImportant: isImportant ?? this.isImportant,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imagePath': imagePath,
      'pdfPath': pdfPath,
      'pinned': pinned,
      'colorValue': colorValue,
      'tags': tags,
      'imageFiles': imageFiles,
      'pdfFiles': pdfFiles,
      'handwritingImagePath': handwritingImagePath,
      'isImportant': isImportant,
      'password': password,
    };
  }

  factory NoteItem.fromMap(Map<dynamic, dynamic> map) {
    return NoteItem(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.parse(map['updatedAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      imagePath: map['imagePath'] as String?,
      pdfPath: map['pdfPath'] as String?,
      pinned: map['pinned'] as bool? ?? false,
      colorValue: map['colorValue'] as int?,
      tags: (map['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      imageFiles: (map['imageFiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      pdfFiles: (map['pdfFiles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      handwritingImagePath: map['handwritingImagePath'] as String?,
      isImportant: map['isImportant'] as bool? ?? false,
      password: map['password'] as String?,
    );
  }
}
