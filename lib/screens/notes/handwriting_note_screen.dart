import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DrawingPoint {
  final Offset? offset;
  final Color color;
  final double width;

  DrawingPoint({this.offset, required this.color, required this.width});
}

class HandwritingNoteScreen extends StatefulWidget {
  const HandwritingNoteScreen({super.key});

  @override
  State<HandwritingNoteScreen> createState() => _HandwritingNoteScreenState();
}

class _HandwritingNoteScreenState extends State<HandwritingNoteScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<DrawingPoint?> _points = [];
  
  Color _selectedColor = Colors.black;
  double _strokeWidth = 3.0;

  final List<Color> _colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú viết tay'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _points.clear()),
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Xóa tất cả',
          ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: 'Lưu',
          ),
        ],
      ),
      body: Column(
        children: [
          // Toolbar cho màu sắc và độ dày
          _buildToolbar(),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RepaintBoundary(
                key: _canvasKey,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        _points.add(DrawingPoint(
                          offset: renderBox.globalToLocal(details.globalPosition),
                          color: _selectedColor,
                          width: _strokeWidth,
                        ));
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        RenderBox renderBox = context.findRenderObject() as RenderBox;
                        _points.add(DrawingPoint(
                          offset: renderBox.globalToLocal(details.globalPosition),
                          color: _selectedColor,
                          width: _strokeWidth,
                        ));
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        _points.add(null);
                      });
                    },
                    child: CustomPaint(
                      painter: _HandwritingPainter(_points),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Column(
        children: [
          // Chọn màu
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color 
                            ? Colors.grey[400]! 
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: _selectedColor == color 
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 16),
          // Chọn độ dày
          Row(
            children: [
              const Icon(Icons.brush, size: 18),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1.0,
                  max: 10.0,
                  onChanged: (v) => setState(() => _strokeWidth = v),
                ),
              ),
              Text('${_strokeWidth.toInt()}px', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || _points.isEmpty) {
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

  final List<DrawingPoint?> points;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final paint = Paint()
          ..color = points[i]!.color
          ..strokeWidth = points[i]!.width
          ..strokeCap = StrokeCap.round;
        
        canvas.drawLine(points[i]!.offset!, points[i + 1]!.offset!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        final paint = Paint()
          ..color = points[i]!.color
          ..strokeWidth = points[i]!.width
          ..strokeCap = StrokeCap.round;
        
        canvas.drawPoints(ui.PointMode.points, [points[i]!.offset!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) => true;
}
