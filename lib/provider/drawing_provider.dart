import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../model/drawing_point.dart';
import '../services/firestore_service.dart';
import '../services/offline_storage.dart';

class DrawingProvider extends ChangeNotifier {
  final String userId = const Uuid().v4();
  final FirestoreService _firestoreService = FirestoreService();
  final List<List<DrawingPoint>> _drawingPoints = [];
  final List<List<DrawingPoint>> _undoStack = [];
  final List<List<DrawingPoint>> _redoStack = [];
  Color selectedColor = Colors.black;
  Timer? _debounceTimer;
  double strokeWidth = 3.0;
  bool _isDrawing = false;
  final List<DrawingPoint> _pointBuffer =
      []; // Buffer to temporarily store points
  final double canvasWidth =
      double.infinity; // Replace with your actual canvas width
  final double canvasHeight =
      double.infinity; // Replace with your actual canvas height

  List<List<DrawingPoint>> get drawingPoints => _drawingPoints;

  List<List<DrawingPoint>> get redoStack => _redoStack;

  bool get isDrawing => _isDrawing;

  DrawingProvider() {
    _initializeFirestore();
    _loadOfflinePoints();
    _monitorConnectivity();
  }

  // Listen to Firestore changes in real-time
  void _initializeFirestore() {
    _firestoreService.getDrawingPoints().listen((points) {
      for (final point in points) {
        if (point.userId != userId) {
          _bufferAndRenderPoints(point);
        }
      }
    });
  }

  void _bufferAndRenderPoints(DrawingPoint point) {
    if (point.offset.dx < 0 || point.offset.dy < 0) return;
    if (point.offset.dx > canvasWidth || point.offset.dy > canvasHeight) return;

    _pointBuffer.add(point);

    // Debounce rendering with a single timer
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 20), () {
      for (var p in _pointBuffer) {
        _handleReceivedDrawingPoint(p);
      }
      _pointBuffer.clear();
    });
  }

  void _loadOfflinePoints() async {
    final offlinePoints = await OfflineStorage.loadDrawingPoints();
    if (offlinePoints.isNotEmpty) {
      _drawingPoints.addAll(offlinePoints);
      notifyListeners();
    }
  }

  void syncOfflinePoints() async {
    final offlinePoints = await OfflineStorage.loadDrawingPoints();
    for (final line in offlinePoints) {
      if (line.isNotEmpty) {
        // Batch save the points from each line to Firestore
        await _firestoreService.addDrawingPoint(line);
      }
    }

    // Clear local storage after syncing
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove('drawing_points'));
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((status) {
      if (status != ConnectivityResult.none) {
        syncOfflinePoints();
      }
    });
  }

  // Start drawing a new line
  void startDrawing(Offset offset) {
    _isDrawing = true;

    // Add a new list of points for the new line, so it doesn't continue from the previous line
    _drawingPoints.add([
      DrawingPoint(
        offset: offset,
        paint: Paint()
          ..color = selectedColor
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
        userId: userId,
      )
    ]);

    // Immediately save the starting point to Firestore
    _firestoreService.addDrawingPoint(_drawingPoints.last);
    notifyListeners();
  }

  // Add a point to the current line
  void addPoint(Offset offset) {
    _redoStack.clear();
    if (!_isDrawing) return;

    final DrawingPoint point = DrawingPoint(
      offset: offset,
      paint: Paint()
        ..color = selectedColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      userId: userId,
    );

    // Add point to the current line
    if (_drawingPoints.isEmpty || _drawingPoints.last.isEmpty) {
      _drawingPoints.add([]);
    }
    _drawingPoints.last.add(point);

    // Save the current line of points (batched) to Firestore
    if (_drawingPoints.last.isNotEmpty) {
      _firestoreService.addDrawingPoint(_drawingPoints.last);
    }

    // Save all points to offline storage
    OfflineStorage.saveDrawingPoints(_drawingPoints);

    notifyListeners();
  }

  // End drawing and stop adding points
  void endDrawing() {
    _isDrawing = false;
  }

  // Handle received points from other users
  void _handleReceivedDrawingPoint(DrawingPoint point) {
    if (_drawingPoints.isEmpty ||
        _drawingPoints.last.last.userId != point.userId) {
      _drawingPoints.add([point]); // Start a new line for this user
    } else {
      final lastPoint = _drawingPoints.last.last;
      final distance = (point.offset - lastPoint.offset).distance;

      // Threshold for detecting discontinuities
      if (distance > 50) {
        _drawingPoints.add([point]); // Start a new line
      } else {
        _drawingPoints.last.add(point); // Continue the current line
      }
    }
    notifyListeners(); // Notify UI of changes
  }

  void undo() {
    if (_drawingPoints.isNotEmpty) {
      _redoStack.add(_drawingPoints.removeLast());
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      _drawingPoints.add(_redoStack.removeLast());
      notifyListeners();
    }
  }

  void clearCanvas() async {
    // Clear local state
    _drawingPoints.clear();
    _redoStack.clear();

    // Clear Firestore data
    await _firestoreService
        .deleteRoom('default_room'); // Replace with the desired room ID

    notifyListeners();
  }

  // Change drawing color
  void setColor(Color color) {
    selectedColor = color;
    notifyListeners();
  }

  // Change stroke width
  void setStrokeWidth(double width) {
    strokeWidth = width;
    notifyListeners();
  }
}

// void startDrawing(Offset offset) {
//   _isDrawing = true;
//   _addNewDrawingList(offset);
//   notifyListeners();
// }
//
// void addPoint(Offset offset) {
//   if (!_isDrawing) return;
//
//   final point = _createDrawingPoint(offset);
//   _addPointToLastDrawing(point);
//
//   // Broadcast the drawing point to all other devices
//   _webSocketService.sendDrawingPoint(point);
//
//   notifyListeners();
// }
//
// void endDrawing() {
//   _isDrawing = false;
// }
//
// void _handleReceivedDrawingPoint(DrawingPoint point) {
//   // Always add points, even if they are from other users
//   if (_drawingPoints.isEmpty ||
//       _drawingPoints.last.isEmpty ||
//       _drawingPoints.last.last.userId != point.userId) {
//     _drawingPoints.add([point]);
//   } else {
//     _drawingPoints.last.add(point);
//   }
//   notifyListeners();
// }
//
// void setColor(Color color) {
//   selectedColor = color;
//   notifyListeners();
// }
//
// void setStrokeWidth(double width) {
//   strokeWidth = width;
//   notifyListeners();
// }
//
// @override
// void dispose() {
//   _webSocketService.disconnect();
//   super.dispose();
// }
//
// void _addNewDrawingList(Offset offset) {
//   _drawingPoints.add([
//     _createDrawingPoint(offset),
//   ]);
// }
//
// DrawingPoint _createDrawingPoint(Offset offset) {
//   return DrawingPoint(
//     offset: offset,
//     paint: Paint()
//       ..color = selectedColor
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round
//       ..style = PaintingStyle.stroke,
//     userId: userId,
//   );
// }
//
// void _addPointToLastDrawing(DrawingPoint point) {
//   if (_drawingPoints.isNotEmpty) {
//     _drawingPoints.last.add(point);
//   }
// }
