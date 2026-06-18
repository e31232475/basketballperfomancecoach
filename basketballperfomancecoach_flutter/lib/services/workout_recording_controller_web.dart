// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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
  WorkoutRecordingController()
      : _viewType =
            'workout-camera-preview-${DateTime.now().microsecondsSinceEpoch}';

  final String _viewType;
  final List<html.Blob> _chunks = [];

  html.VideoElement? _videoElement;
  html.MediaStream? _stream;
  html.MediaRecorder? _recorder;
  Timer? _elapsedTimer;

  bool _isInitializing = false;
  bool _hasCameraPermission = false;
  bool _isRecording = false;
  bool _isStopping = false;
  bool _isUploading = false;
  bool _viewRegistered = false;
  int _elapsedSeconds = 0;
  String? _errorMessage;
  WorkoutRecordingFile? _lastRecording;

  bool get isSupported =>
      html.window.navigator.mediaDevices != null && _supportedMimeType != null;
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
    if (_stream != null || _isInitializing) {
      return;
    }

    if (!isSupported) {
      _errorMessage = "Browser tidak mendukung camera recording.";
      notifyListeners();
      return;
    }

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final stream = await _requestCameraStream();
      final videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.backgroundColor = '#050505'
        ..srcObject = stream;

      if (!_viewRegistered) {
        ui_web.platformViewRegistry.registerViewFactory(
          _viewType,
          (int viewId) => videoElement,
        );
        _viewRegistered = true;
      }

      _stream = stream;
      _videoElement = videoElement;
      _hasCameraPermission = true;

      try {
        await videoElement.play();
      } catch (_) {
        // A few browsers defer autoplay until the embedded view is mounted.
      }
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

    if (_stream == null) {
      await initialize();
    }

    final stream = _stream;

    if (stream == null) {
      return;
    }

    _chunks.clear();
    _lastRecording = null;
    _elapsedSeconds = 0;
    _errorMessage = null;

    final mimeType = _supportedMimeType;

    if (mimeType == null) {
      _errorMessage = "Browser tidak mendukung format recording video.";
      notifyListeners();
      return;
    }

    try {
      final recorder = html.MediaRecorder(stream, {
        'mimeType': mimeType,
        'videoBitsPerSecond': 700000,
      });

      recorder.addEventListener('dataavailable', (event) {
        final blobEvent = event as html.BlobEvent;
        final blob = blobEvent.data;

        if (blob != null && blob.size > 0) {
          _chunks.add(blob);
        }
      });
      recorder.start(2500);
      _recorder = recorder;
      _isRecording = true;
      _elapsedTimer?.cancel();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _elapsedSeconds++;
        if (_elapsedSeconds.isEven) {
          notifyListeners();
        }
      });
    } catch (error) {
      _errorMessage = "Recording gagal dimulai: ${_errorText(error)}";
      _isRecording = false;
    } finally {
      notifyListeners();
    }
  }

  Future<WorkoutRecordingFile?> stop() async {
    if (_lastRecording != null) {
      return _lastRecording;
    }

    final recorder = _recorder;

    if (recorder == null) {
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

    final completer = Completer<WorkoutRecordingFile?>();
    late StreamSubscription<html.Event> stopSubscription;
    stopSubscription = recorder.on['stop'].listen((_) async {
      await stopSubscription.cancel();
      await _captureStoppedRecording();
      completer.complete(_lastRecording);
    });

    if (recorder.state != 'inactive') {
      recorder.stop();
    } else {
      await stopSubscription.cancel();
      await _captureStoppedRecording();
      completer.complete(_lastRecording);
    }

    final file = await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        _errorMessage = "Gagal menghentikan recording.";
        return null;
      },
    );

    _isStopping = false;
    _isRecording = false;
    notifyListeners();

    return file;
  }

  Widget buildPreview() {
    if (_videoElement == null) {
      return const Center(
        child: Icon(
          Icons.videocam_outlined,
          color: Colors.white54,
          size: 48,
        ),
      );
    }

    return HtmlElementView(viewType: _viewType);
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();

    if (_recorder != null && _recorder!.state != 'inactive') {
      _recorder!.stop();
    }

    _stream?.getTracks().forEach((track) {
      track.stop();
    });
    _videoElement?.srcObject = null;
    super.dispose();
  }

  Future<void> _captureStoppedRecording() async {
    if (_lastRecording != null || _chunks.isEmpty) {
      return;
    }

    final mimeType = _supportedMimeType ?? 'video/webm';
    final blob = html.Blob(_chunks, mimeType);
    final bytes = await _blobToBytes(blob);
    _lastRecording = WorkoutRecordingFile(
      bytes: bytes,
      filename:
          'workout-recording-${DateTime.now().millisecondsSinceEpoch}.webm',
      mimeType: mimeType,
      durationSeconds: _elapsedSeconds,
    );
  }

  Future<Uint8List> _blobToBytes(html.Blob blob) {
    final reader = html.FileReader();
    final completer = Completer<Uint8List>();

    reader.onLoadEnd.listen((_) {
      final result = reader.result;

      if (result is Uint8List) {
        completer.complete(result);
        return;
      }

      completer.completeError(StateError('Invalid recording data.'));
    });
    reader.onError.listen((_) {
      completer.completeError(StateError('Failed to read recording data.'));
    });
    reader.readAsArrayBuffer(blob);

    return completer.future;
  }

  Future<html.MediaStream> _requestCameraStream() async {
    final mediaDevices = html.window.navigator.mediaDevices;

    if (mediaDevices == null) {
      throw StateError('MediaDevices API unavailable.');
    }

    try {
      return await mediaDevices.getUserMedia({
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640, 'max': 640},
          'height': {'ideal': 360, 'max': 360},
          'frameRate': {'ideal': 20, 'max': 24},
        },
        'audio': false,
      });
    } catch (_) {
      return mediaDevices.getUserMedia({
        'video': true,
        'audio': false,
      });
    }
  }

  String _cameraErrorMessage(Object error) {
    final errorText = _errorText(error);

    if (error is html.DomException) {
      switch (error.name) {
        case 'NotAllowedError':
        case 'PermissionDeniedError':
          return "Izin kamera ditolak. Klik ikon lock/camera di address bar lalu pilih Allow.";
        case 'NotFoundError':
        case 'DevicesNotFoundError':
          return "Kamera tidak ditemukan. Sambungkan kamera lalu coba lagi.";
        case 'NotReadableError':
        case 'TrackStartError':
          return "Kamera sedang dipakai aplikasi lain. Tutup app lain lalu coba lagi.";
        case 'SecurityError':
        case 'NotSupportedError':
          return "Kamera hanya bisa aktif di HTTPS, localhost, atau 127.0.0.1.";
      }
    }

    return "Kamera wajib diaktifkan untuk mulai exercise. $errorText";
  }

  String _errorText(Object error) {
    if (error is html.DomException) {
      return error.message?.isNotEmpty == true
          ? "${error.name}: ${error.message}"
          : error.name;
    }

    return error.toString();
  }

  static String? get _supportedMimeType {
    const options = [
      'video/webm;codecs=vp8',
      'video/webm',
      'video/webm;codecs=vp9',
    ];

    for (final option in options) {
      if (html.MediaRecorder.isTypeSupported(option)) {
        return option;
      }
    }

    return null;
  }
}
