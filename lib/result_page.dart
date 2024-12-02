import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final List<String> selectedCells;

  ResultPage({required this.selectedCells});

  @override
  Widget build(BuildContext context) {
    Map<int, String> weekdays = {
      1: '월',
      2: '화',
      3: '수',
      4: '목',
      5: '금',
      6: '토',
      0: '일',
    };

    Map<String, List<String>> sortedCells = {};

    // 요일별로 선택된 칸을 분류
    for (var cell in selectedCells) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('결과 화면'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          children: weekdays.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${entry.value}: ${sortedCells[entry.value]?.join(', ') ?? ''}',
                style: TextStyle(fontSize: 16),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
