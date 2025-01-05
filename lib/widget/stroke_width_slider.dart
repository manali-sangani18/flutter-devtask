import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/drawing_provider.dart';

class StrokeWidthSlider extends StatelessWidget {
  const StrokeWidthSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            const Text(
              'Stroke Width',
              style: TextStyle(fontSize: 16),
            ),
            Slider(
              value: provider.strokeWidth,
              min: 1,
              max: 20,
              onChanged: (value) {
                provider.setStrokeWidth(value);
              },
            ),
          ],
        );
      },
    );
  }
}
