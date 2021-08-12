import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:habit_creator/components/bottom_navigation_bar.dart';

import 'package:video_player/video_player.dart';
import 'package:habit_creator/components/wide_button.dart';
import 'dart:core';
import 'package:habit_creator/constants.dart';

import 'package:path/path.dart' as Path;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:habit_creator/components/progress_footer.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

import 'habit_page.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:habit_creator/components/time_zone.dart';

import 'package:image_picker/image_picker.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as Path;
import 'package:flutter/services.dart';
import 'home_page.dart';

import 'package:habit_creator/apis/encoding_provider.dart';

import 'package:habit_creator/apis/process_video.dart';

class HabitTracker extends StatefulWidget {
  static String id = '/tracker';

  String payload;

  HabitTracker([this.payload]);

  @override
  _HabitTrackerState createState() => _HabitTrackerState(payload);
}

class _HabitTrackerState extends State<HabitTracker> {
  int _currentIndex = 2;
  final List<String> _children = [HomePage.id, HabitPage.id, HabitTracker.id];

  String payload;
  _HabitTrackerState(this.payload);
  final picker = ImagePicker();

  final _auth = FirebaseAuth.instance;
  File _cameraVideo;

  VideoPlayerController _cameraVideoPlayerController;

  int dayCount;
  bool uploaded = false;
  bool uploading = false;
  int video_index = 1;
  String day;
  DateTime startTime;
  int reminderFrequency;
  int timesPerDay;
  int timesPerDayProgress;
  int length;
  Map frequency;
  List progressList = [];
  String won;
  bool depositSent;
  int dayInt = 1;
  String startTimeString;
  Map variables;
  int timeFirstReminder;
  int habitNumber;
  String weekday;

  FlutterLocalNotificationsPlugin localNotification;

  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

  VideoPlayerController _controller;
  Directory tempDirectory;
  String assetPath;
  String output;
  String output2;
  String output3;
  Image displayImage;

  int confirmCount;



  @override
  void initState() {
    // TODO: implement initState

    super.initState();

    getImagesDirectory();

    getVariables();
    messagesStream();
  }

