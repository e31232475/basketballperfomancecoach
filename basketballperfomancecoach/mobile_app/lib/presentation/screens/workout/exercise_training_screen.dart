import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/glass_panel.dart';
import 'workout_score_screen.dart';

class ExerciseTrainingScreen extends StatefulWidget {
  const ExerciseTrainingScreen({super.key, required this.detail});

  final WorkoutDetail detail;

  @override
  State<ExerciseTrainingScreen> createState() => _ExerciseTrainingScreenState();
}

class _ExerciseTrainingScreenState extends State<ExerciseTrainingScreen> {
  VideoPlayerController? _videoController;
  Timer? _restTimer;
  int _exerciseIndex = 0;
  int _setNumber = 1;
  int _loggedSets = 0;
  int _successfulSets = 0;
  int _failedSets = 0;
  int _restSeconds = 0;
  bool _isResting = false;
  bool _isSubmitting = false;
  bool _workoutFinished = false;

  ExerciseItem get _exercise => widget.detail.exercises[_exerciseIndex];
  int get _totalSets =>
      widget.detail.exercises.fold(0, (sum, item) => sum + item.sets);

  @override
  void initState() {
    super.initState();
    _setupVideo();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _setupVideo() async {
    final url = _exercise.videoUrl;
    await _videoController?.dispose();
    _videoController = null;

    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    await controller.setLooping(true);
    await controller.initialize();

    if (!mounted || _videoController != controller) {
      await controller.dispose();
      return;
    }

    await controller.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_workoutFinished) {
      return _CompletionView(
        successfulSets: _successfulSets,
        failedSets: _failedSets,
        onComplete: _completeWorkout,
      );
    }

    return Scaffold(
      appBar: const BpcTopBar(showBack: true, compact: true),
      body: Stack(
        children: [
          Positioned.fill(child: _VideoPane(controller: _videoController)),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: _isResting ? 0.72 : 0.48),
            ),
          ),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: _isResting ? _restView(context) : _trainingView(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trainingView(BuildContext context) {
    final progress = _totalSets == 0 ? 0.0 : _loggedSets / _totalSets;
    final target = _exercise.duration != null
        ? '${_exercise.duration} sec'
        : _exercise.reps;

    return Padding(
      key: const ValueKey('training'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _exercise.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Set $_setNumber of ${_exercise.sets} - $target',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: AppColors.orange,
                  backgroundColor: AppColors.panelSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 10),
                Text(
                  '$_loggedSets of $_totalSets sets logged',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: IconButton.filledTonal(
                  tooltip: 'Failed set',
                  onPressed: _isSubmitting ? null : () => _markSet(false),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.text,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _markSet(true),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('COMPLETE SET'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 54,
                height: 54,
                child: Icon(Icons.timer_outlined, color: AppColors.lavender),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _restView(BuildContext context) {
    final restTotal = _exercise.restSeconds == 0 ? 1 : _exercise.restSeconds;
    final progress = (_restSeconds / restTotal).clamp(0.0, 1.0);

    return Center(
      key: const ValueKey('rest'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_rounded,
                color: AppColors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '$_restSeconds',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prepare for next set',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: AppColors.cyan,
                backgroundColor: AppColors.panelSoft,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markSet(bool success) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    final ok = await context.read<WorkoutProvider>().logSet(
      userId: userId,
      workoutId: widget.detail.workout.id,
      exerciseId: _exercise.id,
      setNumber: _setNumber,
      success: success,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!ok) {
      final message =
          context.read<WorkoutProvider>().errorMessage ?? 'Failed to save set';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() {
      _loggedSets++;
      if (success) {
        _successfulSets++;
      } else {
        _failedSets++;
      }
    });

    if (_isLastSet()) {
      await _videoController?.pause();
      setState(() => _workoutFinished = true);
      return;
    }

    _startRest();
  }

  bool _isLastSet() {
    return _exerciseIndex == widget.detail.exercises.length - 1 &&
        _setNumber == _exercise.sets;
  }

  void _startRest() {
    _videoController?.pause();
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSeconds = _exercise.restSeconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_restSeconds <= 1) {
        timer.cancel();
        _advanceSet();
        return;
      }

      setState(() => _restSeconds--);
    });
  }

  void _advanceSet() {
    setState(() {
      if (_setNumber < _exercise.sets) {
        _setNumber++;
      } else {
        _exerciseIndex++;
        _setNumber = 1;
      }
      _isResting = false;
    });
    _setupVideo();
  }

  Future<void> _completeWorkout() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      return;
    }

    final score = await context.read<WorkoutProvider>().completeWorkout(
      userId: userId,
      dayNumber: widget.detail.workout.dayNumber,
    );

    if (!mounted) {
      return;
    }

    if (score == null) {
      final message =
          context.read<WorkoutProvider>().errorMessage ??
          'Workout completion failed';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    await context.read<ProgressProvider>().load(userId);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => WorkoutScoreScreen(score: score)),
    );
  }
}

class _VideoPane extends StatelessWidget {
  const _VideoPane({required this.controller});

  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;

    if (activeController == null || !activeController.value.isInitialized) {
      return Container(
        color: AppColors.navy,
        child: const Center(
          child: Icon(
            Icons.play_circle_outline_rounded,
            size: 72,
            color: AppColors.muted,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: activeController.value.size.width,
        height: activeController.value.size.height,
        child: VideoPlayer(activeController),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.successfulSets,
    required this.failedSets,
    required this.onComplete,
  });

  final int successfulSets;
  final int failedSets;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: const BpcTopBar(showBack: true, compact: true),
      body: EliteBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(),
                GlassPanel(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.orange,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Workout Completed',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: MetricTile(
                              label: 'Successful',
                              value: '$successfulSets',
                              icon: Icons.check_circle_outline_rounded,
                              color: AppColors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricTile(
                              label: 'Failed',
                              value: '$failedSets',
                              icon: Icons.close_rounded,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: 'Complete Workout',
                        icon: Icons.done_all_rounded,
                        isLoading: provider.isLoading,
                        onPressed: onComplete,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
