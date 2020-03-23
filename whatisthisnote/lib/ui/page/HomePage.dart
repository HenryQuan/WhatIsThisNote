import 'package:flutter/material.dart';

/// HomePage class
class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('What is this note?')
      ),
      body: SafeArea(
        child: Column(
          children: renderAllNodes(context)
        ),
      )
    );
  }

  List<Widget> renderAllNodes(BuildContext context) {
    return List.generate(52, (_) => _).map((e) {
      return Flexible(
        flex: 1,
        child: Container(color: e % 2 != 0 ? Colors.white : Colors.blue),
      );
    }).toList();
  }
}
