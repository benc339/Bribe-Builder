import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

late String globalUserId;
late String globalHabitName;
late File globalVideo;

Map downloadedVideos = {};

final firestore = FirebaseFirestore.instance;

const kSendButtonTextStyle = TextStyle(
  color: Colors.lightBlueAccent,
  fontWeight: FontWeight.bold,
  fontSize: 18.0,
);

const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  hintText: 'Type your message here...',
  border: InputBorder.none,
);

const kMessageContainerDecoration = BoxDecoration(
  border: Border(
    top: BorderSide(color: Colors.lightBlueAccent, width: 2.0),
  ),
);

const kInputDecoration = InputDecoration(
  hintText: 'Enter your password.',
  hintStyle: TextStyle(color: Colors.black54),
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.black, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.black, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
);

const apiKey =
    'pk_live_51ISUNqL5eupYTfavhrKxG5PkFmTi2PTwXX7z8mDn9Cj8q3hdWDc9sZB4u4wAGJOJilcigdfY3GiZBJaE2tDhTIdU00IXPDCvzL';
const secretKey =
    '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';
const nikesPriceId = 'price_1ISVb7L5eupYTfavmg1wf8F0';
