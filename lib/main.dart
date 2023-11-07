import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/login.dart';
import 'board.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase 게시판',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // 인증 상태 확인 중이면 로딩 표시
          } else {
            if (snapshot.hasData) {
              return MyBoard(); // 사용자가 로그인한 경우 MyBoard 표시
            } else {
              return LoginScreen(); // 사용자가 로그인하지 않은 경우 로그인 화면 표시
            }
          }
        },
      ),
    );
  }
}
