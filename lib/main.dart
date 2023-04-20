import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:review_task_2/Views/Auth_page.dart';
import 'package:review_task_2/Views/home_screen.dart';
import 'Views/login_screen.dart';
import 'Views/home_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomeScreen();
          }
          else {
          return AuthPage();
          }
        }
      )
    );
  }
}