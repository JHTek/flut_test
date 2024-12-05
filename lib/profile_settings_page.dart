import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSettingsPage extends StatefulWidget {
  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  String? _profileImageAsset;
  String? _userId;
  String? _email;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
        _email = user.email;
      });
      _getUserDataFromFirestore(user.uid);
    }
  }

  Future<void> _getUserDataFromFirestore(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    var userData = userDoc.data() as Map<String, dynamic>?;

    if (userData != null) {
      setState(() {
        _displayName = userData['name'] ?? '';
        _profileImageAsset = userData['profileImage'] ?? '';
        _nameController.text = _displayName!;
      });
    }
  }

  Future<void> _saveProfile() async {
    String name = _nameController.text.trim();
    if (_userId != null && name.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_userId).update({
          'name': name,
          'profileImage': _profileImageAsset ?? '',
        });
        setState(() {
          _displayName = name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("프로필이 저장되었습니다")),
        );
        Navigator.pop(context); // 홈 화면으로 돌아가기
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("저장에 실패했습니다. 다시 시도해주세요.")),
        );
      }
    }
  }

  void _selectProfileImage(String assetName) {
    setState(() {
      _profileImageAsset = assetName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> assetImages = [
      'assets/images/choims.jpg',
      'assets/images/leejj.jpg',
      'assets/images/hwangjm.jpg',
      // 여기에 더 많은 이미지를 추가하세요
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _profileImageAsset != null && _profileImageAsset!.isNotEmpty
                      ? AssetImage(_profileImageAsset!)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: _profileImageAsset == null || _profileImageAsset!.isEmpty
                      ? Text('등록 필요')
                      : null,
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: '이름'),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _email ?? '이메일 없음',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                itemCount: assetImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _selectProfileImage(assetImages[index]),
                    child: Stack(
                      children: [
                        Image.asset(
                          assetImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        if (_profileImageAsset == assetImages[index])
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(Icons.check_circle, color: Colors.green),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text('프로필 저장'),
            ),
          ],
        ),
      ),
    );
  }
}
