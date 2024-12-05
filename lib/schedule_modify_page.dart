import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ScheduleModifyPage extends StatefulWidget {
  @override
  _ScheduleModifyPageState createState() => _ScheduleModifyPageState();
}

class _ScheduleModifyPageState extends State<ScheduleModifyPage> {
  String? currentUserId;
  int _currentIndex = 0;
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

  void _deleteSchedule(String docId) async {
    await FirebaseFirestore.instance.collection('selected_cells').doc(docId).delete();
    _showDeletionMessage();
    _refreshData();
  }

  void _showDeletionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('일정이 삭제되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _refreshData() {
    setState(() {
      _getCurrentUser();
    });
  }

  void _nextData(int totalDocs) {
    setState(() {
      if (_currentIndex < totalDocs - 1) {
        _currentIndex += 1;
      }
    });
  }

  void _prevData() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex -= 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('개인 일정 수정'),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: currentUserId == null
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('selected_cells')
            .where('userId', isEqualTo: currentUserId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('저장된 일정이 없습니다.'));
          }

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
          Map<String, dynamic> data = docs[_currentIndex].data() as Map<String, dynamic>;
          List<dynamic> cells = data['cells'];
          DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
          DateTime weekStart = DateTime(data['weekStart']['year'], data['weekStart']['month'], data['weekStart']['day']);
          DateTime weekEnd = DateTime(data['weekEnd']['year'], data['weekEnd']['month'], data['weekEnd']['day']);
          DateFormat dateFormat = DateFormat('yyyy-MM-dd');

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_left),
                    onPressed: _prevData,
                  ),
                  Text('일정 ${_currentIndex + 1}/${docs.length}'),
                  IconButton(
                    icon: Icon(Icons.arrow_right),
                    onPressed: () => _nextData(docs.length),
                  ),
                ],
              ),
              ListTile(
                title: Text('저장 시간: $timestamp'),
                subtitle: Text('주: ${dateFormat.format(weekStart)} - ${dateFormat.format(weekEnd)}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSchedule(docs[_currentIndex].id),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.vertical,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(35, (row) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (col) {
                          String cell = '(${row + 1}, ${col + 1})';
                          return Container(
                            width: 50,
                            height: 50,
                            color: cells.contains(cell) ? Colors.red : Colors.white,
                            child: Center(child: Text('${timeSlots[row]}')),
                          );
                        }),
                      );
                    }),
                  ),
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
