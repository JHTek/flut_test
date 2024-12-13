import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TeamSelectedTimesPage extends StatefulWidget {
  final String teamId;

  TeamSelectedTimesPage({required this.teamId});

  @override
  _TeamSelectedTimesPageState createState() => _TeamSelectedTimesPageState();
}

class _TeamSelectedTimesPageState extends State<TeamSelectedTimesPage> {
  int _weekOffset = 0;

  DateTime _getStartOfWeek(DateTime date) {
    int currentWeekday = date.weekday;
    return date.subtract(Duration(days: currentWeekday - 1));
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
        title: Text('선택된 가용 시간'),
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
                  .collection('team_meetings')
                  .where('teamId', isEqualTo: widget.teamId)
                  .where('weekStart.year', isEqualTo: weekStart.year)
                  .where('weekStart.month', isEqualTo: weekStart.month)
                  .where('weekStart.day', isEqualTo: weekStart.day)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('선택된 가용 시간이 없습니다.'));
                }

                List<List<bool>> selectedGrid = List.generate(35, (row) => List.generate(7, (col) => false));
                QueryDocumentSnapshot doc = snapshot.data!.docs.first;
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                List<dynamic> selectedTimeSlots = data['selectedTimeSlots'];

                for (var slot in selectedTimeSlots) {
                  var parts = slot.replaceAll('(', '').replaceAll(')', '').split(', ');
                  int row = int.parse(parts[0]) - 1;
                  int col = int.parse(parts[1]) - 1;
                  selectedGrid[row][col] = true;
                }

                return SingleChildScrollView(
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
                            color: selectedGrid[row][col] ? Colors.blue : Colors.white,
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
