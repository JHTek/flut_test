import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('결과 화면'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('selected_cells').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          Map<int, String> weekdays = {
            1: '월',
            2: '화',
            3: '수',
            4: '목',
            5: '금',
            6: '토',
            0: '일',
          };

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = docs[index].data() as Map<String, dynamic>;
              List<dynamic> cells = data['cells'];
              DateTime timestamp = (data['timestamp'] as Timestamp).toDate();
              Map<String, List<String>> sortedCells = {};

              // 요일별로 선택된 칸을 분류
              for (var cell in cells) {
                var parts = cell.replaceAll('(', '').replaceAll(')', '').split(', ');
                int row = int.parse(parts[0]);
                int col = int.parse(parts[1]);
                int dayIndex = col % 7;
                String day = weekdays[dayIndex]!;
                if (!sortedCells.containsKey(day)) {
                  sortedCells[day] = [];
                }
                sortedCells[day]!.add(cell);
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('저장 시간: $timestamp'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance.collection('selected_cells').doc(docs[index].id).delete();
                          },
                        ),
                      ),
                      ...weekdays.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '${entry.value}: ${sortedCells[entry.value]?.join(', ') ?? ''}',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
