import 'package:flutter/material.dart';
import 'package:whatisthisnote/ui/page/HomePage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What is this note?',
      theme: ThemeData.light(),
      home: HomePage(),
    );
  }
}
