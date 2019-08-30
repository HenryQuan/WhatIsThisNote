import 'package:flutter/material.dart';
import 'package:whatisthisnote/ui/page/home.dart';

void main() => runApp(WhatIsThisNote());

class WhatIsThisNote extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatIsThisNote',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}
