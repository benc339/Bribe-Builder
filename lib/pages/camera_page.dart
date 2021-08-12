// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as Path;
import 'package:image/image.dart' as imglib;

import 'package:flutter/foundation.dart';

typedef convert_func = Pointer<Uint32> Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, Int32, Int32, Int32, Int32);
typedef Convert = Pointer<Uint32> Function(
    Pointer<Uint8>, Pointer<Uint8>, Pointer<Uint8>, int, int, int, int);

encodeImage(List list) {
  String input = list[1];
  int x = list[2];
  print('$input$x.jpg');

  //list[0] = imglib.copyCrop(list[0], 150, 0, 230, 400);
  File('$input$x.jpg').writeAsBytes(imglib.encodeJpg(list[0]));
}

class CameraExampleHome extends StatefulWidget {
  @override
  _CameraExampleHomeState createState() {
    return _CameraExampleHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
    default:
      throw ArgumentError('Unknown lens direction');
  }
}

void logError(String code, String? message) {
  if (message != null) {
    print('Error: $code\nError Message: $message');
  } else {
    print('Error: $code');
  }
}

class _CameraExampleHomeState extends State<CameraExampleHome>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  XFile? imageFile;
  XFile? videoFile;
  VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = false;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;
  late AnimationController _exposureModeControlRowAnimationController;
  late Animation<double> _exposureModeControlRowAnimation;
  late AnimationController _focusModeControlRowAnimationController;
  late Animation<double> _focusModeControlRowAnimation;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  late Directory tempDirectory;

  int pictureCount = 0;
  int index = 0;
  late CameraImage _savedImage;
  int x = 0;
  late Convert conv;

  int processedCount=0;
  bool processing = false;
  bool stopRecording = false;



  @override
  void initState() {
    super.initState();
    getImagesDirectory();
    WidgetsBinding.instance?.addObserver(this);

    _flashModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flashModeControlRowAnimation = CurvedAnimation(
      parent: _flashModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _exposureModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _exposureModeControlRowAnimation = CurvedAnimation(
      parent: _exposureModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
    _focusModeControlRowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusModeControlRowAnimation = CurvedAnimation(
      parent: _focusModeControlRowAnimationController,
      curve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    _flashModeControlRowAnimationController.dispose();
    _exposureModeControlRowAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Camera example'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color:
                  controller != null && controller!.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureControlRowWidget(),
          _modeControlRowWidget(),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _cameraTogglesRowWidget(),
                //_thumbnailWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onTapDown: (details) => onViewFinderTap(details, constraints),
                );
              }),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    final VideoPlayerController? localVideoController = videoController;

    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            localVideoController == null && imageFile == null
                ? Container()
                : SizedBox(
              child: (localVideoController == null)
                  ? Image.file(File(imageFile!.path))
                  : Container(
                child: Center(
                  child: AspectRatio(
                      aspectRatio:
                      localVideoController.value.size != null
                          ? localVideoController
                          .value.aspectRatio
                          : 1.0,
                      child: VideoPlayer(localVideoController)),
                ),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.pink)),
              ),
              width: 64.0,
              height: 64.0,
            ),
          ],
        ),
      ),
    );
  }

  /// Display a bar with buttons to change the flash and exposure modes
  Widget _modeControlRowWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.flash_on),
              color: Colors.blue,
              onPressed: controller != null ? onFlashModeButtonPressed : null,
            ),
            IconButton(
              icon: Icon(Icons.exposure),
              color: Colors.blue,
              onPressed:
              controller != null ? onExposureModeButtonPressed : null,
            ),
            IconButton(
              icon: Icon(Icons.filter_center_focus),
              color: Colors.blue,
              onPressed: controller != null ? onFocusModeButtonPressed : null,
            ),
            IconButton(
              icon: Icon(enableAudio ? Icons.volume_up : Icons.volume_mute),
              color: Colors.blue,
              onPressed: controller != null ? onAudioModeButtonPressed : null,
            ),
            IconButton(
              icon: Icon(controller?.value.isCaptureOrientationLocked ?? false
                  ? Icons.screen_lock_rotation
                  : Icons.screen_rotation),
              color: Colors.blue,
              onPressed: controller != null
                  ? onCaptureOrientationLockButtonPressed
                  : null,
            ),
          ],
        ),
        _flashModeControlRowWidget(),
        _exposureModeControlRowWidget(),
        _focusModeControlRowWidget(),
      ],
    );
  }

  Widget _flashModeControlRowWidget() {
    return SizeTransition(
      sizeFactor: _flashModeControlRowAnimation,
      child: ClipRect(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: Icon(Icons.flash_off),
              color: controller?.value.flashMode == FlashMode.off
                  ? Colors.orange
                  : Colors.blue,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.off)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.flash_auto),
              color: controller?.value.flashMode == FlashMode.auto
                  ? Colors.orange
                  : Colors.blue,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.auto)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.flash_on),
              color: controller?.value.flashMode == FlashMode.always
                  ? Colors.orange
                  : Colors.blue,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.always)
                  : null,
            ),
            IconButton(
              icon: Icon(Icons.highlight),
              color: controller?.value.flashMode == FlashMode.torch
                  ? Colors.orange
                  : Colors.blue,
              onPressed: controller != null
                  ? () => onSetFlashModeButtonPressed(FlashMode.torch)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _exposureModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      primary: controller?.value.exposureMode == ExposureMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      primary: controller?.value.exposureMode == ExposureMode.locked
          ? Colors.orange
          : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _exposureModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              Center(
                child: Text("Exposure Mode"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    child: Text('AUTO'),
                    style: styleAuto,
                    onPressed: controller != null
                        ? () =>
                        onSetExposureModeButtonPressed(ExposureMode.auto)
                        : null,
                    onLongPress: () {
                      if (controller != null) {
                        controller!.setExposurePoint(null);
                        showInSnackBar('Resetting exposure point');
                      }
                    },
                  ),
                  TextButton(
                    child: Text('LOCKED'),
                    style: styleLocked,
                    onPressed: controller != null
                        ? () =>
                        onSetExposureModeButtonPressed(ExposureMode.locked)
                        : null,
                  ),
                ],
              ),
              Center(
                child: Text("Exposure Offset"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(_minAvailableExposureOffset.toString()),
                  Slider(
                    value: _currentExposureOffset,
                    min: _minAvailableExposureOffset,
                    max: _maxAvailableExposureOffset,
                    label: _currentExposureOffset.toString(),
                    onChanged: _minAvailableExposureOffset ==
                        _maxAvailableExposureOffset
                        ? null
                        : setExposureOffset,
                  ),
                  Text(_maxAvailableExposureOffset.toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusModeControlRowWidget() {
    final ButtonStyle styleAuto = TextButton.styleFrom(
      primary: controller?.value.focusMode == FocusMode.auto
          ? Colors.orange
          : Colors.blue,
    );
    final ButtonStyle styleLocked = TextButton.styleFrom(
      primary: controller?.value.focusMode == FocusMode.locked
          ? Colors.orange
          : Colors.blue,
    );

    return SizeTransition(
      sizeFactor: _focusModeControlRowAnimation,
      child: ClipRect(
        child: Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              Center(
                child: Text("Focus Mode"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    child: Text('AUTO'),
                    style: styleAuto,
                    onPressed: controller != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.auto)
                        : null,
                    onLongPress: () {
                      if (controller != null) controller!.setFocusPoint(null);
                      showInSnackBar('Resetting focus point');
                    },
                  ),
                  TextButton(
                    child: Text('LOCKED'),
                    style: styleLocked,
                    onPressed: controller != null
                        ? () => onSetFocusModeButtonPressed(FocusMode.locked)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    final CameraController? cameraController = controller;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.blue,
          onPressed: cameraController != null &&
              cameraController.value.isInitialized &&
              !cameraController.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          color: Colors.blue,
          onPressed: cameraController != null &&
              cameraController.value.isInitialized &&
              !cameraController.value.isRecordingVideo
              ? onVideoRecordButtonPressed
              : null,
        ),
        IconButton(
          icon: cameraController != null &&
              cameraController.value.isRecordingPaused
              ? Icon(Icons.play_arrow)
              : Icon(Icons.pause),
          color: Colors.blue,
          onPressed: cameraController != null &&
              cameraController.value.isInitialized &&
              cameraController.value.isRecordingVideo
              ? (cameraController.value.isRecordingPaused)
              ? onResumeButtonPressed
              : onPauseButtonPressed
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          color: Colors.red,
          onPressed: cameraController != null &&
              cameraController.value.isInitialized &&
              cameraController.value.isRecordingVideo
              ? onStopButtonPressed
              : null,
        )
      ],
    );
  }

  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    final onChanged = (CameraDescription? description) {
      if (description == null) {
        return;
      }

      onNewCameraSelected(description);
    };

    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(
          SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
              title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
              groupValue: controller?.description,
              value: cameraDescription,
              onChanged:
              controller != null && controller!.value.isRecordingVideo
                  ? null
                  : onChanged,
            ),
          ),
        );
      }
    }

    return Row(children: toggles);
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    // ignore: deprecated_member_use
    _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final CameraController cameraController = controller!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) setState(() {});
      if (cameraController.value.hasError) {
        showInSnackBar(
            'Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
      await Future.wait([
        cameraController
            .getMinExposureOffset()
            .then((value) => _minAvailableExposureOffset = value),
        cameraController
            .getMaxExposureOffset()
            .then((value) => _maxAvailableExposureOffset = value),
        cameraController
            .getMaxZoomLevel()
            .then((value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((value) => _minAvailableZoom = value),
      ]);
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed()  {
    takePicture().then((XFile? file) async {
      if (mounted) {
        setState(() {
          imageFile = file;
          videoController?.dispose();
          videoController = null;
        });



        String cacheDir = tempDirectory.path;
        print('tempdirectory:$cacheDir');
        late File newFile;
        if (file != null)  {
          print('filepath:'+file.path);
          if (pictureCount < 10) {
            newFile = await File(file.path).rename(
                '$cacheDir/image00$pictureCount.jpg');
          }
          else if (pictureCount < 100) {
            newFile = await File(file.path).rename(
                '$cacheDir/image0$pictureCount.jpg');
          } else {
            newFile = await File(file.path).rename(
                '$cacheDir/image$pictureCount.jpg');
          }
          print('picture$pictureCount saved');
          //showInSnackBar('Picture saved to ${newFile.path}');
          pictureCount++;
        }


        // if (pictureCount < 20) {
        //   onTakePictureButtonPressed();
        // } else if (pictureCount>20) {
        //   pictureCount=0;
        //   //pictureCount=0;
        // } else {
        //   _startVideoPlayer();
        // }

      }
    });
  }

  void onFlashModeButtonPressed() {
    if (_flashModeControlRowAnimationController.value == 1) {
      _flashModeControlRowAnimationController.reverse();
    } else {
      _flashModeControlRowAnimationController.forward();
      _exposureModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onExposureModeButtonPressed() {
    if (_exposureModeControlRowAnimationController.value == 1) {
      _exposureModeControlRowAnimationController.reverse();
    } else {
      _exposureModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _focusModeControlRowAnimationController.reverse();
    }
  }

  void onFocusModeButtonPressed() {
    if (_focusModeControlRowAnimationController.value == 1) {
      _focusModeControlRowAnimationController.reverse();
    } else {
      _focusModeControlRowAnimationController.forward();
      _flashModeControlRowAnimationController.reverse();
      _exposureModeControlRowAnimationController.reverse();
    }
  }

  void onAudioModeButtonPressed() {
    enableAudio = !enableAudio;
    if (controller != null) {
      onNewCameraSelected(controller!.description);
    }
  }

  void onCaptureOrientationLockButtonPressed() async {
    if (controller != null) {
      final CameraController cameraController = controller!;
      if (cameraController.value.isCaptureOrientationLocked) {
        await cameraController.unlockCaptureOrientation();
        showInSnackBar('Capture orientation unlocked');
      } else {
        await cameraController.lockCaptureOrientation();
        showInSnackBar(
            'Capture orientation locked to ${cameraController.value.lockedCaptureOrientation.toString().split('.').last}');
      }
    }
  }

  void onSetFlashModeButtonPressed(FlashMode mode) {
    setFlashMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Flash mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetExposureModeButtonPressed(ExposureMode mode) {
    setExposureMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Exposure mode set to ${mode.toString().split('.').last}');
    });
  }

  void onSetFocusModeButtonPressed(FocusMode mode) {
    setFocusMode(mode).then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Focus mode set to ${mode.toString().split('.').last}');
    });
  }

  Future<void> mediumSleep() async {
    for(int z = 0; z< 20; z++) {
      await new Future.delayed(const Duration(milliseconds: 500), () => "1");
      if (stopRecording) {
        return;
      }
    }
    return;
  }
  Future<void> sleep() async {
    for(int z = 0; z< 2; z++) {
      await new Future.delayed(const Duration(milliseconds: 500), () => "1");
      if (stopRecording) {
        return;
      }
    }
    return;
  }
  Future shortSleep() {
    return new Future.delayed(const Duration(milliseconds: 300), () => "1");
  }

  void onVideoRecordButtonPressed() async {
    await startVideoRecording().then((_) async {
      if (mounted) setState(() {});
      await sleep();
      await stopVideoRecording().then((file) async {
        if (file != null) {
          videoFile = file;
          processVideo();
          while(!stopRecording) {

            await startVideoRecording().then((_) async {
              await mediumSleep();
              await stopVideoRecording().then((file) async {
                videoFile = file;
                processAndCombineVideos();


              });
            });
          }
        }
      });

    });
    while(processing) {
      await shortSleep();
    }
    _startVideoPlayer();
  }

  void onStopButtonPressed() {
    stopRecording = true;
    // stopVideoRecording().then((file) {
    //   if (mounted) setState(() {});
    //
    //   // if (file != null) {
    //   //   showInSnackBar('Video recorded to ${file.path}');
    //   //   videoFile = file;
    //   //   print('startvideoplayer');
    //   //   _startVideoPlayer();
    //   // }
    // });
  }

  void onPauseButtonPressed() {
    pauseVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording paused');
    });
  }

  void onResumeButtonPressed() {
    resumeVideoRecording().then((_) {
      if (mounted) setState(() {});
      showInSnackBar('Video recording resumed');
    });
  }

  Future<void> startVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return;
    }

    if (cameraController.value.isRecordingVideo) {
      // A recording is already started, do nothing.
      return;
    }

    try {
      await cameraController.startVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return;
    }
  }

  Future<XFile?> stopVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      return cameraController.stopVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  Future<void> pauseVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      await cameraController.pauseVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> resumeVideoRecording() async {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isRecordingVideo) {
      return null;
    }

    try {
      await cameraController.resumeVideoRecording();
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (controller == null) {
      return;
    }

    try {
      await controller!.setFlashMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureMode(ExposureMode mode) async {
    if (controller == null) {
      return;
    }

    try {
      await controller!.setExposureMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (controller == null) {
      return;
    }

    setState(() {
      _currentExposureOffset = offset;
    });
    try {
      offset = await controller!.setExposureOffset(offset);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
  }

  Future<void> setFocusMode(FocusMode mode) async {
    if (controller == null) {
      return;
    }

    try {
      await controller!.setFocusMode(mode);
    } on CameraException catch (e) {
      _showCameraException(e);
      rethrow;
    }
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

  Future<void> processVideo() async {

    final FlutterFFmpeg _encoder = FlutterFFmpeg();
    String videoPath = videoFile!.path;
    //String input = getImagePath('image');
    var extension;


    String ff_output = getImagePath('time_lapse$processedCount.mp4');
    try {
      await File(ff_output).delete();
    } catch(e) {}
    //File(input+'021.jpg').delete();


    //final arguments = '-f image2 -i $input%03d.jpg $ff_output';
    //final arguments = '-framerate 30 -i $input%03d.jpg  -vf "select=\'not(mod(n,$divisor))\',setpts=N/30/TB" $ff_output';
    double speed = 0.25;
    if (processedCount > 1) {
      speed = 0.5/(processedCount+1).toDouble();
      print('speed:$speed');
    }
    final arguments = '-i $videoPath ' +
        '-filter:v "setpts=$speed*PTS" -an ' +
        '$ff_output';

    print('ffmpeg processing video $processedCount');
    final int rc = await _encoder.execute(arguments);
    print('after ffmpeg');
    processedCount++;
  }

  Future<void> processAndCombineVideos() async {
    while(processing) {
      await shortSleep();
    }
    processing = true;
    await processVideo();
    await combineVideos();
    processing = false;
  }

  Future<void> combineVideos() async {
    print('combining videos');
    var firstVideoCount;
    var secondVideoCount;
    if(processedCount < 3) {
      firstVideoCount = processedCount - 2;
      secondVideoCount = processedCount - 1;
    } else {
      firstVideoCount = '00' + (processedCount - 2).toString();
      secondVideoCount = processedCount - 1;
    }
    String ff_output1 = getImagePath('time_lapse$firstVideoCount.mp4');
    String ff_output2 = getImagePath('time_lapse$secondVideoCount.mp4');
    String concateListPath = getImagePath('concateList.txt');
    await File(concateListPath).writeAsString('file $ff_output1\nfile $ff_output2\n');
    String string = await File(concateListPath).readAsString();
    print(string);

    final FlutterFFmpeg _encoder = FlutterFFmpeg();
    int previousProcessedCount = processedCount-1;
    String ff_output_final = getImagePath('time_lapse0$previousProcessedCount.mp4');
    try {
      await File(ff_output_final).delete();
    } catch(e) {}

    //final arguments = '-f image2 -i $input%03d.jpg $ff_output';
    //final arguments = '-framerate 30 -i $input%03d.jpg  -vf "select=\'not(mod(n,$divisor))\',setpts=N/30/TB" $ff_output';
    final arguments = '-f concat -safe 0 -i $concateListPath -c copy $ff_output_final';
    print('start ffmpeg combine');
    final int rc = await _encoder.execute(arguments);

    String ff_output_final2 = getImagePath('time_lapse00$previousProcessedCount.mp4');
    try {
      await File(ff_output_final2).delete();
    } catch(e) {}
    print('speed$previousProcessedCount');
    double speed = (processedCount-1).toDouble()/processedCount.toDouble();
    print('speed:$speed');
    final arguments2 = '-i $ff_output_final ' +
        '-filter:v "setpts=$speed*PTS" -an ' +
        '$ff_output_final2';

    print('start ffmpeg combined slowdown');
    final int rc2 = await _encoder.execute(arguments2);


  }

  Future<void> _startVideoPlayer() async {
    // if (videoFile == null) {
    //   return;
    // }
    // int divisor = (pictureCount ~/ 130);
    // final FlutterFFmpeg _encoder = FlutterFFmpeg();
    // //String videoPath = videoFile!.path;
    // String input = getImagePath('image');
    // String ff_output = getImagePath('time_lapse.mp4');
    // File(ff_output).delete();
    // File(input+'021.jpg').delete();
    //
    //
    // final arguments = '-f image2 -i $input%03d.jpg $ff_output';
    // //final arguments = '-framerate 30 -i $input%03d.jpg  -vf "select=\'not(mod(n,$divisor))\',setpts=N/30/TB" $ff_output';
    // // final arguments = '-i $videoPath ' +
    // //     '-filter:v "setpts=0.01*PTS" -an ' +
    // //     '$ff_output';
    //
    //
    // final int rc = await _encoder.execute(arguments);
    // print('after ffmpeg');
    int previousProcessedCount = processedCount-1;
    print('playing:time_lapse00$previousProcessedCount');
    String ff_output_final = getImagePath('time_lapse00$previousProcessedCount.mp4');
    final VideoPlayerController vController =
    VideoPlayerController.file(File(ff_output_final));
    videoPlayerListener = () {
      if (videoController != null && videoController!.value.size != null) {
        // Refreshing the state to update video player with the correct ratio.
        if (mounted) setState(() {});
        videoController!.removeListener(videoPlayerListener!);
      }
    };
    vController.addListener(videoPlayerListener!);
    await vController.setLooping(true);
    await vController.initialize();
    await videoController?.dispose();
    if (mounted) {
      setState(() {
        imageFile = null;
        videoController = vController;
      });
    }
    print('show dialog');
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
                      vController
                          .pause();
                      Navigator.pop(
                          context);
                    },
                    onLongPress: () {
                      setState(() {
                        vController
                            .value
                            .isPlaying
                            ? vController
                            .pause()
                            : vController
                            .play();
                      });
                    },
                    child: AspectRatio(
                      aspectRatio:
                      vController
                          .value
                          .aspectRatio,
                      child: VideoPlayer(
                          vController),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    print('play VIDEO');
    await vController.play();
  }



  void _processCameraImage(CameraImage image, cameraController) async {
    index++;
    late imglib.Image img;
    //print(index % 50);
    if (index % 20 == 0) {
      _savedImage = image;

      if (Platform.isIOS) {
        img = imglib.Image.fromBytes(
          _savedImage.planes[0].bytesPerRow,
          _savedImage.height,
          _savedImage.planes[0].bytes,
          format: imglib.Format.bgra,
        );
      }
      print('save image');

      //imgs.add(img);


      if (x >= 100)  {
        String input = getImagePath('image');
        print('$input$x.png');

        await File('$input$x.png').writeAsBytes(imglib.encodePng(img));
      }
      else if (x >= 10) {
        String input = getImagePath('image0');
        print('$input$x.png');

        await File('$input$x.png').writeAsBytes(imglib.encodePng(img));
      } else {
        String input = getImagePath('image00');
        print('$input$x.png');

        File('$input$x.png').writeAsBytes(imglib.encodePng(img));
      }

      if (x>20) {
        cameraController.stopImageStream();
        _startVideoPlayer();
      }


      // List list = [];
      // if (x >= 10) {
      //   String input = getImagePath('image0');
      //   print('$input$x.jpg');
      //
      //   list.add(img);
      //   list.add(input);
      //   list.add(x);
      //   compute(encodeImage, list);
      // } else {
      //   String input = getImagePath('image00');
      //   print('$input$x.jpg');
      //   list.add(img);
      //   list.add(input);
      //   list.add(x);
      //   compute(encodeImage, list);
      // }






      x++;
    }
  }

  Future<XFile?> takePicture() async {
    index = 0;
    x = 0;
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    cameraController.startImageStream((image) => _processCameraImage(image,cameraController));

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }
}

class CameraApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraExampleHome(),
    );
  }
}

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
  runApp(CameraApp());
}