import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:habit_creator/components/wide_button.dart';
import 'package:habit_creator/constants.dart';

import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'dart:core';
import 'package:habit_creator/components/alert_box.dart';

import 'habit_tracker.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:stripe_payment/stripe_payment.dart';
import 'package:http/http.dart' as http;

late User loggedInUser;

class HabitBuilder extends StatefulWidget {
  static String id = '/builder';

  @override
  _HabitBuilderState createState() => _HabitBuilderState();
}

class _HabitBuilderState extends State<HabitBuilder> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final _auth = FirebaseAuth.instance;
  bool showSpinner = false;
  bool paymentFailed = false;
  late double money;
  int timesPerDay = 0;
  int reminderFrequency = 0;
  late int length;
  late String startTime;
  late String orderId;
  late String weekday;
  int timeFirstReminder = 8;
  double costPrice = 1.0;
  bool isLoading = false;
  int amount = 0;

  var _errorString = '';
  late PaymentMethod _paymentMethod;
  late String _paymentIntentClientSecret;
  late PaymentIntentResult _paymentIntent;
  bool _error = false;
  late String _pubKey;

  Map frequency = {
    '1': true,
    '2': true,
    '3': true,
    '4': true,
    '5': true,
    '6': true,
    '7': true,
  };

  getPubKey() async {
    try {
      final keyUrl =
          "https://us-central1-bribe-builder.cloudfunctions.net/pub_key";
      final http.Response response = await http.post(
        Uri.parse(keyUrl),
      );
      final responseData = jsonDecode(response.body);
      final String pubKey = responseData['publishable_key'];
      setState(() {
        _pubKey = pubKey;
      });
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
    StripePayment.setOptions(
      StripeOptions(publishableKey: _pubKey),
    );
  }

  String capitalize(String string) {
    if (string.isEmpty) {
      return string;
    }

    return string[0].toUpperCase() + string.substring(1);
  }

  void initVariables() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
    globalHabitName = capitalize(globalHabitName);
    var document =
        await firestore.collection(loggedInUser.email!).doc('variables').get();
    Map variables = document.data()!;
    List habitList = variables['habitList'];
    if (habitList != null) {
      habitList.add(globalHabitName);
    } else {
      habitList = [globalHabitName];
    }
    int habitNumber = habitList.length;

    await firestore
        .collection(loggedInUser.email!)
        .doc('variables')
        .update({'habitList': habitList});
    await firestore
        .collection(loggedInUser.email!)
        .doc(globalHabitName)
        .set({'habit': globalHabitName});
    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'frequency': frequency});
    await firestore
        .collection(loggedInUser.email!)
        .doc(globalHabitName)
        .update({'money': money});
    await firestore
        .collection(loggedInUser.email!)
        .doc(globalHabitName)
        .update({'length': length});

    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'progressList': []});
    print('before won');
    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'won': ''});
    print('after won');
    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'orderId': orderId});
    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'reminderFrequency': reminderFrequency});
    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'timesPerDay': timesPerDay});
    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'timesPerDayProgress': 0});
    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'timeFirstReminder': timeFirstReminder});
    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'habitNumber': habitNumber});
    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'videosVerified': []});

    var now = DateTime.now();
    now = now.toLocal();
    weekday = now.weekday.toString();
    var lastMidnight = DateTime(now.year, now.month, now.day);
    startTime = lastMidnight.toString();

    await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .update({'startTime': startTime});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _paymentIntent = null;
    _paymentMethod = null;
    _paymentIntentClientSecret = null;
    getPubKey();
  }

  void setError(dynamic errorString) {
    print(errorString);
    _scaffoldKey.currentState
        .showSnackBar(SnackBar(content: Text(errorString.toString())));
    setState(() {
      _errorString = errorString;
    });
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
          child: ListView(
            //mainAxisAlignment: MainAxisAlignment.center,
            //crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Hero(
                tag: 'logo',
                child: Container(
                  height: 100.0,
                  child: Image.asset('images/portal.png'),
                ),
              ),
              Text(
                //'Most of us would like to improve ourselves but the hard part is getting our future self to repeatedly do what we would like it to.  We can bribe our future self with this app.  Studies have shown this method to be highly effective.',
                'Bribe Builder',
                style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[950]),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 24.0,
              ),
              WideButton(
                Colors.red[500],
                //'Most of us would like to improve ourselves but the hard part is getting our future self to repeatedly do what we would like it to.  We can bribe our future self with this app.  Studies have shown this method to be highly effective.',
                "See Rules",

                () {
                  showAlert(context);
                },
              ),
              SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.text,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  globalHabitName = value;
                },
                decoration: kInputDecoration.copyWith(hintText: 'Enter habit'),
              ),
              SizedBox(
                height: 8.0,
              ),
              TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  length = int.parse(value);
                },
                decoration:
                    kInputDecoration.copyWith(hintText: 'For how many days?'),
              ),
              SizedBox(
                height: 8.0,
              ),
              TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  setState(() {
                    timesPerDay = int.parse(value);
                  });
                },
                decoration: kInputDecoration.copyWith(
                    hintText: 'How many times a day?'),
              ),
              SizedBox(
                height: 8.0,
              ),
              TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  setState(() {
                    amount = int.parse(value);
                  });
                },
                decoration:
                    kInputDecoration.copyWith(hintText: 'Bribe amount?'),
              ),
              SizedBox(
                height: 8.0,
              ),
              Visibility(
                visible: (timesPerDay > 1),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    reminderFrequency = int.parse(value);
                  },
                  decoration: kInputDecoration.copyWith(
                      hintText: 'Send a reminder every how many hours?'),
                ),
              ),
              SizedBox(
                height: 8.0,
              ),
              Visibility(
                visible: (timesPerDay > 1),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    timeFirstReminder = int.parse(value);
                  },
                  decoration: kInputDecoration.copyWith(
                      hintText: 'Time of first reminder?'),
                ),
              ),
              SizedBox(
                height: 8.0,
              ),
              Text('Select days of the week',
                  style: TextStyle(fontSize: 18.0, color: Colors.deepPurple)),
              SizedBox(
                height: 5.0,
              ),
              Row(
                children: [
                  Flexible(child: daySelector('7')),
                  SizedBox(width: 3),
                  Flexible(child: daySelector('1')),
                  SizedBox(width: 3),
                  Flexible(child: daySelector('2')),
                  SizedBox(width: 3),
                  Flexible(child: daySelector('3')),
                  SizedBox(width: 3),
                  Flexible(child: daySelector('4')),
                  SizedBox(width: 3),
                  Flexible(child: daySelector('5')),
                  SizedBox(width: 3),
                  Flexible(child: daySelector('6')),
                ],
              ),
              SizedBox(
                height: 12,
              ),
              WideButton(
                  Colors.red[900],
                  amount != 0
                      ? 'Deposit \$$amount and begin'
                      : 'Deposit and begin', () async {
                setState(() {
                  showSpinner = true;
                });
                _paymentIntent = null;
                _paymentMethod = null;
                _paymentIntentClientSecret = null;
                await StripePayment.paymentRequestWithCardForm(
                  CardFormPaymentRequest(),
                ).then(
                  (paymentMethod) {
                    setState(() {
                      _paymentMethod = paymentMethod;
                    });
                    print('card request done');
                  },
                ).catchError(setError);

                print('after card request');
                //Send Payment
                final String cpiUrl =
                    'https://us-central1-bribe-builder.cloudfunctions.net/create_payment_intent';
                final finalAmount = amount * 100;
                final String currency = "USD";
                final String finalUrl =
                    '$cpiUrl?amount=$finalAmount&currency=$currency';
                final http.Response response = await http.post(
                  Uri.parse(finalUrl),
                );
                final responseData = jsonDecode(response.body);
                final String pics = responseData['clientSecret'];
                setState(() {
                  _paymentIntentClientSecret = pics;
                });
                bool success = false;
                print(pics);

                //Confirm
                await StripePayment.confirmPaymentIntent(PaymentIntent(
                        clientSecret: _paymentIntentClientSecret,
                        paymentMethodId: _paymentMethod.id))
                    .then((paymentIntent) {
                  setState(() {
                    _paymentIntent = paymentIntent;
                  });
                  success = true;
                }).catchError(setError);

                if (success) {
                  await initVariables();
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.setString('userId', loggedInUser.email);
                  setState(() {
                    showSpinner = false;
                  });
                  Navigator.pushNamed(context, HabitTracker.id);
                } else {
                  print('payment failed');
                  setState(() {
                    paymentFailed = true;
                  });
                }

                // await redirectToCheckout(context)
                // await Navigator.of(context).push(
                //   MaterialPageRoute(
                //     builder: (BuildContext context) => PaypalPayment(
                //       amount: money,
                //       onFinish: (number) async {
                //         // payment done
                //         print('order id: ' + number);
                //         orderId = number;
                //       },
                //     ),
                //   ),
                // );
                //await redirectToCheckout(context, money.toInt());
              }),
              paymentFailed == true
                  ? Text('Payment failed',
                      style: TextStyle(fontSize: 18.0, color: Colors.red))
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Row daySelector(String weekday) {
    Map dayMap = {
      '1': 'M',
      '2': 'T',
      '3': 'W',
      '4': 'T',
      '5': 'F',
      '6': 'S',
      '7': 'S'
    };
    return Row(
      children: [
        frequency[weekday]
            ? Flexible(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      frequency[weekday] = !frequency[weekday];
                    });
                  },
                  child: Container(
                    height: 49,
                    width: 49,
                    decoration: BoxDecoration(
                        border: Border.all(width: 2, color: Colors.deepPurple),
                        shape: BoxShape.circle,
                        color: Colors.blueGrey[100]),
                    child: Center(
                      child: Text(dayMap[weekday],
                          style: TextStyle(
                              fontSize: 16.0, color: Colors.deepPurple)),
                    ),
                  ),
                ),
              )
            : InkWell(
                onTap: () {
                  setState(() {
                    frequency[weekday] = !frequency[weekday];
                  });
                },
                child: Container(
                  height: 49,
                  width: 49,
                  decoration: BoxDecoration(
                      border: Border.all(width: 2, color: Colors.blueGrey[100]),
                      shape: BoxShape.circle,
                      color: Colors.blueGrey[100]),
                  child: Center(
                    child: Text(dayMap[weekday],
                        style:
                            TextStyle(fontSize: 16.0, color: Colors.black54)),
                  ),
                ),
              ),
      ],
    );
  }
}
