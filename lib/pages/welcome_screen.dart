import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:habit_creator/components/wide_button.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_creator/constants.dart';
import 'habit_page.dart';

class WelcomeScreen extends StatefulWidget {
  static String id = '/';

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation animation;
  bool skipped = true;

  void skipLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    globalUserId = await prefs.getString('userId');
    if (globalUserId != null) {
      Navigator.pushNamed(context, HabitPage.id);
      skipped = true;
    } else
      skipped = false;
  }

  @override
  void initState() {
    // TODO: implement initState
    //
    skipLogin();
    super.initState();
    Firebase.initializeApp();
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    controller.forward();
    animation = ColorTween(begin: Colors.blueGrey, end: Colors.blueGrey[100])
        .animate(controller);
    controller.addListener(() {
      setState(() {});
      print(animation.value);
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      body: !skipped
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Hero(
                          tag: 'logo',
                          child: Container(
                            child: Image.asset('images/portal.png'),
                            height: 90,
                          ),
                        ),
                      ),
                      Flexible(
                        child: TypewriterAnimatedTextKit(
                          text: ['Inspiration'],
                          textStyle: TextStyle(
                            fontSize: 34.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 24.0,
                  ),
                  WideButton(Colors.red[900], 'Start',
                      () => Navigator.pushNamed(context, '/register')),
                  SizedBox(height: 8),
                  WideButton(Colors.red[500], 'Log in', () {
                    //globalUserId = 'simon.toth@yahoo.com';
                    Navigator.pushNamed(context, LoginScreen.id);
                  }),
                ],
              ),
            )
          : Container(),
    );
  }
}
