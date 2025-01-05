import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/drawing_point.dart';
import '../provider/drawing_provider.dart';

class DrawingCanvas extends StatelessWidget {
  const DrawingCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.globalPosition);
        Provider.of<DrawingProvider>(context, listen: false)
            .startDrawing(offset);
      },
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final offset = box.globalToLocal(details.globalPosition);
        Provider.of<DrawingProvider>(context, listen: false).addPoint(offset);
      },
      onPanEnd: (details) {
        Provider.of<DrawingProvider>(context, listen: false).endDrawing();
      },
      child: CustomPaint(
        painter: DrawingPainter(
          drawingPoints: context.watch<DrawingProvider>().drawingPoints,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<List<DrawingPoint>> drawingPoints;

  DrawingPainter({required this.drawingPoints});

  @override
  void paint(Canvas canvas, Size size) {
    for (final points in drawingPoints) {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(
          points[i].offset,
          points[i + 1].offset,
          points[i].paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
