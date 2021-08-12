import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'habit_tracker.dart';
import 'habit_page.dart';
import 'build_habit.dart';
import 'package:video_player/video_player.dart';

import 'dart:io';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:habit_creator/apis/encoding_provider.dart';
import 'package:habit_creator/apis/firebase_provider.dart';
import 'package:path/path.dart' as p;
import 'package:habit_creator/models/video_info.dart';
import 'package:habit_creator/widgets/player.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:habit_creator/apis/process_video.dart';

import 'package:habit_creator/components/bottom_navigation_bar.dart';

import 'package:habit_creator/constants.dart';

import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  static String id = '/home';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<String> _children = [HomePage.id, HabitPage.id, HabitTracker.id];
  bool showSpinner = false;
  bool disposed = false;
  VideoPlayerController _controller;
  File videoFile;
  List<String> downloading = [];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    FirebaseProvider.listenToVideos((newVideos) {
      if (mounted) {
        setState(() {
          videos = newVideos;
        });
      }
    });

    // EncodingProvider.enableStatisticsCallback((int time,
    //     int size,
    //     double bitrate,
    //     double speed,
    //     int videoFrameNumber,
    //     double videoQuality,
    //     double videoFps) {
    //   if (canceled) return;
    //
    //   if (mounted) {
    //     setState(() {
    //       progress = time / videoDuration;
    //     });
    //   }
    // });
  }

  void _onUploadProgress(event) {
    if (event.state == firebase.TaskState.running) {
      // final double progress = event.bytesTransferred / event.totalByteCount;
      // setState(() {
      //   _progress = progress;
      // });
    }
  }

  Future<String> _uploadFile(filePath, folderName) async {
    final file = File(filePath);
    final basename = p.basename(filePath);

    final Reference ref =
        FirebaseStorage.instance.ref().child(folderName).child(basename);
    UploadTask uploadTask = ref.putFile(file);
    uploadTask.snapshotEvents.listen(_onUploadProgress);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    String videoUrl = await taskSnapshot.ref.getDownloadURL();
    return videoUrl;
  }

  String getFileExtension(String fileName) {
    final exploded = fileName.split('.');
    return exploded[exploded.length - 1];
  }

  void _updatePlaylistUrls(File file, String videoName) {
    final lines = file.readAsLinesSync();
    var updatedLines = List<String>();

    for (final String line in lines) {
      var updatedLine = line;
      if (line.contains('.ts') || line.contains('.m3u8')) {
        updatedLine = '$videoName%2F$line?alt=media';
      }
      updatedLines.add(updatedLine);
    }
    final updatedContents =
        updatedLines.reduce((value, element) => value + '\n' + element);

    file.writeAsStringSync(updatedContents);
  }

  Future<String> _uploadHLSFiles(dirPath, videoName) async {
    final videosDir = Directory(dirPath);

    var playlistUrl = '';

    final files = videosDir.listSync();
    int i = 1;
    for (FileSystemEntity file in files) {
      final fileName = p.basename(file.path);

      setState(() {
        processPhase = 'Uploading video file $i out of ${files.length}';
        progress = 0.0;
      });

      final downloadUrl = await _uploadFile(file.path, videoName);

      playlistUrl = downloadUrl;
    }

    return playlistUrl;
  }

  void downloadVideo(var video) async {
    final request = await HttpClient().getUrl(Uri.parse(video.videoUrl));
    final response = await request.close();
    String dir = (await getApplicationDocumentsDirectory()).path;
    String videoName = video.videoName;
    if (!downloading.contains(video.videoName)) {
      downloading.add(video.videoName);
      print('DOWNLOADING ' + video.videoName);
      await response.pipe(File('$dir/$videoName.mp4').openWrite());
      downloadedVideos[video.videoName] = File('$dir/$videoName.mp4');
      print(video.videoName + ' DOWNLOADED');
    }
  }

  Future sleep() {
    return new Future.delayed(const Duration(milliseconds: 200), () => "1");
  }

  _getListView() {
    videos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: videos.length,
          itemBuilder: (BuildContext context, int index) {
            final video = videos[index];
            if (!downloadedVideos.containsKey(video.videoName)) {
              downloadVideo(video);
            } else {
              print('already downloaded ' + video.videoName);
            }

            return Card(
              color: Colors.blueGrey[200],
              elevation: 5,
              child: new Container(
                padding: new EdgeInsets.all(10.0),
                child: Stack(
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () async {
                            setState(() {
                              showSpinner = true;
                            });
                            print('PLAY VIDEO ' + video.videoName);

                            // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
                            while (downloadedVideos[video.videoName] == null) {
                              print('sleep');
                              await sleep();
                            }
                            _controller = await VideoPlayerController.file(
                                downloadedVideos[video.videoName])
                              ..initialize().then((_) {
                                print('controller video file initialized');
                              });

                            //_controller.setLooping(true);

                            showGeneralDialog(
                              context: context,
                              barrierColor: Colors.black12.withOpacity(0.6),
                              // background color
                              barrierDismissible: false,
                              // should dialog be dismissed when tapped outside
                              barrierLabel: "Dialog",
                              // label for barrier
                              transitionDuration: Duration(milliseconds: 500),
                              // how long it takes to popup dialog after button click
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
                                              _controller.pause();
                                              Navigator.pop(context);
                                            },
                                            onLongPress: () {
                                              setState(() {
                                                _controller.value.isPlaying
                                                    ? _controller.pause()
                                                    : _controller.play();
                                              });
                                            },
                                            child: AspectRatio(
                                              aspectRatio: video.aspectRatio,
                                              child: VideoPlayer(_controller),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                            setState(() {
                              showSpinner = false;
                            });
                            await sleep();
                            await sleep();
                            _controller.play();
                          },
                          child: Stack(
                            children: <Widget>[
                              Container(
                                width: thumbWidth.toDouble(),
                                height: thumbHeight.toDouble(),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                              ClipRRect(
                                borderRadius: new BorderRadius.circular(8.0),
                                child: FadeInImage.memoryNetwork(
                                  placeholder: kTransparentImage,
                                  image: video.thumbUrl,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: new EdgeInsets.only(left: 15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("${video.habitName}"),
                                Text("${video.videoName}"),
                                Container(
                                  margin: new EdgeInsets.only(top: 12.0),
                                  child: Text(
                                      'Uploaded ${timeago.format(new DateTime.fromMillisecondsSinceEpoch(video.uploadedAt))}'),
                                ),
                                SizedBox(height: 30),
                                Row(
                                  children: [
                                    //Expanded(child: SizedBox()),
                                    TextButton(
                                        onPressed: () async {
                                          setState(() {
                                            video.checked = false;
                                          });

                                          print('pressed Icon');
                                          print(video.user);
                                          print(video.habitName);
                                          print('videosVerified');
                                          print(video.videosVerified);

                                          print(video.timesPerDay);

                                          //update firebase record
                                          print(video.progressListIndex);

                                          var document = await firestore
                                              .collection(video.user)
                                              .doc(video.habitName)
                                              .get();
                                          var variables = document.data();
                                          firestore
                                              .collection('videos')
                                              .doc(video.videoUrl.substring(
                                                  video.videoUrl.length - 8))
                                              .update({'checked': false});

                                          var currentProgressList =
                                              variables['progressList'];
                                          currentProgressList[
                                              video.progressListIndex] = 3;
                                          firestore
                                              .collection(video.user)
                                              .doc(video.habitName)
                                              .update({
                                            'progressList': currentProgressList
                                          });
                                        },
                                        child: Icon(Icons.close,
                                            size: 60,
                                            color: video.checked != null
                                                ? !video.checked
                                                    ? Colors.green
                                                    : Colors.blue[100]
                                                : Colors.blue[100])),
                                    SizedBox(width: 10),
                                    TextButton(
                                        onPressed: () async {
                                          print('pressed Icon');
                                          setState(() {
                                            video.checked = true;
                                          });
                                          List videosVerified = [];
                                          print(video.progressListIndex);
                                          var document = await firestore
                                              .collection(video.user)
                                              .doc(video.habitName)
                                              .get();
                                          var variables = document.data();
                                          firestore
                                              .collection('videos')
                                              .doc(video.videoUrl.substring(
                                                  video.videoUrl.length - 8))
                                              .update({'checked': true});
                                          if (video.timesPerDay > 1) {
                                            try {
                                              videosVerified =
                                                  variables['videosVerified'];
                                              print(videosVerified[
                                                  video.progressListIndex]);
                                              if (videosVerified[video
                                                      .progressListIndex] >=
                                                  video.timesPerDay - 1) {
                                                var currentProgressList =
                                                    variables['progressList'];
                                                currentProgressList[video
                                                    .progressListIndex] = 2;
                                                firestore
                                                    .collection(video.user)
                                                    .doc(video.habitName)
                                                    .update({
                                                  'progressList':
                                                      currentProgressList
                                                });
                                              } else {
                                                videosVerified[
                                                    video.progressListIndex]++;
                                                firestore
                                                    .collection(video.user)
                                                    .doc(video.habitName)
                                                    .update({
                                                  'videosVerified':
                                                      videosVerified
                                                });
                                              }
                                            } catch (e) {
                                              while (true) {
                                                try {
                                                  videosVerified[video
                                                      .progressListIndex] = 1;
                                                  break;
                                                } catch (e) {
                                                  videosVerified.add(0);
                                                }
                                              }

                                              firestore
                                                  .collection(video.user)
                                                  .doc(video.habitName)
                                                  .update({
                                                'videosVerified': videosVerified
                                              });
                                            }
                                          } else {
                                            var currentProgressList =
                                                variables['progressList'];
                                            currentProgressList[
                                                video.progressListIndex] = 2;
                                            firestore
                                                .collection(video.user)
                                                .doc(video.habitName)
                                                .update({
                                              'progressList':
                                                  currentProgressList
                                            });
                                          }
                                        },
                                        child: Icon(Icons.check,
                                            size: 60,
                                            color: video.checked != null
                                                ? video.checked
                                                    ? Colors.green
                                                    : Colors.blue[100]
                                                : Colors.blue[100])),
                                    SizedBox(),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }

  _getProgressBar() {
    return Container(
      padding: EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: 30.0),
            child: Text(processPhase),
          ),
          LinearProgressIndicator(
            value: progress,
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;

      Navigator.pushNamed(context, _children[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      bottomNavigationBar: buildBottomNavigationBar(onTabTapped, _currentIndex),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Inspiration', style: TextStyle(fontSize: 21)),
        backgroundColor: Colors.blueGrey[500],
      ),
      body: Center(child: processing ? _getProgressBar() : _getListView()),
    );
  }
}
