import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/media_information.dart';
import 'package:habit_creator/constants.dart';

removeExtension(String path) {
  final str = path.substring(0, path.length - 4);
  return str;
}

class EncodingProvider {
  static final FlutterFFmpeg _encoder = FlutterFFmpeg();
  static final FlutterFFprobe _probe = FlutterFFprobe();
  static final FlutterFFmpegConfig _config = FlutterFFmpegConfig();

  static Future<String> encodeHLS(videoPath, outDirPath) async {
    assert(File(videoPath).existsSync());

    final arguments = '-i $videoPath ' +
        '-filter:v "setpts=0.1*PTS" -an ' +
        '$outDirPath/master.mp4';

    final int rc = await _encoder.execute(arguments);
    assert(rc == 0);

    globalVideo = File('$outDirPath/master.mp4');

    return outDirPath;
  }

  static double getAspectRatio(MediaInformation info) {
    final int width = info.getMediaProperties()!['streams'][0]['width'];
    final int height = info.getMediaProperties()!['streams'][0]['height'];
    final double aspect = height / width;
    return aspect;
  }

  static Future<String> getThumb(videoPath, width, height) async {
    assert(File(videoPath).existsSync());

    final String outPath = '$videoPath.jpg';
    final arguments =
        '-y -i $videoPath -vframes 1 -an -filter:v "scale=$width:-1,crop=$width:$height" -ss 1 $outPath';

    final int rc = await _encoder.execute(arguments);
    assert(rc == 0);
    assert(File(outPath).existsSync());

    return outPath;
  }

  // static void enableStatisticsCallback(Function cb) {
  //   return _config.enableStatisticsCallback(cb);
  // }

  static Future<void> cancel() async {
    await _encoder.cancel();
  }

  static Future<MediaInformation> getMediaInformation(String path) async {
    assert(File(path).existsSync());

    return await _probe.getMediaInformation(path);
  }

  static int getDuration(MediaInformation info) {
    return info.getMediaProperties()!['duration'];
  }

  static void enableLogCallback(
      void Function(int level, String message) logCallback) {
    //_config.enableLogCallback(logCallback);
  }
}
