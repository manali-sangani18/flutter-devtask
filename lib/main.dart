
import 'package:flutter/material.dart';

void main() {
  runApp(const DrawingApp());
}

class DrawingApp extends StatelessWidget {
  const DrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collaborative Drawing',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DrawingScreen(),
    );
  }
}
