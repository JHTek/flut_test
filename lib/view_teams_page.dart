import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'team_schedule_page.dart';

class ViewTeamsPage extends StatefulWidget {
  @override
  _ViewTeamsPageState createState() => _ViewTeamsPageState();
}

class _ViewTeamsPageState extends State<ViewTeamsPage> {
  String? selectedTeamId;
  String? currentUserId;
  List<DocumentSnapshot> userTeams = [];
  bool isTeamLeader = false;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserId = user?.uid;
      if (currentUserId != null) {
        _getUserTeams();
      }
    });
  }

  Future<void> _getUserTeams() async {
    try {
      QuerySnapshot userTeamsSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('members', arrayContains: currentUserId)
          .get();
      setState(() {
        userTeams = userTeamsSnapshot.docs;
      });
    } catch (e) {
      print("Failed to get user teams: $e");
    }
  }

  Future<Map<String, String>> _getUserData(String userId) async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userSnapshot.exists) {
      Map<String, dynamic>? data = userSnapshot.data() as Map<String, dynamic>?;
      String userName = data?['name'] ?? 'Unknown';
      String userProfileImage = data?['profileImage'] ?? '';
      return {'name': userName, 'profileImage': userProfileImage};
    } else {
      return {'name': 'Unknown', 'profileImage': ''};
    }
  }

  void _checkIfTeamLeader(String teamId) async {
    DocumentSnapshot teamSnapshot = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
    if (teamSnapshot.exists) {
      Map<String, dynamic> teamData = teamSnapshot.data() as Map<String, dynamic>;
      setState(() {
        isTeamLeader = teamData['teamLeader'] == currentUserId;
      });
    }
  }

  void _addMemberByEmail(String email) async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('없는 이메일입니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      String newMemberId = userSnapshot.docs.first.id;

      DocumentSnapshot teamSnapshot = await FirebaseFirestore.instance.collection('teams').doc(selectedTeamId).get();
      if (teamSnapshot.exists) {
        Map<String, dynamic> teamData = teamSnapshot.data() as Map<String, dynamic>;
        List<dynamic> members = teamData['members'];
        if (members.contains(newMemberId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미 팀에 추가된 이메일입니다.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        await FirebaseFirestore.instance.collection('teams').doc(selectedTeamId).update({
          'members': FieldValue.arrayUnion([newMemberId])
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('팀원이 추가되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
        _emailController.clear();
        _refreshTeamData();
      }
    } catch (e) {
      print("Failed to add member: $e");
    }
  }

  void _refreshTeamData() {
    setState(() {
      _getUserTeams();
    });
  }

  void _deleteMember(String teamId, String memberId) async {
    DocumentReference teamRef = FirebaseFirestore.instance.collection('teams').doc(teamId);
    await teamRef.update({
      'members': FieldValue.arrayRemove([memberId])
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('팀원이 삭제되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
    _refreshTeamData();
  }

  void _deleteTeam(String teamId) async {
    await FirebaseFirestore.instance.collection('teams').doc(teamId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('팀이 삭제되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
    _refreshTeamData();
    setState(() {
      selectedTeamId = null;
      isTeamLeader = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('팀 확인 페이지'),
      ),
      body: currentUserId == null
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 팀 이름 선택 드롭다운
          userTeams.isEmpty
              ? Center(child: Text('속한 팀이 없습니다.'))
              : DropdownButton<String>(
            hint: Text('팀 이름 선택'),
            value: selectedTeamId,
            items: userTeams.map((doc) {
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(doc['name']),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedTeamId = newValue;
                _checkIfTeamLeader(newValue!);
              });
            },
          ),
          // 선택된 팀의 멤버 표시
          Expanded(
            child: selectedTeamId == null
                ? Center(child: Text('팀을 선택하세요'))
                : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .doc(selectedTeamId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                List<dynamic> members = data['members'];
                String teamLeader = data['teamLeader'];

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          String member = members[index];
                          bool isLeader = member == teamLeader;

                          return FutureBuilder<Map<String, String>>(
                            future: _getUserData(member),
                            builder: (context, dataSnapshot) {
                              if (!dataSnapshot.hasData) {
                                return ListTile(
                                  title: Text('Loading...'),
                                );
                              }
                              var userData = dataSnapshot.data!;
                              var profileImage = userData['profileImage'] ?? '';
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: profileImage.isNotEmpty
                                      ? AssetImage(profileImage)
                                      : null,
                                  backgroundColor: Colors.grey[300],
                                  child: profileImage.isEmpty
                                      ? Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  userData['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: isLeader ? Colors.blue : Colors.black,
                                    fontWeight: isLeader ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: isTeamLeader && !isLeader
                                    ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteMember(selectedTeamId!, member),
                                )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamSchedulePage(teamId: selectedTeamId!),
                          ),
                        );
                      },
                      child: Text('팀 일정 보기'),
                    ),
                    if (isTeamLeader)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: '팀원 이메일 입력',
                              ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => _addMemberByEmail(_emailController.text.trim()),
                              child: Text('팀원 추가'),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => _deleteTeam(selectedTeamId!),
                              child: Text('팀 삭제'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
