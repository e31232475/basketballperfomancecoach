import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WorkoutRecordingFile {
  const WorkoutRecordingFile({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    required this.durationSeconds,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final int durationSeconds;
}

class WorkoutRecordingController extends ChangeNotifier {
  bool get isSupported => false;
  bool get isInitializing => false;
  bool get hasCameraPermission => false;
  bool get isRecording => false;
  bool get isStopping => false;
  bool get isUploading => false;
  bool get hasRecordedVideo => false;
  int get elapsedSeconds => 0;
  String? get errorMessage => "Camera recording is only available on web.";
  WorkoutRecordingFile? get lastRecording => null;

  set isUploading(bool value) {}

  Future<void> initialize() async {}

  Future<void> start() async {}

  Future<WorkoutRecordingFile?> stop() async {
    return null;
  }

  Widget buildPreview() {
    return const Center(
      child: Icon(
        Icons.videocam_off_outlined,
        color: Colors.white54,
        size: 48,
      ),
    );
  }
}
