import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateTeamPage extends StatefulWidget {
  @override
  _CreateTeamPageState createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  final TextEditingController _teamNameController = TextEditingController();
  final List<TextEditingController> _memberControllers = [];
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  void _addMemberField() {
    setState(() {
      _memberControllers.add(TextEditingController());
    });
  }

  Future<void> _createTeam() async {
    String teamName = _teamNameController.text;
    if (teamName.isNotEmpty && currentUser != null) {
      List<String> members = [];
      String teamLeader = currentUser!.uid; // 팀장 UID

      for (var controller in _memberControllers) {
        String email = controller.text;
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
        if (userSnapshot.docs.isNotEmpty) {
          String uid = userSnapshot.docs.first.id;
          members.add(uid);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Email $email is not registered. Please enter a valid email.')),
          );
          return;
        }
      }

      members.insert(0, teamLeader);

      CollectionReference teams = FirebaseFirestore.instance.collection('teams');
      DocumentReference newTeamRef = teams.doc();

      await newTeamRef.set({
        'name': teamName,
        'teamLeader': teamLeader,
        'members': members,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Team "$teamName" created successfully!'))
      );

      _teamNameController.clear();
      _memberControllers.forEach((controller) => controller.clear());
      setState(() {
        _memberControllers.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('팀 생성 페이지'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _teamNameController,
              decoration: InputDecoration(labelText: '팀 이름'),
            ),
            SizedBox(height: 10),
            ..._memberControllers.map((controller) {
              return TextField(
                controller: controller,
                decoration: InputDecoration(labelText: '멤버 이메일'),
              );
            }).toList(),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addMemberField,
              child: Text('멤버 추가'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createTeam,
              child: Text('팀 생성'),
            ),
          ],
        ),
      ),
    );
  }
}
