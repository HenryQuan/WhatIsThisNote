import 'package:flutter/material.dart';

/// HomePage class
class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  Offset offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('What is this note?')
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            left: offset.dx,
            top: offset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                final newDx = offset.dx + details.delta.dx;
                final newDy = offset.dy + details.delta.dy;
                print('$newDx $newDy\n');
                if (newDy >= 0 && newDx >= 0) {
                  setState(() {
                    offset = Offset(newDx, newDy);
                  });
                }
              },
              child: Container(width: 100, height: 100, color: Colors.blue),
            ),
          ),
        ],
      ),
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
