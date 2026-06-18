import 'dart:async';

import 'package:camera/camera.dart';
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
  CameraController? _cameraController;
  Timer? _elapsedTimer;

  bool _isSupported = true;
  bool _isInitializing = false;
  bool _hasCameraPermission = false;
  bool _isRecording = false;
  bool _isStopping = false;
  bool _isUploading = false;
  int _elapsedSeconds = 0;
  String? _errorMessage;
  WorkoutRecordingFile? _lastRecording;

  bool get isSupported => _isSupported;
  bool get isInitializing => _isInitializing;
  bool get hasCameraPermission => _hasCameraPermission;
  bool get isRecording => _isRecording;
  bool get isStopping => _isStopping;
  bool get isUploading => _isUploading;
  bool get hasRecordedVideo => _lastRecording != null;
  int get elapsedSeconds => _elapsedSeconds;
  String? get errorMessage => _errorMessage;
  WorkoutRecordingFile? get lastRecording => _lastRecording;

  set isUploading(bool value) {
    if (_isUploading == value) {
      return;
    }

    _isUploading = value;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitializing || _cameraController?.value.isInitialized == true) {
      return;
    }

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        _isSupported = false;
        _hasCameraPermission = false;
        _errorMessage = "Kamera tidak ditemukan di device/emulator ini.";
        return;
      }

      final selectedCamera = _pickCamera(cameras);
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize().timeout(const Duration(seconds: 15));

      _cameraController = controller;
      _isSupported = true;
      _hasCameraPermission = true;
      _errorMessage = null;
    } catch (error) {
      _hasCameraPermission = false;
      _errorMessage = _cameraErrorMessage(error);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> start() async {
    if (_isRecording) {
      return;
    }

    if (_cameraController?.value.isInitialized != true) {
      await initialize();
    }

    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    _lastRecording = null;
    _elapsedSeconds = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      await controller.prepareForVideoRecording();
      await controller.startVideoRecording();
      _isRecording = true;
      _elapsedTimer?.cancel();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        if (_elapsedSeconds.isEven) {
          notifyListeners();
        }
      });
    } catch (error) {
      _isRecording = false;
      _errorMessage = "Recording gagal dimulai: ${_errorText(error)}";
    } finally {
      notifyListeners();
    }
  }

  Future<WorkoutRecordingFile?> stop() async {
    if (_lastRecording != null) {
      return _lastRecording;
    }

    final controller = _cameraController;

    if (controller == null || !controller.value.isRecordingVideo) {
      _errorMessage = "Recording belum tersedia.";
      notifyListeners();
      return null;
    }

    if (_isStopping) {
      while (_isStopping) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }

      return _lastRecording;
    }

    _isStopping = true;
    _elapsedTimer?.cancel();
    notifyListeners();

    try {
      final file = await controller
          .stopVideoRecording()
          .timeout(const Duration(seconds: 15));
      final bytes = await file.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      _lastRecording = WorkoutRecordingFile(
        bytes: bytes,
        filename: 'workout-recording-$timestamp.mp4',
        mimeType: 'video/mp4',
        durationSeconds: _elapsedSeconds,
      );
      _isRecording = false;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = "Gagal menghentikan recording: ${_errorText(error)}";
    } finally {
      _isStopping = false;
      notifyListeners();
    }

    return _lastRecording;
  }

  Widget buildPreview() {
    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Icon(
          Icons.videocam_outlined,
          color: Colors.white54,
          size: 48,
        ),
      );
    }

    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final previewSize = value.previewSize;

        if (!value.isInitialized || previewSize == null) {
          return const Center(
            child: Icon(
              Icons.videocam_outlined,
              color: Colors.white54,
              size: 48,
            ),
          );
        }

        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewSize.height,
              height: previewSize.width,
              child: child,
            ),
          ),
        );
      },
      child: CameraPreview(controller),
    );
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  CameraDescription _pickCamera(List<CameraDescription> cameras) {
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        return camera;
      }
    }

    return cameras.first;
  }

  String _cameraErrorMessage(Object error) {
    if (error is CameraException) {
      switch (error.code) {
        case 'CameraAccessDenied':
        case 'CameraAccessDeniedWithoutPrompt':
        case 'CameraAccessRestricted':
          return "Izin kamera ditolak. Buka App info > Permissions, lalu izinkan Camera.";
      }
    }

    return "Kamera wajib diaktifkan untuk mulai exercise. ${_errorText(error)}";
  }

  String _errorText(Object error) {
    if (error is CameraException) {
      final description = error.description;
      return description == null || description.isEmpty
          ? error.code
          : "${error.code}: $description";
    }

    return error.toString();
  }
}
