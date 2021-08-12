import 'package:habit_creator/constants.dart';
import 'package:habit_creator/models/video_info.dart';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:habit_creator/apis/encoding_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase;
import 'package:path/path.dart' as p;
import 'package:habit_creator/apis/firebase_provider.dart';

final thumbWidth = 170;
final thumbHeight = 150;
List<VideoInfo> videos = <VideoInfo>[];
bool imagePickerActive = false;
bool processing = false;
bool canceled = false;
double progress = 0.0;
int videoDuration = 0;
String processPhase = '';
final bool debugMode = false;

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

Future<String> _uploadHLSFiles(dirPath, videoName) async {
  final videosDir = Directory(dirPath);

  var playlistUrl = '';

  final files = videosDir.listSync();
  int i = 1;
  for (FileSystemEntity file in files) {
    final fileName = p.basename(file.path);

    // setState(() {
    processPhase = 'Uploading video file $i out of ${files.length}';
    progress = 0.0;
    // });

    final downloadUrl = await _uploadFile(file.path, videoName);

    playlistUrl = downloadUrl;
  }

  return playlistUrl;
}

void _onUploadProgress(event) {
  if (event.state == firebase.TaskState.running) {
    // final double progress = event.bytesTransferred / event.totalByteCount;
    // setState(() {
    //   _progress = progress;
    // });
  }
}

Future<void> processVideo(File rawVideoFile, String habitName, String user,
    int progressListIndex, int timesPerDay) async {
  final String rand = '${new Random().nextInt(10000000)}';
  final videoName = 'video$rand';

  final Directory extDir = await getApplicationDocumentsDirectory();
  final outDirPath = '${extDir.path}/Videos/$videoName';
  final videosDir = new Directory(outDirPath);
  videosDir.createSync(recursive: true);

  final rawVideoPath = rawVideoFile.path;
  final info = await EncodingProvider.getMediaInformation(rawVideoPath);
  final aspectRatio = EncodingProvider.getAspectRatio(info);

  // setState(() {
  processPhase = 'Generating thumbnail';
  videoDuration = EncodingProvider.getDuration(info);
  progress = 0.0;
  // });
  print('rawvideopath2');
  print(rawVideoPath);
  final thumbFilePath =
      await EncodingProvider.getThumb(rawVideoPath, thumbWidth, thumbHeight);

  // setState(() {
  processPhase = 'Encoding video';
  progress = 0.0;
  // });

  final encodedFilesDir =
      await EncodingProvider.encodeHLS(rawVideoPath, outDirPath);

  downloadedVideos[videoName] = globalVideo;

  // setState(() {
  processPhase = 'Uploading thumbnail to firebase storage';
  progress = 0.0;
  // });
  final thumbUrl = await _uploadFile(thumbFilePath, 'thumbnail');
  final videoUrl = await _uploadHLSFiles(encodedFilesDir, videoName);

  print(habitName);
  print(user);
  print(progressListIndex);
  final videoInfo = VideoInfo(
    videoUrl: videoUrl,
    thumbUrl: thumbUrl,
    coverUrl: thumbUrl,
    aspectRatio: aspectRatio,
    uploadedAt: DateTime.now().millisecondsSinceEpoch,
    videoName: videoName,
    habitName: habitName,
    user: user,
    progressListIndex: progressListIndex,
    timesPerDay: timesPerDay,
    videosVerified: 0,
    checked: null,
  );

  // setState(() {
  processPhase = 'Saving video metadata to cloud firestore';
  progress = 0.0;
  // });

  await FirebaseProvider.saveVideo(videoInfo);

  // setState(() {
  processPhase = '';
  progress = 0.0;
  processing = false;
  // });
}
