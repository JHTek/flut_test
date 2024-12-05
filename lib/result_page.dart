import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'schedule_modify_page.dart'; // ScheduleModifyPage 파일을 임포트

class ResultPage extends StatefulWidget {
  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String? currentUserId;
  int _weekOffset = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserId = user?.uid;
    });
  }

  DateTime _getStartOfWeek(DateTime date) {
    int currentWeekday = date.weekday;
    return DateTime(date.year, date.month, date.day - currentWeekday + 1); // 시간 제거
  }

  DateTime _getEndOfWeek(DateTime date) {
    return _getStartOfWeek(date).add(Duration(days: 6));
  }

  DateTime _getCurrentStartOfWeek() {
    return _getStartOfWeek(DateTime.now().add(Duration(days: _weekOffset * 7)));
  }

  DateTime _getCurrentEndOfWeek() {
    return _getEndOfWeek(DateTime.now().add(Duration(days: _weekOffset * 7)));
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
    DateTime weekStart = _getCurrentStartOfWeek();
    DateTime weekEnd = _getCurrentEndOfWeek();
    DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    List<String> weekDays = List.generate(7, (index) {
      DateTime day = weekStart.add(Duration(days: index));
      return DateFormat.E('en_US').format(day); // 요일 형식
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('결과 화면'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: currentUserId == null
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: _decrementWeek,
              ),
              Text('${dateFormat.format(weekStart)} - ${dateFormat.format(weekEnd)}'),
              IconButton(
                icon: Icon(Icons.arrow_right),
                onPressed: _incrementWeek,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: weekDays.map((day) {
              return Container(
                width: 50,
                height: 20,
                child: Center(child: Text(day)),
              );
            }).toList(),
          ),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('selected_cells')
                  .where('userId', isEqualTo: currentUserId)
                  .where('weekStart.year', isEqualTo: weekStart.year)
                  .where('weekStart.month', isEqualTo: weekStart.month)
                  .where('weekStart.day', isEqualTo: weekStart.day)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('해당 기간에 등록된 기록이 없습니다.'));
                }

                List<List<bool>> selectedGrid = List.generate(35, (row) => List.generate(7, (col) => false));
                List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

                for (var doc in docs) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  List<dynamic> cells = data['cells'];

                  for (var cell in cells) {
                    var parts = cell.replaceAll('(', '').replaceAll(')', '').split(', ');
                    int row = int.parse(parts[0]) - 1;
                    int col = int.parse(parts[1]) - 1;
                    selectedGrid[row][col] = true;
                  }
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(35, (row) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (col) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: selectedGrid[row][col] ? Colors.green : Colors.white,
                            child: Center(child: Text('${timeSlots[row]}')),
                          );
                        }),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScheduleModifyPage()),
                );
              },
              child: Icon(Icons.edit),
            ),
          ),
        ],
      ),
    );
  }
}

final List<String> timeSlots = [
  '7:00', '7:30', '8:00', '8:30', '9:00', '9:30', '10:00', '10:30', '11:00', '11:30',
  '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
  '17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00', '21:30',
  '22:00', '22:30', '23:00', '23:30', '24:00'
];