  _pickVideoFromCamera() async {
    PickedFile pickedFile = await picker.getVideo(source: ImageSource.camera);

    String video_path = pickedFile.path;
    File videoFile = File(video_path);
    setState(() {
      uploading = true;
      uploaded = false;
    });
    int progressIndex;
    if (timesPerDayProgress >= timesPerDay) {
      progressIndex = progressList.length - 1;
    } else {
      progressIndex = progressList.length;
    }
    await processVideo(videoFile, globalHabitName, loggedInUser.email,
        progressIndex, timesPerDay);

    // //String path1 = getImagePath('1.mp4');
    // String ff_output = getImagePath('output8' + video_index.toString());
    // String output_video_path = getImagePath('out8$video_index.mp4');
    // // String ffmpeg_code =
    // //     "-i $video_path -filter:v fps=fps=1/.3 $ff_output%03d.bmp";
    //
    // String ffmpeg_code =
    //     '-i $video_path -vf "scale=iw/2:ih/2"  $output_video_path';
    //
    // setState(() {
    //   uploading = true;
    //   uploaded = false;
    // });
    // await _flutterFFmpeg.execute(ffmpeg_code).then((code) {
    //   if (code == 0) {
    //     print('1 Done!');
    //   }
    // });
    //
    // //
    // //return "-i $path1 -filter:v fps=fps=1/10 $ff_output%d.bmp";
    // //
    //
    // // ffmpeg_code = "-framerate 24 -i $ff_output%03d.bmp $output_video_path";
    // //
    // // await _flutterFFmpeg.execute(ffmpeg_code).then((code) {
    // //   if (code == 0) {
    // //     print('2 Done!');
    // //   }
    // // });
    //
    // File video = File(output_video_path);
    //

    _controller = VideoPlayerController.file(globalVideo)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        //_controller.setLooping(true);
        setState(() {});
      });

    setState(() {
      uploading = false;
      uploaded = true;
    });
    //
    // video_index++;
    //
    // Reference storageReference;
    // UploadTask uploadTask;
    // String userId = loggedInUser.email;
    // var now = DateTime.now();
    // String nowDate = now.year.toString() +
    //     '-' +
    //     now.month.toString() +
    //     '-' +
    //     now.day.toString();
    // storageReference = FirebaseStorage.instance.ref().child(
    //     'videos/$userId/$nowDate/$globalHabitName/${Path.basename(output_video_path)}}');
    // print('after storage reference');
    // uploadTask = storageReference.putFile(video);
    // print('after path');
    //
    // setState(() {
    //   uploading = true;
    //   uploaded = false;
    // });
    //
    // await uploadTask.whenComplete(() => null);
    //
    // print('File Uploaded');
    // setState(() {
    //   uploading = false;
    //   uploaded = true;
    // });
  }

  Future onSelectNotification(String payld) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return HabitTracker(payld);
    }));
  }

  Future initializetimezone() async {
    tz.initializeTimeZones();
  }

  Future<void> scheduleShortNotification() async {
    var scheduledNotificationDateTime =
        DateTime.now().add(Duration(hours: reminderFrequency));

    //final timeZone = TimeZone();
    await initializetimezone();

    // The device's timezone.
    //String timeZoneName = await timeZone.getTimeZoneName();

    // Find the 'current location'
    //final location = await timeZone.getLocation(timeZoneName);

    // final scheduledDate =
    //     tz.TZDateTime.from(scheduledNotificationDateTime, location);
    tz.TZDateTime zonedTime = tz.TZDateTime.
    tz.TZDateTime zonedTime = tz.TZDateTime.local(year,month,day,hour,
        minute).subtract(offsetTime);

    var androidDetails = new AndroidNotificationDetails("channelId",
        "Local Notification", "This is the notification description");
    var iOSDetails = new IOSNotificationDetails();
    var generalNotificationDetails =
        new NotificationDetails(android: androidDetails, iOS: iOSDetails);
    await localNotification.zonedSchedule(
      habitNumber * 2,
      'Reminder',
      globalHabitName,
      scheduledDate,
      generalNotificationDetails,
      androidAllowWhileIdle: true,
      payload: 'short',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('done scheduling');
  }

  Future<void> scheduleLongNotification() async {
    int today = DateTime.now().weekday;
    int cnt = today;

    if (cnt == 8) {
      cnt = 1;
    }
    int daysLater = 1;
    for (var x = 0; x < 6; x++) {
      cnt++;
      print(cnt);
      if (cnt == 8) {
        cnt = 1;
      }
      print(cnt);
      print(frequency);
      print('after print frequency');
      if (frequency[cnt.toString()]) {
        daysLater = x + 1;
        break;
      }
    }
    var now = DateTime.now();

    var scheduledNotificationDateTime =
        DateTime(now.year, now.month, now.day + daysLater, timeFirstReminder);

    final timeZone = TimeZone();

    // The device's timezone.
    String timeZoneName = await timeZone.getTimeZoneName();

    // Find the 'current location'
    final location = await timeZone.getLocation(timeZoneName);

    final scheduledDate =
        tz.TZDateTime.from(scheduledNotificationDateTime, location);

    var androidDetails = new AndroidNotificationDetails("channelId",
        "Local Notification", "This is the notification description");
    var iOSDetails = new IOSNotificationDetails();
    var generalNotificationDetails =
        new NotificationDetails(android: androidDetails, iOS: iOSDetails);
    await localNotification.zonedSchedule(
      habitNumber * 2 + 1,
      'Reminder',
      globalHabitName,
      scheduledDate,
      generalNotificationDetails,
      androidAllowWhileIdle: true,
      payload: 'long',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  void messagesStream() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
    await for (var snapshot in firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .snapshots()) {
      variables = snapshot.data();

      await setState(() {
        won = variables['won'];
      });

      setState(() {
        progressList = progressList;
      });
      print(variables);
    }
  }

  void getVariables() async {
    var androidInitialize = new AndroidInitializationSettings('ic_launcher');

    //Ios
    var iOSinitialize = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        android: androidInitialize, iOS: iOSinitialize);
    localNotification = new FlutterLocalNotificationsPlugin();
    localNotification.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);

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
    print(globalHabitName);
    var document = await firestore
        .collection(loggedInUser.email)
        .doc(globalHabitName)
        .get();
    variables = document.data();
    print(variables);

    print('after get');

    startTime = DateTime.parse(variables['startTime']);
    print(startTime);
    DateTime now = DateTime.now().toLocal();

    weekday = now.weekday.toString();

    dayInt = (now.difference(startTime).inDays + 1);
    print(dayInt);
    progressList = variables['progressList'];
    length = variables['length'];

    timesPerDay = variables['timesPerDay'];
    reminderFrequency = variables['reminderFrequency'];
    timeFirstReminder = variables['timeFirstReminder'];

    timesPerDayProgress = variables['timesPerDayProgress'];
    habitNumber = variables['habitNumber'];

    var newDayTracker = variables['newDayTracker'];
    print('newDayTracker');
    print(newDayTracker);
    if (newDayTracker == null) {
      newDayTracker = 1;
    }
    if (newDayTracker < dayInt) {
      newDayTracker = dayInt;
      timesPerDayProgress = 0;
      firestore
          .collection(loggedInUser.email)
          .doc(globalHabitName)
          .update({'newDayTracker': newDayTracker});
      firestore
          .collection(loggedInUser.email)
          .doc(globalHabitName)
          .update({'timesPerDayProgress': timesPerDayProgress});
    }
    frequency = variables['frequency'];

    if (dayInt + 1 > progressList.length) {
      for (int x = progressList.length + 1; x < dayInt; x++) {
        progressList.add(0);
      }
    }
    dayCount = 1;
    confirmCount = 0;
    int weekdayCount = int.parse(weekday);
    print('progressList.length');
    print(progressList.length);
    for (int x = progressList.length; x > 0; x--) {
      print('xxx');
      print(x);
      if (frequency[weekdayCount.toString()]) {
        if (progressList[x - 1] == 2) {
          confirmCount++;
        }
        if (progressList[x - 1] == 1 || progressList[x - 1] == 2) {
          dayCount++;
          print('daycount++');
        } else {
          break;
        }
      }
      weekdayCount--;
      if (weekdayCount == 0) {
        weekdayCount = 7;
      }
    }
    print('dayCount');
    print(dayCount);

    video_index = int.parse(dayInt.toString() + timesPerDayProgress.toString());
    //schedule reminders

    if ((timesPerDay > 1) & (timesPerDayProgress < timesPerDay)) {
      scheduleShortNotification();
      print('scheduleShort');
    }

    print(DateTime.now());
    if ((payload == null) | (payload == 'long')) {
      scheduleLongNotification();
      print('schedullong');
    }

    print('progresslength' + progressList.length.toString());
    setState(() {
      print(dayInt);
      won = variables['won'];
      day = dayInt.toString();
      globalHabitName = variables['habit'];
      progressList = progressList;
      timesPerDayProgress = timesPerDayProgress;
      startTime = DateTime.parse(variables['startTime']);
      if (dayInt == progressList.length) {
        uploaded = true;
      }
    });

    if (won == 'try') {
      startTime = startTime.add(new Duration(days: 1));
      startTimeString = startTime.toString();
      firestore
          .collection(loggedInUser.email)
          .doc(globalHabitName)
          .update({'startTime': startTime});
    } else if (won == 'won') {
    } else if (won == 'lost') {}
  }

  _pickFile() async {
    print(kIsWeb);

    FilePickerResult result = await FilePicker.platform.pickFiles();
    print('after result');
    //print(result.files.single.bytes);

    await uploadFile(result);
    //uploadFile(File(result.files.single.path));
  }

  getImagesDirectory() async {
    tempDirectory = await getTemporaryDirectory();
    // setFontconfigConfigurationPath(tempDirectory.path);
    print(tempDirectory.path);
    print('print temp directory');
  }

  getImagePath(String assetName) {
    return Path.join(tempDirectory.path, assetName);
  }

  Future<File> copyFileAssets(String assetName, String localName) async {
    final ByteData assetByteData = await rootBundle.load(assetName);

    final List<int> byteList = assetByteData.buffer
        .asUint8List(assetByteData.offsetInBytes, assetByteData.lengthInBytes);

    final String fullTemporaryPath = Path.join(tempDirectory.path, localName);

    return File(fullTemporaryPath)
        .writeAsBytes(byteList, mode: FileMode.writeOnly, flush: true);
  }

  //
  // Future<void> setFontconfigConfigurationPath(String path) async {
  //   return await _flutterFFmpeg.setFontconfigConfigurationPath(path);
  // }

  prepareAssetsPath() {
    copyFileAssets('assets/1.mp4', '1.mp4')
        .then((path) => print('Loaded asset $path.'));
    copyFileAssets('assets/graduation.png', '2.png')
        .then((path) => print('Loaded asset $path.'));
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      Navigator.pushNamed(context, _children[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    //userId != null ? getVariables() : '';
    double c_width = MediaQuery.of(context).size.width * 0.8;
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      bottomNavigationBar: buildBottomNavigationBar(onTabTapped, _currentIndex),
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.blueGrey[500],
          // leading: IconButton(
          //   icon: Icon(Icons.home, size: 35, color: Colors.black),
          //   onPressed: () {
          //     Navigator.pushNamed(context, HabitPage.id);
          //   },
          // ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  globalHabitName != null
                      ? Text(globalHabitName, style: TextStyle(fontSize: 19))
                      : Container()
                ],
              ),
            ],
          )),
      body: frequency != null
          ? SafeArea(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: (won != 'lost') & (won != 'won')
                      ? Column(
                          children: [
                            SizedBox(height: 10),
                            Visibility(
                              visible: won == 'try',
                              child: Flexible(
                                child: Text('Video not accepted, try again',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: Colors.lightBlue,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                dayCount > length
                                    ? Column(children: [
                                        confirmCount >= length
                                            ? Text('Habit complete'.toString(),
                                                style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 30,
                                                    fontWeight:
                                                        FontWeight.bold))
                                            : Text(
                                                '      Habit complete\nAwaiting confirmation'
                                                    .toString(),
                                                style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 30,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                        SizedBox(height: 8),
                                        confirmCount >= length
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                width: c_width,
                                                child: Text(
                                                    'Your deposit will be refunded automatically to your original payment method. Please allow 7 business days for this to be reflected on your statement'
                                                        .toString(),
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 18,
                                                    )),
                                              )
                                            : Container(),
                                      ])
                                    : dayInt <= progressList.length
                                        ? Text('Day complete'.toString(),
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold))
                                        : day != null
                                            ? Text('Day ' + dayCount.toString(),
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 30,
                                                    fontWeight:
                                                        FontWeight.bold))
                                            : Text('Day ',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 30,
                                                    fontWeight:
                                                        FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 5),
                            !uploaded & frequency[weekday] &&
                                    dayInt > progressList.length
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(child: SizedBox()),
                                      Expanded(
                                        flex: 3,
                                        child: FittedBox(
                                          fit: BoxFit.fitWidth,
                                          child: Text('Time Remaining:',
                                              style: TextStyle(
                                                  color: Colors.black)),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      startTime != null
                                          ? Expanded(
                                              flex: 2,
                                              child: FittedBox(
                                                fit: BoxFit.fitWidth,
                                                child: CountdownTimer(
                                                  textStyle: TextStyle(
                                                      color: Colors.black),
                                                  endTime: startTime
                                                      .add(Duration(
                                                          days: dayInt))
                                                      .millisecondsSinceEpoch,
                                                ),
                                              ),
                                            )
                                          : Container(),
                                      Expanded(child: SizedBox()),
                                    ],
                                  )
                                : Container(),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [],
                            ),
                            SizedBox(height: 5),
                            !kIsWeb
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 1.0),
                                        child: dayInt > progressList.length
                                            ? FloatingActionButton(
                                                backgroundColor:
                                                    Colors.red[800],
                                                onPressed: () async {
                                                  await _pickVideoFromCamera();
                                                  if ((progressList.length <
                                                          dayInt) &
                                                      (timesPerDay == 1)) {
                                                    progressList.add(1);
                                                  }
                                                  if (timesPerDay > 1) {
                                                    setState(() {
                                                      timesPerDayProgress++;
                                                    });
                                                    firestore
                                                        .collection(
                                                            loggedInUser.email)
                                                        .doc(globalHabitName)
                                                        .update({
                                                      'timesPerDayProgress':
                                                          timesPerDayProgress
                                                    });
                                                  }
                                                  if (timesPerDay ==
                                                      timesPerDayProgress) {
                                                    progressList.add(1);
                                                  }

                                                  firestore
                                                      .collection(
                                                          loggedInUser.email)
                                                      .doc(globalHabitName)
                                                      .update({
                                                    'progressList': progressList
                                                  });
                                                  setState(() {
                                                    progressList = progressList;
                                                  });
                                                },
                                                heroTag: 'video1',
                                                tooltip: 'Take a Video',
                                                child: Icon(Icons.videocam,
                                                    color: Colors.white),
                                              )
                                            : Container(),
                                      ),
                                    ],
                                  )
                                : !uploaded
                                    ? WideButton(
                                        Colors.red,
                                        'Upload a video',
                                        () async {
                                          await _pickFile();
                                          progressList.add(1);
                                          firestore
                                              .collection(loggedInUser.email)
                                              .doc(globalHabitName)
                                              .update({
                                            'progressList': progressList
                                          });
                                        },
                                      )
                                    : Container(),
                            //timesPerDay > 1
                            //?
                            SizedBox(height: 5),
                            _controller != null
                                ? _controller.value.isInitialized
                                    ? Flexible(
                                        flex: 7,
                                        child: TextButton(
                                          onPressed: () {
                                            showGeneralDialog(
                                              context: context,
                                              barrierColor: Colors.black12
                                                  .withOpacity(
                                                      0.6), // background color
                                              barrierDismissible:
                                                  false, // should dialog be dismissed when tapped outside
                                              barrierLabel:
                                                  "Dialog", // label for barrier
                                              transitionDuration: Duration(
                                                  milliseconds:
                                                      400), // how long it takes to popup dialog after button click
                                              pageBuilder: (_, __, ___) {
                                                // your widget implementation
                                                return SizedBox.expand(
                                                  // makes widget fullscreen
                                                  child: Column(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: SizedBox.expand(
                                                          child: TextButton(
                                                            onPressed: () {
                                                              _controller
                                                                  .pause();
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            onLongPress: () {
                                                              setState(() {
                                                                _controller
                                                                        .value
                                                                        .isPlaying
                                                                    ? _controller
                                                                        .pause()
                                                                    : _controller
                                                                        .play();
                                                              });
                                                            },
                                                            child: AspectRatio(
                                                              aspectRatio:
                                                                  _controller
                                                                      .value
                                                                      .aspectRatio,
                                                              child: VideoPlayer(
                                                                  _controller),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                            _controller.play();
                                          },
                                          onLongPress: () {
                                            setState(() {
                                              _controller.value.isPlaying
                                                  ? _controller.pause()
                                                  : _controller.play();
                                            });
                                          },
                                          child: AspectRatio(
                                            aspectRatio:
                                                _controller.value.aspectRatio,
                                            child: VideoPlayer(_controller),
                                          ),
                                        ),
                                      )
                                    : Container()
                                : dayInt > progressList.length
                                    ? Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: RawMaterialButton(
                                          onPressed: () {
                                            if ((progressList.length < dayInt) &
                                                (timesPerDay == 1)) {
                                              progressList.add(1);
                                            }
                                            if (timesPerDay > 1) {
                                              setState(() {
                                                timesPerDayProgress++;
                                              });
                                              firestore
                                                  .collection(
                                                      loggedInUser.email)
                                                  .doc(globalHabitName)
                                                  .update({
                                                'timesPerDayProgress':
                                                    timesPerDayProgress
                                              });
                                            }
                                            if (timesPerDay ==
                                                timesPerDayProgress) {
                                              progressList.add(1);
                                            }

                                            firestore
                                                .collection(loggedInUser.email)
                                                .doc(globalHabitName)
                                                .update({
                                              'progressList': progressList
                                            });
                                            setState(() {
                                              progressList = progressList;
                                            });
                                          },
                                          elevation: 2.0,
                                          fillColor:
                                              Color.fromRGBO(64, 75, 96, .9),
                                          child: Icon(
                                            Icons.add,
                                            size: 70.0,
                                            color: Colors.white,
                                          ),
                                          padding: EdgeInsets.only(
                                              right: 60.0,
                                              left: 60.0,
                                              top: 60.0,
                                              bottom: 60.0),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  new BorderRadius.circular(
                                                      30.0)),
                                        ))
                                    : Container(),
                            //: Container(),
                            timesPerDay > 1 && dayInt > progressList.length
                                ? Visibility(
                                    visible: !uploading,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                          '$timesPerDayProgress/$timesPerDay',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 30,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                : Container(),
                            Visibility(
                              visible: true,
                              child: CountdownTimer(
                                textStyle:
                                    TextStyle(color: Colors.blueGrey[100]),
                                onEnd: () {
                                  print('ended');
                                  setState(() {
                                    uploaded = false;
                                    dayInt++;
                                    timesPerDayProgress = 0;

                                    day = dayInt.toString();
                                    if (dayInt + 1 > progressList.length) {
                                      for (int x = progressList.length + 1;
                                          x < dayInt;
                                          x++) {
                                        progressList.add(0);
                                      }
                                    }
                                  });
                                  firestore
                                      .collection(loggedInUser.email)
                                      .doc(globalHabitName)
                                      .update({
                                    'timesPerDayProgress': timesPerDayProgress
                                  });
                                },
                                endTime: startTime
                                    .add(Duration(days: dayInt))
                                    .millisecondsSinceEpoch,
                              ),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Visibility(
                              visible: !uploaded & (_cameraVideo != null),
                              child: WideButton(Colors.red, 'Submit Video', () {
                                uploadFile(_cameraVideo);

                                _cameraVideoPlayerController =
                                    VideoPlayerController.file(_cameraVideo)
                                      ..initialize().then((_) {
                                        setState(() {
                                          _cameraVideoPlayerController.play();
                                          progressList.add(1);
                                        });
                                      });
                                firestore
                                    .collection(loggedInUser.email)
                                    .doc('variables')
                                    .update({'progressList': progressList});
                              }),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Visibility(
                                  visible: uploading,
                                  child: Text('Processing and uploading..',
                                      style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.deepOrange)),
                                ),
                                dayCount <= length
                                    ? Visibility(
                                        visible: uploaded,
                                        child: Flexible(
                                          child: Text('Upload complete',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontSize: 22,
                                                  color: Colors.lightBlue,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      )
                                    : Container(),
                              ],
                            ),

                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: FractionalOffset.bottomCenter,
                                child: Row(
                                  children: progressList != null
                                      ? progressCircles(
                                          progressList, frequency, weekday)
                                      : [],
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                          ],
                        )
                      : won == 'won'
                          ? Column(
                              children: [
                                Flexible(
                                  child: Text('Challenge Completed',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.lightBlue,
                                          fontWeight: FontWeight.bold)),
                                ),
                                WideButton(Colors.red, 'Withdraw deposit', () {
                                  depositSent = true;
                                }),
                                Visibility(
                                  visible: depositSent,
                                  child: Flexible(
                                    child: Text(
                                        'Your deposit will be returned to your PayPal account within 24 hours',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 22,
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(height: 10),
                                Center(
                                  child: Text('Challenge Failed',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.black54,
                                          fontWeight: FontWeight.bold)),
                                ),
                                WideButton(Colors.red, 'Start again now', () {
                                  setState(() {
                                    var now = DateTime.now().toLocal();

                                    startTime =
                                        DateTime(now.year, now.month, now.day);

                                    progressList = [];
                                    uploaded = false;
                                    day = '1';
                                    won = '';
                                  });
                                  startTimeString = startTime.toString();
                                  firestore
                                      .collection(loggedInUser.email)
                                      .doc(globalHabitName)
                                      .update({'startTime': startTimeString});
                                  firestore
                                      .collection(loggedInUser.email)
                                      .doc(globalHabitName)
                                      .update({'day': day});
                                  firestore
                                      .collection(loggedInUser.email)
                                      .doc(globalHabitName)
                                      .update({'progressList': progressList});
                                  firestore
                                      .collection(loggedInUser.email)
                                      .doc(globalHabitName)
                                      .update({'won': ''});
                                })
                              ],
                            )),
            )
          : Center(
              child: CircularProgressIndicator(backgroundColor: Colors.white)),
    );
  }

  Future uploadFile(var file) async {
    print('before path');
    Reference storageReference;
    UploadTask uploadTask;
    String userId = loggedInUser.email;
    var now = DateTime.now();
    String nowDate = now.year.toString() +
        '-' +
        now.month.toString() +
        '-' +
        now.day.toString();
    if (kIsWeb) {
      storageReference = FirebaseStorage.instance.ref().child(
          'videos/$userId/$nowDate/$globalHabitName/${Path.basename(file.files.single.name)}}');
      print('after path');
      uploadTask = storageReference.putData(file.files.single.bytes);
    } else {
      storageReference = FirebaseStorage.instance.ref().child(
          'videos/$userId/$nowDate/$globalHabitName/${Path.basename(file)}}');
      print('after storage reference');
      uploadTask = storageReference.putData(file);
      print('after path');
    }
    setState(() {
      uploading = true;
      uploaded = false;
    });

    await uploadTask.whenComplete(() => null);

    print('File Uploaded');
    setState(() {
      uploading = false;
      uploaded = true;
    });

    storageReference.getDownloadURL().then((fileURL) {
      firestore
          .collection(loggedInUser.email)
          .doc(globalHabitName)
          .update({'videoUrl': fileURL});
    });
  }
}
