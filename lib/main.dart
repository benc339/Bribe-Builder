import 'dart:core';
import 'package:flutter/material.dart';
import 'pages/registration_screen.dart';
import 'pages/habit_tracker.dart';
import 'pages/welcome_screen.dart';
import 'pages/login_screen.dart';
import 'pages/build_habit.dart';

import 'pages/habit_page.dart';

import 'package:firebase_core/firebase_core.dart';

import 'pages/home_page.dart';
import 'pages/camera_page.dart';

import 'pages/test_payment.dart';

// void main() {
//   runApp(FlashChat());
// }

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  // try {
  //   WidgetsFlutterBinding.ensureInitialized();
  //   cameras = await availableCameras();
  // } on CameraException catch (e) {
  //   logError(e.code, e.description);
  // }
  runApp(CameraApp());
}

class FlashChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Firebase.initializeApp();

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: new ThemeData(primaryColor: Color.fromRGBO(58, 66, 86, 1.0)),
        initialRoute: '/',
        routes: {
          WelcomeScreen.id: (context) => WelcomeScreen(),
          LoginScreen.id: (context) => LoginScreen(),
          RegistrationScreen.id: (context) => RegistrationScreen(),
          HabitBuilder.id: (context) => HabitBuilder(),
          HabitTracker.id: (context) => HabitTracker(),
          HabitPage.id: (context) => HabitPage(),
          HomePage.id: (context) => HomePage(),

          //MyApp.id: (context) => MyApp(),
          //WinScreen.id: (context) => WinScreen(),
          //ProgressScreen.id: (context) => ProgressScreen(),
          //LoginScreen.id: (context) => LoginScreen(),
        });
  }
}
