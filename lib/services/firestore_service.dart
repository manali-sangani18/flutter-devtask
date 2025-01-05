import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../model/drawing_point.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _roomId = 'default_room';
  StreamSubscription? _firestoreSubscription;

  // Stream to get drawing points with debouncing
  Stream<List<DrawingPoint>> getDrawingPoints() {
    return _firestore
        .collection('rooms')
        .doc(_roomId)
        .collection('points')
        .orderBy('timestamp', descending: true)
        .limit(1000)
        .snapshots()
        .debounceTime(const Duration(milliseconds: 200))
        .transform(
          ThrottleStreamTransformer<QuerySnapshot<Map<String, dynamic>>>(
            (_) => TimerStream(true, const Duration(milliseconds: 100)),
          ),
        )
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DrawingPoint.fromJson(doc.data()))
          .toList()
          .reversed
          .toList();
    });
  }

  // Add a drawing point
  Future<void> addDrawingPoint(List<DrawingPoint> points) async {
    const batchSize = 500;
    for (int i = 0; i < points.length; i += batchSize) {
      final batch = _firestore.batch();
      final pointsCollection =
          _firestore.collection('rooms').doc(_roomId).collection('points');
      final chunk = points.sublist(
          i, i + batchSize > points.length ? points.length : i + batchSize);

      for (var point in chunk) {
        batch.set(pointsCollection.doc(), {
          ...point.toJson(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }
  }

  // Method to clear all drawing points from Firestore
  Future<void> deleteRoom(String roomId) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);

      // Step 1: Delete all points in the subcollection
      final pointsSnapshot = await roomRef.collection('points').get();
      final batch = _firestore.batch();
      for (final doc in pointsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Step 2: Delete the room document
      await roomRef.delete();

      print("Room '$roomId' and its points deleted successfully.");
    } catch (e) {
      print("Error deleting room '$roomId': $e");
      // Optionally handle errors, such as logging or displaying to the user
    }
  }

  // Dispose of Firestore subscription
  void dispose() {
    _firestoreSubscription?.cancel();
  }
}
