import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_creator/models/video_info.dart';
import 'package:habit_creator/constants.dart';

class FirebaseProvider {
  static saveVideo(VideoInfo video) async {
    await firestore
        .collection('videos')
        .doc(video.videoUrl!.substring(video.videoUrl!.length - 8))
        .set({
      'videoUrl': video.videoUrl,
      'thumbUrl': video.thumbUrl,
      'coverUrl': video.coverUrl,
      'aspectRatio': video.aspectRatio,
      'uploadedAt': video.uploadedAt,
      'videoName': video.videoName,
      'habitName': video.habitName,
      'user': video.user,
      'progressListIndex': video.progressListIndex,
      'timesPerDay': video.timesPerDay,
      'videosVerified': video.videosVerified,
      'checked': video.checked,
    });
  }

  static listenToVideos(callback) async {
    firestore.collection('videos').snapshots().listen((qs) {
      final videos = mapQueryToVideoInfo(qs);
      callback(videos);
    });
  }

  static mapQueryToVideoInfo(QuerySnapshot qs) {
    return qs.docs.map((DocumentSnapshot ds) {
      return VideoInfo(
        videoUrl: ds.data()!['videoUrl'],
        thumbUrl: ds.data()!['thumbUrl'],
        coverUrl: ds.data()!['coverUrl'],
        aspectRatio: ds.data()!['aspectRatio'],
        videoName: ds.data()!['videoName'],
        uploadedAt: ds.data()!['uploadedAt'],
        habitName: ds.data()!['habitName'],
        user: ds.data()!['user'],
        progressListIndex: ds.data()!['progressListIndex'],
        timesPerDay: ds.data()!['timesPerDay'],
        videosVerified: ds.data()!['videosVerified'],
        checked: ds.data()!['checked'],
      );
    }).toList();
  }
}
