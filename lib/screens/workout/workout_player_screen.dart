import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../services/workout_service.dart';
import '../../services/workout_recording_controller.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  const WorkoutPlayerScreen({
    super.key,
    required this.dayNumber,
  });

  final int dayNumber;

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  bool isLoading = true;
  bool isSaving = false;
  bool isVideoPlaying = false;
  bool isResting = false;
  bool isVideoInitializing = false;

  Map<String, dynamic>? workoutData;
  List<dynamic> exercises = [];
  int currentIndex = 0;
  int currentSetNumber = 1;
  int restRemaining = 0;
  int restTotal = 0;
  int? pendingExerciseIndex;
  int? pendingSetNumber;
  Map<int, Map<int, bool>> setResults = {};
  late final WorkoutRecordingController recordingController;
  bool recordingUploaded = false;

  Timer? _timer;
  VideoPlayerController? _videoController;
  String? _currentVideoUrl;

  @override
  void initState() {
    super.initState();
    recordingController = WorkoutRecordingController()
      ..addListener(_handleRecordingChanged);
    _loadWorkout();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposeVideoController();
    recordingController.removeListener(_handleRecordingChanged);
    recordingController.dispose();
    super.dispose();
  }

  void _handleRecordingChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadWorkout() async {
    setState(() {
      isLoading = true;
    });

    final data = await WorkoutService.getWorkoutByDay(widget.dayNumber);
    final responseData = data["data"];
    final workout = responseData is Map ? responseData["workout"] : null;
    final loadedExercises =
        responseData is Map ? responseData["exercises"] : null;
    final exerciseList = loadedExercises is List ? loadedExercises : [];

    final normalizedExercises = exerciseList
        .map((exercise) => _asMap(exercise) ?? exercise)
        .toList(growable: false);

    if (!mounted) return;

    setState(() {
      workoutData = _asMap(workout);
      exercises = normalizedExercises;
      currentIndex = 0;
      currentSetNumber = 1;
      setResults = {};
      isLoading = false;
    });

    await _prepareCurrentExercise();
    await _startWorkoutRecording();
  }

  Future<void> _startWorkoutRecording() async {
    final wasRecording = recordingController.isRecording;

    await recordingController.initialize();

    if (!mounted) {
      return;
    }

    await recordingController.start();

    if (!mounted) {
      return;
    }

    if (!wasRecording && recordingController.isRecording) {
      _showRecordingCaution();
    }
  }

  Future<void> _prepareCurrentExercise({bool autoStart = false}) async {
    _timer?.cancel();

    final exercise = _currentExercise;

    if (mounted) {
      setState(() {
        isResting = false;
        isVideoPlaying = false;
        currentSetNumber = exercise == null
            ? 1
            : currentSetNumber.clamp(1, _sets(exercise)).toInt();
      });
    }

    await _setupVideoForCurrent(autoPlay: false);

    if (autoStart && mounted) {
      await _playVideo();
    }
  }

  Future<void> _setupVideoForCurrent({required bool autoPlay}) async {
    final url = _videoUrl(_currentExercise);

    if (url == null) {
      await _disposeVideoController();
      return;
    }

    if (_videoController != null && _currentVideoUrl == url) {
      if (autoPlay) {
        await _videoController!.play();
        if (mounted) {
          setState(() {
            isVideoPlaying = true;
          });
        }
      } else {
        await _videoController!.pause();
        if (mounted) {
          setState(() {
            isVideoPlaying = false;
          });
        }
      }
      return;
    }

    await _disposeVideoController();

    if (!mounted) {
      return;
    }

    setState(() {
      isVideoInitializing = true;
    });

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize().timeout(const Duration(seconds: 12));
      await controller.setLooping(true);

      if (!mounted || _videoUrl(_currentExercise) != url) {
        await controller.dispose();
        return;
      }

      if (autoPlay) {
        await controller.play();
      }

      setState(() {
        _videoController = controller;
        _currentVideoUrl = url;
        isVideoPlaying = autoPlay;
      });
    } catch (_) {
      await _disposeVideoController();
    } finally {
      if (mounted) {
        setState(() {
          isVideoInitializing = false;
        });
      }
    }
  }

  Future<void> _disposeVideoController() async {
    try {
      await _videoController?.pause();
      await _videoController?.dispose();
    } catch (_) {}

    _videoController = null;
    _currentVideoUrl = null;
  }

  Future<void> _playVideo() async {
    if (_videoController == null || isSaving || isResting) {
      return;
    }

    await _videoController?.play();

    if (mounted) {
      setState(() {
        isVideoPlaying = true;
      });
    }
  }

  Future<void> _pauseVideo() async {
    await _videoController?.pause();

    if (mounted) {
      setState(() {
        isVideoPlaying = false;
      });
    }
  }

  Future<void> _togglePlayback() async {
    if (isVideoPlaying) {
      await _pauseVideo();
      return;
    }

    await _playVideo();
  }

  Future<void> _goToExercise(int index, {int? setNumber}) async {
    if (index < 0 || index >= exercises.length || index == currentIndex) {
      return;
    }

    final exercise = exercises[index];

    setState(() {
      currentIndex = index;
      currentSetNumber = (setNumber ?? _activeSetNumber(exercise))
          .clamp(1, _sets(exercise))
          .toInt();
    });

    await _prepareCurrentExercise();
  }

  Future<void> _goPreviousStep() async {
    final exercise = _currentExercise;

    if (exercise == null) {
      return;
    }

    if (currentSetNumber > 1) {
      setState(() {
        currentSetNumber--;
      });
      await _prepareCurrentExercise();
      return;
    }

    if (currentIndex <= 0) {
      _showMessage("Ini set pertama.");
      return;
    }

    await _goToExercise(
      currentIndex - 1,
      setNumber: _sets(exercises[currentIndex - 1]),
    );
  }

  Future<void> _completeCurrentSetFromNextButton() async {
    await _onResult(true);
  }

  Future<void> _moveAfterLoggedResult() async {
    final exercise = _currentExercise;

    if (exercise == null) {
      return;
    }

    if (!_isExerciseComplete(exercise)) {
      await _startRestBeforeNextStep(
        nextExerciseIndex: currentIndex,
        nextSetNumber: _activeSetNumber(exercise),
        restSeconds: _restSeconds(exercise),
      );
      return;
    }

    if (_areAllExercisesCompleted()) {
      await _finishWorkout();
      return;
    }

    final nextIndex = _nextIncompleteExerciseIndex(startAfter: currentIndex) ??
        _nextIncompleteExerciseIndex();

    if (nextIndex != null) {
      final nextExercise = exercises[nextIndex];

      await _startRestBeforeNextStep(
        nextExerciseIndex: nextIndex,
        nextSetNumber: _activeSetNumber(nextExercise),
        restSeconds: _restSeconds(exercise),
      );
      return;
    }

    await _finishWorkout();
  }

  Future<void> _onResult(bool success) async {
    if (isSaving) {
      return;
    }

    final recordingReady = recordingController.isRecording ||
        (recordingController.hasRecordedVideo && _areAllExercisesCompleted());

    if (!recordingReady) {
      await _startWorkoutRecording();

      if (!mounted) {
        return;
      }

      if (!recordingController.isRecording) {
        _showMessage(
          recordingController.errorMessage ??
              "Aktifkan kamera untuk mulai exercise.",
        );
        return;
      }
    }

    final exercise = _currentExercise;
    final exerciseId = _exerciseId(exercise);

    if (exerciseId == null) {
      _showMessage("Data latihan tidak valid.");
      return;
    }

    _timer?.cancel();
    await _pauseVideo();

    setState(() {
      isSaving = true;
      isVideoPlaying = false;
    });

    final setNumber = currentSetNumber;
    final updatedResults = Map<int, Map<int, bool>>.from(setResults);
    final exerciseResults = Map<int, bool>.from(
      updatedResults[exerciseId] ?? {},
    );
    exerciseResults[setNumber] = success;
    updatedResults[exerciseId] = exerciseResults;

    setState(() {
      setResults = updatedResults;
    });

    if (!success) {
      _showMessage(
          "Set $setNumber ditandai gagal sementara. Lanjut ke langkah berikutnya.");
    }

    await _moveAfterLoggedResult();
  }

  Future<void> _startRestBeforeNextStep({
    required int nextExerciseIndex,
    required int nextSetNumber,
    required int restSeconds,
  }) async {
    await _pauseVideo();

    if (!mounted) {
      return;
    }

    if (restSeconds <= 0) {
      setState(() {
        isSaving = false;
        currentIndex = nextExerciseIndex;
        currentSetNumber = nextSetNumber;
      });
      await _prepareCurrentExercise();
      return;
    }

    _timer?.cancel();

    setState(() {
      isSaving = false;
      isResting = true;
      restRemaining = restSeconds;
      restTotal = restSeconds;
      pendingExerciseIndex = nextExerciseIndex;
      pendingSetNumber = nextSetNumber;
    });

    _runRestTimer();
  }

  void _runRestTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (restRemaining <= 1) {
        _finishRest();
        return;
      }

      setState(() {
        restRemaining--;
      });
    });
  }

  Future<void> _finishRest() async {
    _timer?.cancel();
    _timer = null;

    if (!mounted) {
      return;
    }

    final nextIndex = pendingExerciseIndex;
    final nextSet = pendingSetNumber;

    setState(() {
      isResting = false;
      restRemaining = 0;
      restTotal = 0;
      pendingExerciseIndex = null;
      pendingSetNumber = null;

      if (nextIndex != null && nextSet != null) {
        currentIndex = nextIndex;
        currentSetNumber = nextSet;
      }
    });

    await _prepareCurrentExercise();
  }

  Future<void> _finishWorkout() async {
    final recordingResult = await _uploadWorkoutRecording();

    if (!mounted) {
      return;
    }

    if (!recordingResult.success) {
      setState(() {
        isSaving = false;
      });
      _showMessage(recordingResult.message);
      return;
    }

    final saveResult = await _saveSessionResults();

    if (!mounted) {
      return;
    }

    if (!saveResult.success) {
      setState(() {
        isSaving = false;
      });
      _showMessage(saveResult.message);
      return;
    }

    final result = await WorkoutService.completeWorkout(widget.dayNumber);

    if (!mounted) {
      return;
    }

    if (result.success) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      isSaving = false;
    });

    _showMessage(result.message);
  }

  Future<WorkoutActionResult> _uploadWorkoutRecording() async {
    if (recordingUploaded) {
      return const WorkoutActionResult(
        success: true,
        message: "Recording already uploaded",
      );
    }

    final workoutId = _workoutId;

    if (workoutId == null) {
      return const WorkoutActionResult(
        success: false,
        message: "Data workout tidak valid.",
      );
    }

    final recording =
        recordingController.lastRecording ?? await recordingController.stop();

    if (recording == null) {
      return WorkoutActionResult(
        success: false,
        message: recordingController.errorMessage ??
            "Recording kamera belum tersedia.",
      );
    }

    recordingController.isUploading = true;
    final result = await WorkoutService.uploadWorkoutRecording(
      workoutId: workoutId,
      dayNumber: widget.dayNumber,
      videoBytes: recording.bytes,
      filename: recording.filename,
      mimeType: recording.mimeType,
      durationSeconds: recording.durationSeconds,
    );
    recordingController.isUploading = false;

    if (result.success) {
      recordingUploaded = true;
    }

    return result;
  }

  Future<WorkoutActionResult> _saveSessionResults() async {
    final workoutId = _workoutId;

    if (workoutId == null) {
      return const WorkoutActionResult(
        success: false,
        message: "Data workout tidak valid.",
      );
    }

    for (final exercise in exercises) {
      final exerciseId = _exerciseId(exercise);
      final serverExerciseId = _serverExerciseId(exercise);

      if (exerciseId == null) {
        return const WorkoutActionResult(
          success: false,
          message: "Data exercise tidak valid.",
        );
      }

      final results = setResults[exerciseId] ?? {};

      for (var setNumber = 1; setNumber <= _sets(exercise); setNumber++) {
        final success = results[setNumber];

        if (success == null) {
          return const WorkoutActionResult(
            success: false,
            message: "Lengkapi semua set terlebih dahulu.",
          );
        }

        if (serverExerciseId == null || setNumber > _serverSets(exercise)) {
          continue;
        }

        final result = await WorkoutService.logPerformance(
          workoutId: workoutId,
          exerciseId: serverExerciseId,
          setNumber: setNumber,
          success: success,
        );

        if (!result.success) {
          return result;
        }
      }

      if (serverExerciseId != null) {
        final result = await WorkoutService.completeExercise(
          workoutId: workoutId,
          exerciseId: serverExerciseId,
        );

        if (!result.success) {
          return result;
        }
      }
    }

    return const WorkoutActionResult(
      success: true,
      message: "Berhasil",
    );
  }

  Future<void> _handleBackPressed() async {
    if (isSaving) {
      _showMessage("Tunggu proses selesai terlebih dahulu.");
      return;
    }

    final wasResting = isResting;
    final wasVideoPlaying = isVideoPlaying;

    _timer?.cancel();
    await _pauseVideo();

    if (!mounted) {
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text(
            "Tinggalkan workout?",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          content: const Text(
            "Apakah anda yakin ingin meninggalkan? Progress anda tidak akan tersimpan jika anda keluar.",
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("TETAP LATIHAN"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("KELUAR"),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (shouldLeave != true) {
      if (wasResting && restRemaining > 0) {
        _runRestTimer();
      } else if (wasVideoPlaying) {
        await _playVideo();
      }
      return;
    }

    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        await _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            tooltip: "Back",
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _handleBackPressed,
          ),
          title: const Text(
            "EXERCISING",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isResting) {
      return _buildRestScreen();
    }

    final exercise = _currentExercise;

    if (exercise == null) {
      return const Center(
        child: Text(
          "No Workout Available",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              children: [
                _buildExerciseTitle(exercise),
                const SizedBox(height: 18),
                _buildPracticePanels(exercise),
                const SizedBox(height: 18),
                _buildSetStatusBlock(exercise),
                const SizedBox(height: 18),
                _buildTransportControls(),
                const SizedBox(height: 14),
                _buildNextStepLabel(),
                const SizedBox(height: 18),
                _buildInfoPanel(exercise),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestScreen() {
    final progress = restTotal <= 0 ? 0.0 : restRemaining / restTotal;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final miniWidth = constraints.maxWidth < 560 ? 144.0 : 210.0;
          final miniHeight = miniWidth * 0.62;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 104),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "next",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "REST",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.lavender,
                          fontSize: 58,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: 218,
                        height: 218,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 218,
                              height: 218,
                              child: CircularProgressIndicator(
                                value: progress.clamp(0, 1).toDouble(),
                                strokeWidth: 14,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(restRemaining),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "After rest: ${_pendingStepLabel()}",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 16,
                width: miniWidth,
                height: miniHeight,
                child: _buildMiniRecordingPanel(),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _finishRest,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text(
                    "SKIP REST",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExerciseTitle(dynamic exercise) {
    return Column(
      children: [
        Text(
          _exerciseName(exercise).toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.04,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Day ${widget.dayNumber} - Exercise ${currentIndex + 1} of ${exercises.length}",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPracticePanels(dynamic exercise) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final tutorial = _buildMediaPanel(exercise);
        final recorder = _buildRecordingPanel();

        if (wide) {
          return SizedBox(
            height: 286,
            child: Row(
              children: [
                Expanded(child: tutorial),
                const SizedBox(width: 14),
                Expanded(child: recorder),
              ],
            ),
          );
        }

        return Column(
          children: [
            SizedBox(height: 240, child: tutorial),
            const SizedBox(height: 14),
            SizedBox(height: 240, child: recorder),
          ],
        );
      },
    );
  }

  Widget _buildMediaPanel(dynamic exercise) {
    final videoUrl = _videoUrl(exercise);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (videoUrl == null)
            _buildExerciseFallbackArt(exercise)
          else if (isVideoInitializing || _videoController == null)
            const Center(child: CircularProgressIndicator())
          else if (_videoController!.value.isInitialized)
            GestureDetector(
              onTap: _togglePlayback,
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
              ),
            )
          else
            _buildExerciseFallbackArt(exercise),
          Positioned(
            left: 12,
            top: 12,
            child: _MediaBadge(
              label: "TUTORIAL",
              color: Colors.black.withValues(alpha: 0.62),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "${currentIndex + 1}/${exercises.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingPanel() {
    final ready = recordingController.isRecording;
    final busy = recordingController.isInitializing ||
        recordingController.isStopping ||
        recordingController.isUploading;
    final statusLabel = _recordingStatusLabel();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050506),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ready ? AppColors.secondary : Colors.white24,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: recordingController.buildPreview()),
          Positioned(
            left: 12,
            top: 12,
            child: _MediaBadge(
              label: "USER RECORD",
              color: ready
                  ? AppColors.danger.withValues(alpha: 0.86)
                  : Colors.black.withValues(alpha: 0.64),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _MediaBadge(
              label: ready
                  ? _formatDuration(recordingController.elapsedSeconds)
                  : statusLabel,
              color: Colors.black.withValues(alpha: 0.64),
            ),
          ),
          if (!ready)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          busy
                              ? Icons.hourglass_top_rounded
                              : Icons.videocam_outlined,
                          color: Colors.white,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          statusLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        if (recordingController.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            recordingController.errorMessage!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: busy || isSaving
                                ? null
                                : _startWorkoutRecording,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: AppColors.secondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            icon: const Icon(Icons.videocam_rounded),
                            label: const Text(
                              "AKTIFKAN KAMERA",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (recordingController.isUploading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.72),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniRecordingPanel() {
    final ready = recordingController.isRecording;
    final statusLabel =
        ready ? _formatDuration(recordingController.elapsedSeconds) : "OFF";

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050506),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ready ? AppColors.secondary : Colors.white24,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: recordingController.buildPreview()),
          if (!ready)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.58),
              child: const Center(
                child: Icon(
                  Icons.videocam_outlined,
                  color: Colors.white70,
                  size: 26,
                ),
              ),
            ),
          Positioned(
            left: 8,
            top: 8,
            child: _MediaBadge(
              label: "REC",
              color: ready
                  ? AppColors.danger.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.64),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: _MediaBadge(
              label: statusLabel,
              color: Colors.black.withValues(alpha: 0.64),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseFallbackArt(dynamic exercise) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF9F9FB),
            Color(0xFFE9EDF4),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TrainingLinePainter(),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Text(
                    _exerciseName(exercise),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF20222B),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetStatusBlock(dynamic exercise) {
    return Column(
      children: [
        Text(
          _exerciseName(exercise).toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "set",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        Text(
          currentSetNumber.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.lavender,
            fontSize: 64,
            height: 0.92,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "of ${_sets(exercise)} - ${_workValue(exercise)} ${_workLabel(exercise).toLowerCase()}",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildTransportControls() {
    final canSubmit = _canSubmitExerciseResult;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundControlButton(
          tooltip: "Previous set",
          caption: "PREV SET",
          icon: Icons.skip_previous_rounded,
          size: 56,
          onPressed: isSaving ? null : _goPreviousStep,
        ),
        const SizedBox(width: 18),
        _RoundControlButton(
          tooltip: isVideoPlaying ? "Pause" : "Play",
          icon: isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 82,
          backgroundColor: AppColors.primary,
          iconColor: Colors.white,
          iconSize: 50,
          onPressed:
              isSaving || _videoController == null ? null : _togglePlayback,
        ),
        const SizedBox(width: 18),
        _RoundControlButton(
          tooltip: _nextButtonTooltip(),
          caption: _nextButtonCaption(),
          icon: Icons.skip_next_rounded,
          size: 56,
          onPressed: canSubmit ? _completeCurrentSetFromNextButton : null,
        ),
      ],
    );
  }

  Widget _buildNextStepLabel() {
    return Text(
      _nextStepText(),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildInfoPanel(dynamic exercise) {
    final description = _exerciseDescription(exercise);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: "SET $currentSetNumber/${_sets(exercise)}"),
              _InfoChip(label: "${_restSeconds(exercise)}s REST"),
              _InfoChip(label: _exerciseType(exercise).toUpperCase()),
              if (_videoUrl(exercise) != null) const _InfoChip(label: "VIDEO"),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFDAD6E1),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  dynamic get _currentExercise {
    if (exercises.isEmpty) {
      return null;
    }

    final safeIndex = currentIndex.clamp(0, exercises.length - 1).toInt();
    return exercises[safeIndex];
  }

  int? get _workoutId => _toInt(workoutData?["id"]);

  bool get _canSubmitExerciseResult =>
      !isSaving &&
      (recordingController.isRecording ||
          (recordingController.hasRecordedVideo &&
              _areAllExercisesCompleted())) &&
      !recordingController.isStopping &&
      !recordingController.isUploading;

  int? _exerciseId(dynamic exercise) {
    return _toInt(_asMap(exercise)?["id"] ?? _asMap(exercise)?["exercise_id"]);
  }

  int? _serverExerciseId(dynamic exercise) {
    final map = _asMap(exercise);

    if (_toBool(map?["local_only"])) {
      return _toInt(map?["server_exercise_id"]);
    }

    return _toInt(
      map?["server_exercise_id"] ?? map?["id"] ?? map?["exercise_id"],
    );
  }

  int _serverSets(dynamic exercise) {
    final sets = _toInt(_asMap(exercise)?["server_sets"]);
    return sets == null || sets < 1 ? _sets(exercise) : sets;
  }

  int _sets(dynamic exercise) {
    final sets = _toInt(_asMap(exercise)?["sets"]);
    return sets == null || sets < 1 ? 1 : sets;
  }

  String _workValue(dynamic exercise) {
    final duration = _durationSeconds(exercise);

    if (_exerciseType(exercise).toLowerCase() == "time" && duration != null) {
      return "${duration}s";
    }

    final reps = _textValue(exercise, "reps");

    if (reps != null) {
      return reps;
    }

    return duration == null ? "-" : "${duration}s";
  }

  String _workLabel(dynamic exercise) {
    if (_exerciseType(exercise).toLowerCase() == "time" ||
        _durationSeconds(exercise) != null) {
      return "DURATION";
    }

    return "REPS";
  }

  int? _durationSeconds(dynamic exercise) {
    return _toInt(
      _asMap(exercise)?["duration"] ?? _asMap(exercise)?["duration_seconds"],
    );
  }

  int _restSeconds(dynamic exercise) {
    final seconds = _toInt(_asMap(exercise)?["rest_seconds"]);
    return seconds == null || seconds < 0 ? 60 : seconds;
  }

  String _exerciseName(dynamic exercise) {
    return _textValue(exercise, "name") ??
        _textValue(exercise, "title") ??
        "Exercise";
  }

  String _exerciseType(dynamic exercise) {
    return _textValue(exercise, "type") ?? "training";
  }

  String? _exerciseDescription(dynamic exercise) {
    return _textValue(exercise, "description") ??
        _textValue(exercise, "instructions");
  }

  String? _videoUrl(dynamic exercise) {
    return _textValue(exercise, "video_url") ?? _textValue(exercise, "video");
  }

  int _activeSetNumber(dynamic exercise) {
    return _activeSetNumberFor(exercise, setResults);
  }

  int _activeSetNumberFor(
    dynamic exercise,
    Map<int, Map<int, bool>> results,
  ) {
    final id = _exerciseId(exercise);
    final sets = _sets(exercise);
    final logs = id == null ? <int, bool>{} : results[id] ?? {};

    for (var setNumber = 1; setNumber <= sets; setNumber++) {
      if (!logs.containsKey(setNumber)) {
        return setNumber;
      }
    }

    return sets;
  }

  bool _isExerciseComplete(dynamic exercise) {
    return _isExerciseCompleteWithData(exercise, setResults);
  }

  bool _isExerciseCompleteWithData(
    dynamic exercise,
    Map<int, Map<int, bool>> results,
  ) {
    final id = _exerciseId(exercise);

    if (id == null) {
      return false;
    }

    return (results[id]?.length ?? 0) >= _sets(exercise);
  }

  bool _areAllExercisesCompleted() {
    return exercises.isNotEmpty && exercises.every(_isExerciseComplete);
  }

  int? _nextIncompleteExerciseIndex({int startAfter = -1}) {
    for (var index = startAfter + 1; index < exercises.length; index++) {
      if (!_isExerciseComplete(exercises[index])) {
        return index;
      }
    }

    for (var index = 0;
        index <= startAfter && index < exercises.length;
        index++) {
      if (!_isExerciseComplete(exercises[index])) {
        return index;
      }
    }

    return null;
  }

  String _nextStepText() {
    final exercise = _currentExercise;

    if (exercise == null) {
      return "Next: -";
    }

    final sets = _sets(exercise);
    final isFinalWorkoutSet =
        currentIndex >= exercises.length - 1 && currentSetNumber >= sets;

    if (!isFinalWorkoutSet && _restSeconds(exercise) > 0) {
      return "Next: Rest";
    }

    if (currentSetNumber < sets) {
      return "Next set: Set ${currentSetNumber + 1} of $sets";
    }

    if (currentIndex < exercises.length - 1) {
      return "Next exercise: ${_exerciseName(exercises[currentIndex + 1])}";
    }

    return "Next: Finish workout";
  }

  String _pendingStepLabel() {
    final nextIndex = pendingExerciseIndex;
    final nextSet = pendingSetNumber;

    if (nextIndex == null ||
        nextSet == null ||
        nextIndex < 0 ||
        nextIndex >= exercises.length) {
      return "Workout";
    }

    return "${_exerciseName(exercises[nextIndex])} - set $nextSet";
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;

    return "${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}";
  }

  String _recordingStatusLabel() {
    if (recordingController.isUploading) {
      return "UPLOADING";
    }

    if (recordingController.isStopping) {
      return "SAVING RECORD";
    }

    if (recordingController.isInitializing) {
      return "CAMERA STARTING";
    }

    if (recordingController.hasRecordedVideo) {
      return "READY TO UPLOAD";
    }

    if (!recordingController.isSupported) {
      return "CAMERA UNSUPPORTED";
    }

    if (!recordingController.hasCameraPermission) {
      return "CAMERA REQUIRED";
    }

    return "RECORDING OFF";
  }

  String _nextButtonCaption() {
    final exercise = _currentExercise;

    if (exercise == null) {
      return "NEXT";
    }

    final sets = _sets(exercise);
    final isFinalWorkoutSet =
        currentIndex >= exercises.length - 1 && currentSetNumber >= sets;

    if (!isFinalWorkoutSet && _restSeconds(exercise) > 0) {
      return "REST";
    }

    if (currentSetNumber < sets) {
      return "NEXT SET";
    }

    if (currentIndex < exercises.length - 1) {
      return "NEXT EXERCISE";
    }

    return "FINISH";
  }

  String _nextButtonTooltip() {
    final exercise = _currentExercise;

    if (exercise == null) {
      return "Next";
    }

    final sets = _sets(exercise);
    final isFinalWorkoutSet =
        currentIndex >= exercises.length - 1 && currentSetNumber >= sets;

    if (!isFinalWorkoutSet && _restSeconds(exercise) > 0) {
      return "Selesaikan set $currentSetNumber, masuk rest";
    }

    if (currentSetNumber < sets) {
      return "Selesaikan set $currentSetNumber, lanjut set ${currentSetNumber + 1}";
    }

    if (currentIndex < exercises.length - 1) {
      return "Selesaikan exercise ini, lanjut exercise berikutnya";
    }

    return "Selesaikan workout";
  }

  String? _textValue(dynamic exercise, String key) {
    final value = _asMap(exercise)?[key]?.toString().trim();

    if (value == null || value.isEmpty || value == "null") {
      return null;
    }

    return value;
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase();
    return text == "true" || text == "1" || text == "yes";
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showRecordingCaution() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 5),
        content: Row(
          children: const [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Take your time, dont be rush, just do your best",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.tooltip,
    required this.icon,
    required this.size,
    required this.onPressed,
    this.caption,
    this.backgroundColor = const Color(0xFF24242D),
    this.iconColor = Colors.white,
    this.iconSize = 32,
  });

  final String tooltip;
  final IconData icon;
  final double size;
  final VoidCallback? onPressed;
  final String? caption;
  final Color backgroundColor;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: IconButton(
              onPressed: onPressed,
              style: IconButton.styleFrom(
                backgroundColor: onPressed == null
                    ? backgroundColor.withValues(alpha: 0.45)
                    : backgroundColor,
                shape: const CircleBorder(),
              ),
              icon: Icon(
                icon,
                color: onPressed == null ? Colors.white38 : iconColor,
                size: iconSize,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: 96,
              child: Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onPressed == null ? Colors.white38 : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _TrainingLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orangePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final cyanPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.2),
      Offset(size.width * 0.92, size.height * 0.2),
      orangePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.8),
      Offset(size.width * 0.92, size.height * 0.8),
      cyanPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.shortestSide * 0.34,
      orangePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
