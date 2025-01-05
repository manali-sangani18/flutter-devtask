import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/drawing_point.dart';

class OfflineStorage {
  static Future<void> saveDrawingPoints(List<List<DrawingPoint>> points) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonPoints = points
        .map((line) => line.map((point) => point.toJson()).toList())
        .toList();
    prefs.setString('drawing_points', jsonEncode(jsonPoints));
  }

  static Future<List<List<DrawingPoint>>> loadDrawingPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('drawing_points');
    if (data != null) {
      final jsonPoints = jsonDecode(data) as List;
      return jsonPoints
          .map((line) => (line as List)
              .map((point) => DrawingPoint.fromJson(point))
              .toList())
          .toList();
    }
    return [];
  }
}
