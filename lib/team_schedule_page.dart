import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TeamSchedulePage extends StatefulWidget {
  final String teamId;

  TeamSchedulePage({required this.teamId});

  @override
  _TeamSchedulePageState createState() => _TeamSchedulePageState();
}

class _TeamSchedulePageState extends State<TeamSchedulePage> {
  final ScrollController _scrollController = ScrollController();
  int _weekOffset = 0;
  List<String> memberUids = [];

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

  Future<List<List<bool>>> _getTeamSchedules(DateTime weekStart, DateTime weekEnd) async {
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

      if (schedulesSnapshot.docs.isEmpty) {
        print('No schedules found for the specified week');
        return teamSelectedGrid;
      }

      for (var doc in schedulesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Document found: ${doc.id} with data: $data');
        List<dynamic> cells = data['cells'];
        print('Cells: $cells');
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
        title: Text('팀 일정 페이지'),
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
        future: _getTeamSchedules(weekStart, weekEnd),
        builder: (context, scheduleSnapshot) {
          if (!scheduleSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          List<List<bool>> teamSelectedGrid = scheduleSnapshot.data!;
          bool hasOverlap = teamSelectedGrid.any((row) => row.contains(true));

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
                  child: hasOverlap
                      ? Column(
                    children: List.generate(35, (row) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (col) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: teamSelectedGrid[row][col] ? Colors.green : Colors.white,
                            child: Center(child: Text('${timeSlots[row]}')),
                          );
                        }),
                      );
                    }),
                  )
                      : Center(
                    child: Text(
                      '팀원끼리의 겹치는 시간이 없습니다! 일정을 조율하세요!',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.edit),
                ),
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
