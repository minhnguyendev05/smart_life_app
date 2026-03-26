import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NoteMediaPreviewScreen extends StatelessWidget {
  const NoteMediaPreviewScreen({
    super.key,
    required this.heroTag,
    required this.imageUrl,
    required this.title,
  });

  final String heroTag;
  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InteractiveViewer(
        minScale: 0.7,
        maxScale: 4,
        child: Center(
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              errorWidget: (context, url, error) =>
                  const Icon(Icons.image_not_supported_outlined, size: 54),
            ),
          ),
        ),
      ),
    );
  }
}
