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
        child: Stack(
          children: <Widget>[
            Column(
              children: renderAllNodes(),
            ),
            Center(
              child: FractionallySizedBox(
                heightFactor: 1 / 52,
                child: Container(
                  color: Colors.red,
                ),
              ),
            )
          ],
        ),
      )
    );
  }

  List<Widget> renderAllNodes() {
    return List.generate(52, (_) => _).map((e) {
      return Flexible(
        flex: 1,
        child: DragTarget(
          builder: (BuildContext context, List<dynamic> candidateData, List<dynamic> rejectedData) { 
            return Container(color: e % 2 != 0 ? Colors.white : Colors.blue);
          },
        ),
      );
    }).toList();
  }
}
