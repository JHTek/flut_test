import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<List<bool>> _isSelected = List.generate(35, (index) => List.generate(7, (index) => false));
  final ScrollController _scrollController = ScrollController();
  bool? _initialSelectedState;

  final List<String> timeSlots = [
    '7:00', '7:30', '8:00', '8:30', '9:00', '9:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30',
    '22:00', '22:30', '23:00', '23:30', '24:00'
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _onTap(int row, int col) {
    setState(() {
      _isSelected[row][col] = !_isSelected[row][col];
    });
  }

  void _onPanStart(DragStartDetails details) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(details.localPosition);

    double dx = localPosition.dx;
    double dy = localPosition.dy;

    int col = (dx / 50).floor();
    int row = (dy / 50).floor();

    if (row >= 0 && row < 35 && col >= 0 && col < 7) {
      _initialSelectedState = _isSelected[row][col];
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(details.localPosition);

    double dx = localPosition.dx;
    double dy = localPosition.dy;

    int col = (dx / 50).floor();
    int row = (dy / 50).floor();

    if (row >= 0 && row < 35 && col >= 0 && col < 7) {
      setState(() {
        if (_initialSelectedState != null) {
          if (_initialSelectedState!) {
            if (_isSelected[row][col]) {
              _isSelected[row][col] = false;
            }
          } else {
            if (!_isSelected[row][col]) {
              _isSelected[row][col] = true;
            }
          }
        }
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _isSelected = List.generate(35, (index) => List.generate(7, (index) => false));
    });
  }

  List<String> _getSelectedCells() {
    List<String> selectedCells = [];
    for (int row = 0; row < 35; row++) {
      for (int col = 0; col < 7; col++) {
        if (_isSelected[row][col]) {
          selectedCells.add('(${row + 1}, ${col + 1})');
        }
      }
    }
    return selectedCells;
  }

  void _saveSelectedCells() async {
    List<String> selectedCells = _getSelectedCells();
    await _firestore.collection('selected_cells').add({
      'cells': selectedCells,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('Data saved to Firestore');
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
            child: Scrollbar(
              thumbVisibility: true,
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  child: Column(
                    children: List.generate(35, (row) {
                      return Row(
                        children: List.generate(7, (col) {
                          return GestureDetector(
                            onTap: () => _onTap(row, col),
                            child: Container(
                              width: 50,
                              height: 50,
                              color: _isSelected[row][col] ? Colors.yellow : Colors.white,
                              child: Center(child: Text('${timeSlots[row]}')),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ResultPage()),
              );
            },
            child: Text('결과 화면으로 이동'),
          ),
          ElevatedButton(
            onPressed: _saveSelectedCells,
            child: Text('저장'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '선택된 칸: ${_getSelectedCells().join(', ')}',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          IconButton(
            icon: Icon(Icons.cleaning_services),
            onPressed: _clearSelection,
          ),
        ],
      ),
    );
  }
}
