import 'package:flutter/material.dart';
import 'result_page.dart'; // 결과 페이지 파일을 임포트


class CalendarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<List<bool>> _isSelected = List.generate(10, (index) => List.generate(7, (index) => false));
  bool? _initialSelectedState;

  void _onPanStart(DragStartDetails details) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(details.localPosition);
    _initialSelectedState = _getSelectedState(localPosition);
  }

  bool? _getSelectedState(Offset localPosition) {
    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 7; col++) {
        double startX = col * 50.0;
        double endX = startX + 50.0;
        double startY = row * 50.0;
        double endY = startY + 50.0;
        if (localPosition.dx >= startX && localPosition.dx < endX &&
            localPosition.dy >= startY && localPosition.dy < endY) {
          return _isSelected[row][col];
        }
      }
    }
    return null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(details.localPosition);

    setState(() {
      for (int row = 0; row < 10; row++) {
        for (int col = 0; col < 7; col++) {
          double startX = col * 50.0;
          double endX = startX + 50.0;
          double startY = row * 50.0;
          double endY = startY + 50.0;
          if (localPosition.dx >= startX && localPosition.dx < endX &&
              localPosition.dy >= startY && localPosition.dy < endY) {
            if (_isSelected[row][col] == _initialSelectedState) {
              _isSelected[row][col] = !_isSelected[row][col]; // 선택 상태 반전
            }
          }
        }
      }
    });
  }

  List<String> _getSelectedCells() {
    List<String> selectedCells = [];
    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 7; col++) {
        if (_isSelected[row][col]) {
          selectedCells.add('(${row + 1}, ${col + 1})');
        }
      }
    }
    return selectedCells;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('드래그로 선택하기'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Row(
            children: List.generate(7, (col) {
              return Container(
                width: 50,
                height: 50,
                child: Center(
                  child: Text(
                    ['월', '화', '수', '목', '금', '토', '일'][col],
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              );
            }),
          ),
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              child: Column(
                children: List.generate(10, (row) {
                  return Row(
                    children: List.generate(7, (col) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: _isSelected[row][col] ? Colors.yellow : Colors.white,
                        child: Center(child: Text('칸 ${row * 7 + col + 1}')),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ResultPage(selectedCells: _getSelectedCells())),
              );
            },
            child: Text('결과 화면으로 이동'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '선택된 칸: ${_getSelectedCells().join(', ')}',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),

        ],
      ),
    );
  }
}
