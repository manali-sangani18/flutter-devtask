import 'drawing_point.dart';

class DrawingStroke {
  final String userId;
  final List<DrawingPoint> points;

  DrawingStroke({
    required this.userId,
    required this.points,
  });

  void addPoint(DrawingPoint point) {
    if (point.userId == userId) {
      points.add(point);
    }
  }

  bool get isEmpty => points.isEmpty;

  DrawingPoint get lastPoint => points.last;
}
