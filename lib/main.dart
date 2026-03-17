import 'package:flutter/material.dart';
import 'start_page.dart';

void main() {
  runApp(const LetterSoundMazeApp());
}

class LetterSoundMazeApp extends StatelessWidget {
  const LetterSoundMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Letter Sound Maze',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StartPage(),
    );
  }
}
