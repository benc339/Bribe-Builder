import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:core';

import 'package:habit_creator/constants.dart';
import 'build_habit.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:habit_creator/components/habit_card.dart';

import 'home_page.dart';

import 'habit_tracker.dart';

import 'package:habit_creator/components/bottom_navigation_bar.dart';

User loggedInUser;

class HabitPage extends StatefulWidget {
  static String id = '/habits';

  @override
  _HabitPageState createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _auth = FirebaseAuth.instance;
  List habitList = [];
  bool doneLoading = false;

  int _currentIndex = 1;
  final List<String> _children = [HomePage.id, HabitPage.id, HabitTracker.id];

  String capitalize(String string) {
    if (string.isEmpty) {
      return string;
    }

    return string[0].toUpperCase() + string.substring(1);
  }

  void getHabits() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
    print('before firestore');
    // var document =
    //     await firestore.collection(loggedInUser.email).doc('variables').get();

    await for (var snapshot in firestore
        .collection(loggedInUser.email)
        .doc('variables')
        .snapshots()) {
      Map variables = snapshot.data();
      //Map variables = document.data();

      List collection = variables['habitList'];
      print('collection:');
      print(collection);
      setState(() {
        doneLoading = true;
      });

      List mapList = [];
      DateTime now = DateTime.now().toLocal();
      String weekday = now.weekday.toString();
      for (String doc in collection) {
        var document =
            await firestore.collection(loggedInUser.email).doc(doc).get();

        print('x');
        print(document.data());
        if (document.id == 'variables') continue;
        var map = document.data();
        print('add habit');
        Habit habit = new Habit(map);
        await habit.init();
        if (globalHabitName == null) {
          globalHabitName = habit.habitName;
        }

        habitList.add(habit);

        print('after add habit');
        setState(() {
          doneLoading = true;
        });
      }
    }
  }

  Widget topAppBar() => AppBar(
        elevation: 0.3,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey[500],
        title: Text('Habits', style: TextStyle(fontSize: 21)),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 14.0),
            child: IconButton(
              icon: Icon(Icons.add, size: 35),
              onPressed: () {
                Navigator.pushNamed(context, HabitBuilder.id);
              },
            ),
          )
        ],
      );

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      Navigator.pushNamed(context, _children[index]);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    getHabits();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: topAppBar(),
      bottomNavigationBar: buildBottomNavigationBar(onTabTapped, _currentIndex),
      backgroundColor: Colors.blueGrey[100],
      body: doneLoading
          ? makeBody(habitList, context)
          : Center(
              child: CircularProgressIndicator(backgroundColor: Colors.white)),
    );
  }
}
