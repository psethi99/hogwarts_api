import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';

class SignupScreen extends StatefulWidget {
  final Function() onClickedSignIn;

  const SignupScreen({
    Key? key,
    required this.onClickedSignIn,
  }) : super (key:key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review Task')),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 15),
                    Text(
                    'Sign Up Here',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email ID',
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (email) => 
                      email != null && !EmailValidator.validate(email)
                      ? 'Enter a valid email'
                      : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => value != null && value.length<7
                    ? 'Enter minimum 7 characters'
                    : null,
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 50,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: ElevatedButton(
                      child: const Text('Sign Up'),
                      onPressed: signUp,
                    )
                  ),
                Row(
                  children: <Widget>[
                    const Text("Already have an account?"),
                    TextButton(
                      child: const Text(
                        'Log In',
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        widget.onClickedSignIn();
                      },
                    )
                  ],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
          ])
        ),
      ));
  }
  Future signUp() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) return;

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(), 
        password: passwordController.text.trim(),);
    }
}