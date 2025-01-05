import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/drawing_provider.dart';
import '../widget/color_picker.dart';
import '../widget/drawing_canvas.dart';
import '../widget/stroke_width_slider.dart';

class DrawingScreen extends StatelessWidget {
  const DrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborative Drawing'),
      ),
      body: Column(
        children: [
          const Expanded(
            child: DrawingCanvas(),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: context
                                  .read<DrawingProvider>()
                                  .drawingPoints
                                  .isNotEmpty
                              ? () => context.read<DrawingProvider>().undo()
                              : null,
                          child: Icon(
                            Icons.undo,
                            color: context
                                    .watch<DrawingProvider>()
                                    .drawingPoints
                                    .isNotEmpty
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 20),
                        InkWell(
                          onTap: context
                                  .read<DrawingProvider>()
                                  .redoStack
                                  .isNotEmpty
                              ? () => context.read<DrawingProvider>().redo()
                              : null,
                          child: Icon(
                            Icons.redo,
                            color: context
                                    .watch<DrawingProvider>()
                                    .redoStack
                                    .isNotEmpty
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: context
                                  .read<DrawingProvider>()
                                  .drawingPoints
                                  .isNotEmpty
                              ? () =>
                                  context.read<DrawingProvider>().clearCanvas()
                              : null,
                          child: Icon(
                            Icons.delete,
                            color: context
                                    .watch<DrawingProvider>()
                                    .drawingPoints
                                    .isNotEmpty
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const ColorPicker(),
                const SizedBox(height: 20),
                const StrokeWidthSlider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
