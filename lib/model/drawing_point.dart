import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  final String userId;

  DrawingPoint({
    required this.offset,
    required this.paint,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': offset.dx,
      'y': offset.dy,
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
      'userId': userId,
    };
  }

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      offset: Offset(json['x'], json['y']),
      paint: Paint()
        ..color = Color(json['color'])
        ..strokeWidth = json['strokeWidth']
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      userId: json['userId'],
    );
  }
}
