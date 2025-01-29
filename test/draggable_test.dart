// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DragAndDropScreen(),
    );
  }
}

class DragAndDropScreen extends StatefulWidget {
  const DragAndDropScreen({super.key});

  @override
  _DragAndDropScreenState createState() => _DragAndDropScreenState();
}

class _DragAndDropScreenState extends State<DragAndDropScreen> {
  String _droppedData = 'Drop here';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drag and Drop Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Draggable<String>(
              data: 'Some data',
              feedback: Material(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue.withOpacity(0.5),
                  child: Center(child: Text('Dragging')),
                ),
              ),
              childWhenDragging: Container(
                width: 100,
                height: 100,
                color: Colors.grey,
                child: Center(child: Text('Dragging...')),
              ),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: Center(child: Text('Drag me')),
              ),
            ),
            SizedBox(height: 50),
            DragTarget<String>(
              onWillAccept: (data) {
                return data == 'Some data';
              },
              onAccept: (data) {
                setState(() {
                  _droppedData = 'Dropped: $data';
                });
              },
              onLeave: (data) {
                setState(() {
                  _droppedData = 'Drop here';
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: 200,
                  height: 200,
                  color: candidateData.isNotEmpty ? Colors.green : Colors.red,
                  child: Center(child: Text(_droppedData)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
