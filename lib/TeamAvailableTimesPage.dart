import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeamAvailableTimesPage extends StatefulWidget {
  final String teamId;

  TeamAvailableTimesPage({required this.teamId});

  @override
  _TeamAvailableTimesPageState createState() => _TeamAvailableTimesPageState();
}

class _TeamAvailableTimesPageState extends State<TeamAvailableTimesPage> {
  final ScrollController _scrollController = ScrollController();
  int _weekOffset = 0;
  List<String> memberUids = [];
  List<List<bool>> selectedTimes = List.generate(35, (row) => List.generate(7, (col) => false)); // 선택된 시간 저장

  @override
  void initState() {
    super.initState();
    _getTeamMembers();
  }

  Future<void> _getTeamMembers() async {
    try {
      DocumentSnapshot teamSnapshot = await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).get();
      if (teamSnapshot.exists) {
        Map<String, dynamic>? teamData = teamSnapshot.data() as Map<String, dynamic>?;
        if (teamData != null) {
          List<dynamic> memberIds = teamData['members'];
          setState(() {
            memberUids = memberIds.map((id) => id.toString()).toList();
          });
        }
      }
    } catch (e) {
      print("Failed to get team members: $e");
    }
  }

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

  Future<List<List<bool>>> _getTeamAvailableTimes(DateTime weekStart, DateTime weekEnd) async {
    List<List<bool>> teamSelectedGrid = List.generate(35, (row) => List.generate(7, (col) => true));

    try {
      var schedulesSnapshot = await FirebaseFirestore.instance
          .collection('selected_cells')
          .where('userId', whereIn: memberUids)
          .where('weekStart.year', isEqualTo: weekStart.year)
          .where('weekStart.month', isEqualTo: weekStart.month)
          .where('weekStart.day', isEqualTo: weekStart.day)
          .where('weekEnd.year', isEqualTo: weekEnd.year)
          .where('weekEnd.month', isEqualTo: weekEnd.month)
          .where('weekEnd.day', isEqualTo: weekEnd.day)
          .get();

      for (var doc in schedulesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> cells = data['cells'];
        List<List<bool>> memberGrid = List.generate(35, (row) => List.generate(7, (col) => false));
        for (var cell in cells) {
          var parts = cell.replaceAll('(', '').replaceAll(')', '').split(', ');
          int row = int.parse(parts[0]) - 1;
          int col = int.parse(parts[1]) - 1;
          memberGrid[row][col] = true;
        }

        for (int i = 0; i < 35; i++) {
          for (int j = 0; j < 7; j++) {
            teamSelectedGrid[i][j] = teamSelectedGrid[i][j] && memberGrid[i][j];
          }
        }
      }
    } catch (e) {
      print("Failed to get team schedules: $e");
    }

    return teamSelectedGrid;
  }

  void _toggleTimeSelection(int row, int col) {
    setState(() {
      selectedTimes[row][col] = !selectedTimes[row][col];
    });
  }

  void _saveSelectedTime() async {
    DateTime weekStart = _getCurrentStartOfWeek();
    DateTime weekEnd = _getCurrentEndOfWeek();

    List<String> selectedTimeSlots = [];
    for (int row = 0; row < 35; row++) {
      for (int col = 0; col < 7; col++) {
        if (selectedTimes[row][col]) {
          selectedTimeSlots.add('(${row + 1}, ${col + 1})');
        }
      }
    }

    await FirebaseFirestore.instance.collection('team_meetings').add({
      'teamId': widget.teamId,
      'selectedTimeSlots': selectedTimeSlots,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('선택된 시간이 저장되었습니다!')),
    );
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
        title: Text('팀 가용 시간 추천'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: memberUids.isEmpty
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<List<List<bool>>>(
        future: _getTeamAvailableTimes(weekStart, weekEnd),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<List<bool>> availableTimes = snapshot.data!;

          return Column(
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
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: List.generate(35, (row) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (col) {
                          return GestureDetector(
                            onTap: availableTimes[row][col] ? () => _toggleTimeSelection(row, col) : null,
                            child: Container(
                              width: 50,
                              height: 50,
                              color: availableTimes[row][col]
                                  ? selectedTimes[row][col] ? Colors.blue : Colors.green
                                  : Colors.grey,
                              child: Center(child: Text('${timeSlots[row]}')),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _saveSelectedTime,
                child: Text('선택된 시간 저장하기'),
              ),
            ],
          );
        },
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
