import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:review_task_2/Views/login_screen.dart';
import 'Signup_screen.dart';
import 'login_screen.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState () => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) => 
    isLogin ? LoginScreen(onClickedSignUp : toggle) 
    : SignupScreen(onClickedSignIn : toggle);

  void toggle() => setState(() => isLogin = !isLogin);
}