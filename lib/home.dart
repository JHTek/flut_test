import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'calendar_page.dart';
import 'create_team_page.dart';
import 'view_teams_page.dart';
import 'result_page.dart';
import 'profile_settings_page.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('홈 페이지'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            if (user != null)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  var userData = snapshot.data!.data() as Map<String, dynamic>?;
                  var profileImage = userData?['profileImage'] ?? '';
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: profileImage.isNotEmpty ? AssetImage(profileImage) : null,
                        backgroundColor: Colors.grey[300],
                        child: profileImage.isEmpty ? Icon(Icons.person, size: 40) : null,
                      ),
                      SizedBox(height: 10),
                      Text(
                        userData?['name'] ?? '이름 없음',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email ?? '이메일 없음',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfileSettingsPage()),
                          );
                        },
                        child: Text('프로필 설정'),
                      ),
                    ],
                  );
                },
              ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalendarPage()),
                );
              },
              child: Text('캘린더 페이지로 이동'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResultPage()),
                );
              },
              child: Text('개인 스케줄 보기'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateTeamPage()),
                );
              },
              child: Text('팀 생성 페이지로 이동'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewTeamsPage()),
                );
              },
              child: Text('팀 확인 페이지로 이동'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
