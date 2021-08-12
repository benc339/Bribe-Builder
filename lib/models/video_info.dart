import 'dart:io';

class VideoInfo {
  String ?videoUrl;
  String ?thumbUrl;
  String ?coverUrl;
  double ?aspectRatio;
  int ?uploadedAt;
  String ?videoName;
  String ?habitName;
  String ?user;
  int ?progressListIndex;
  int ?timesPerDay;
  int ?videosVerified;
  bool ?checked;
  File ?videoFile;

  VideoInfo(
      {this.videoUrl,
      this.thumbUrl,
      this.coverUrl,
      this.aspectRatio,
      this.uploadedAt,
      this.videoName,
      this.habitName,
      this.user,
      this.progressListIndex,
      this.timesPerDay,
      this.videosVerified,
      this.checked,
      this.videoFile,
      });
}
