import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'result_page.dart';
import 'package:intl/intl.dart';  // 날짜 형식을 위한 패키지

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
  int _weekOffset = 0; // 주간 오프셋
  final GlobalKey _gridKey = GlobalKey(); // Grid의 GlobalKey

  final List<String> timeSlots = [
    '7:00', '7:30', '8:00', '8:30', '9:00', '9:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30',
    '22:00', '22:30', '23:00', '23:30', '24:00'
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 유저 아이디 변수
  String? _userId;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  // 현재 로그인된 유저의 아이디를 가져오는 메소드
  void _getUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userId = user?.uid;
    });
  }

  void _onTap(int row, int col) {
    setState(() {
      _isSelected[row][col] = !_isSelected[row][col];
    });
  }

  void _onPanStart(DragStartDetails details) {
    RenderBox box = _gridKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(details.globalPosition);

    _initialSelectedState = !_getCellState(localPosition);
    _updateSelection(localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    RenderBox box = _gridKey.currentContext!.findRenderObject() as RenderBox;
    Offset localPosition = box.globalToLocal(details.globalPosition);

    _updateSelection(localPosition);
  }

  bool _getCellState(Offset localPosition) {
    double dx = localPosition.dx;
    double dy = localPosition.dy;

    int col = (dx / 50).floor();
    int row = (dy / 50).floor();

    if (row >= 0 && row < 35 && col >= 0 && col < 7) {
      return _isSelected[row][col];
    }
    return false;
  }

  void _updateSelection(Offset localPosition) {
    double dx = localPosition.dx;
    double dy = localPosition.dy;

    int col = (dx / 50).floor();
    int row = (dy / 50).floor();

    if (row >= 0 && row < 35 && col >= 0 && col < 7) {
      setState(() {
        _isSelected[row][col] = _initialSelectedState!;
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
    if (_userId == null) {
      print('User is not logged in');
      return;
    }

    List<String> selectedCells = _getSelectedCells();
    DateTime weekStart = _getCurrentStartOfWeek();
    DateTime weekEnd = _getCurrentEndOfWeek();

    try {
      // 기존 데이터 검색
      QuerySnapshot querySnapshot = await _firestore.collection('selected_cells')
          .where('userId', isEqualTo: _userId)
          .where('weekStart.year', isEqualTo: weekStart.year)
          .where('weekStart.month', isEqualTo: weekStart.month)
          .where('weekStart.day', isEqualTo: weekStart.day)
          .where('weekEnd.year', isEqualTo: weekEnd.year)
          .where('weekEnd.month', isEqualTo: weekEnd.month)
          .where('weekEnd.day', isEqualTo: weekEnd.day)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 기존 데이터가 있는 경우
        DocumentSnapshot existingDoc = querySnapshot.docs.first;
        Map<String, dynamic> existingData = existingDoc.data() as Map<String, dynamic>;
        List<dynamic> existingCells = existingData['cells'];

        // 기존 셀과 새로운 셀을 합치고 중복 제거
        Set<String> mergedCells = {...existingCells.map((cell) => cell.toString()), ...selectedCells};

        // 기존 문서 업데이트
        await _firestore.collection('selected_cells').doc(existingDoc.id).update({
          'cells': mergedCells.toList(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // 새로운 문서 생성
        await _firestore.collection('selected_cells').add({
          'userId': _userId,
          'cells': selectedCells,
          'weekStart': {
            'year': weekStart.year,
            'month': weekStart.month,
            'day': weekStart.day,
          },
          'weekEnd': {
            'year': weekEnd.year,
            'month': weekEnd.month,
            'day': weekEnd.day,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("데이터가 성공적으로 저장되었습니다!"))
      );
    } catch (e) {
      print('Error saving selected cells: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("데이터 저장에 실패했습니다: $e"))
      );
    }
  }


  DateTime _getCurrentStartOfWeek() {
    DateTime now = DateTime.now().add(Duration(days: _weekOffset * 7));
    int currentWeekday = now.weekday;
    return now.subtract(Duration(days: currentWeekday - 1));
  }

  DateTime _getCurrentEndOfWeek() {
    return _getCurrentStartOfWeek().add(Duration(days: 6));
  }

  void _incrementWeek() {
    setState(() {
      _weekOffset += 1;
    });
  }

  void _decrementWeek() {
    setState(() {
      _weekOffset -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DateTime> weekDates = List.generate(7, (index) => _getCurrentStartOfWeek().add(Duration(days: index)));
    DateFormat formatter = DateFormat('M/d');

    return Scaffold(
      appBar: AppBar(
        title: Text('드래그로 선택하기'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(7, (col) {
              return Container(
                width: 50,
                height: 50,
                child: Center(
                  child: Text(
                    '${['월', '화', '수', '목', '금', '토', '일'][col]} (${formatter.format(weekDates[col])})',
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
                    key: _gridKey,
                    children: List.generate(35, (row) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: _decrementWeek,
              ),
              IconButton(
                icon: Icon(Icons.arrow_right),
                onPressed: _incrementWeek,
              ),
            ],
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
          IconButton(
            icon: Icon(Icons.cleaning_services),
            onPressed: _clearSelection,
          ),
        ],
      ),
    );
  }
}
