import 'package:flutter/material.dart';
import 'package:habit_creator/components/wide_button.dart';
import 'package:habit_creator/constants.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'build_habit.dart';
import 'dart:core';
import 'package:shared_preferences/shared_preferences.dart';

User loggedInUser;

class RegistrationScreen extends StatefulWidget {
  static const String id = '/register';

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String password;
  bool showSpinner = false;

  final _auth = FirebaseAuth.instance;

  void initUserVariables() async {
    loggedInUser = _auth.currentUser;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', loggedInUser.email);
    firestore
        .collection(globalUserId)
        .doc('variables')
        .set({'userId': globalUserId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.blueGrey[100],
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    height: 200.0,
                    child: Image.asset('images/portal.png'),
                  ),
                ),
              ),
              SizedBox(
                height: 48.0,
              ),
              TextField(
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  //Do something with the user input.
                  globalUserId = value;
                },
                decoration:
                    kInputDecoration.copyWith(hintText: 'Enter your email'),
              ),
              SizedBox(
                height: 8.0,
              ),
              TextField(
                obscureText: true,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  //Do something with the user input.
                  password = value;
                },
                decoration:
                    kInputDecoration.copyWith(hintText: 'Enter your password'),
              ),
              SizedBox(
                height: 24.0,
              ),
              WideButton(Colors.red[900], 'Register', () async {
                setState(() {
                  showSpinner = true;
                });
                try {
                  final newUser = await _auth.createUserWithEmailAndPassword(
                      email: globalUserId, password: password);
                  if (newUser != null) {
                    initUserVariables();
                    Navigator.pushNamed(context, HabitBuilder.id);
                  }
                  setState(() {
                    showSpinner = false;
                  });
                } catch (e) {
                  print(e);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
