import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입 페이지'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: '이메일'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text,
                    password: passwordController.text,
                  );
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('회원가입 성공'),
                        content: Text('환영합니다! 회원가입이 성공적으로 완료되었습니다.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.pushReplacementNamed(context, '/login'); // 로그인 페이지로 이동
                            },
                            child: Text('확인'),
                          ),
                        ],
                      );
                    },
                  );
                } on FirebaseAuthException catch (e) {
                  String message;
                  if (e.code == 'weak-password') {
                    message = '비밀번호가 너무 약합니다.';
                  } else if (e.code == 'email-already-in-use') {
                    message = '이미 사용 중인 이메일입니다.';
                  } else {
                    message = '회원가입 중 오류가 발생했습니다.';
                  }
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('회원가입 실패'),
                        content: Text(message),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('확인'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
