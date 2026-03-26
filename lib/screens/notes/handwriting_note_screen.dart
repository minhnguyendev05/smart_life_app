import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HandwritingNoteScreen extends StatefulWidget {
  const HandwritingNoteScreen({super.key});

  @override
  State<HandwritingNoteScreen> createState() => _HandwritingNoteScreenState();
}

class _HandwritingNoteScreenState extends State<HandwritingNoteScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<Offset?> _points = <Offset?>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú viet tay'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _points.clear()),
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Xoa net ve',
          ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: 'Luu',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _canvasKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onPanUpdate: (details) {
                final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
                if (box == null) return;
                final local = box.globalToLocal(details.globalPosition);
                setState(() => _points.add(local));
              },
              onPanEnd: (_) => setState(() => _points.add(null)),
              child: CustomPaint(
                painter: _HandwritingPainter(_points),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      Navigator.pop(context);
      return;
    }

    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    if (!mounted) return;
    Navigator.pop<Uint8List?>(context, bytes);
  }
}

class _HandwritingPainter extends CustomPainter {
  _HandwritingPainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) => true;
}
