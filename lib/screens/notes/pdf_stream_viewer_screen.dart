import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfStreamViewerScreen extends StatefulWidget {
  const PdfStreamViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  State<PdfStreamViewerScreen> createState() => _PdfStreamViewerScreenState();
}

class _PdfStreamViewerScreenState extends State<PdfStreamViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _pdfViewerController.zoomLevel = 2,
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.url,
            controller: _pdfViewerController,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() => _isLoading = false);
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('❌ Không thể tải PDF: ${details.description}')),
              );
            },
          ),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Đang tải tài liệu...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
