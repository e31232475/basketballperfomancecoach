import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/workout_service.dart';
import 'workout_player_screen.dart';
import 'workout_video_screen.dart';

class WorkoutDayDetailScreen extends StatefulWidget {
  const WorkoutDayDetailScreen({
    super.key,
    required this.dayNumber,
  });

  final int dayNumber;

  @override
  State<WorkoutDayDetailScreen> createState() => _WorkoutDayDetailScreenState();
}

class _WorkoutDayDetailScreenState extends State<WorkoutDayDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic>? workoutData;
  List<dynamic> exercises = [];
  WorkoutAccessState? accessState;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
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
    final access = await WorkoutService.getWorkoutAccess(widget.dayNumber);

    if (!mounted) {
      return;
    }

    setState(() {
      workoutData = _asMap(workout);
      exercises = exerciseList
          .map((exercise) => _asMap(exercise) ?? exercise)
          .toList(growable: false);
      accessState = access;
      isLoading = false;
    });
  }

  Future<void> _startWorkout() async {
    if (exercises.isEmpty) {
      _showMessage("Workout belum memiliki exercise.");
      return;
    }

    final access = await WorkoutService.getWorkoutAccess(widget.dayNumber);

    if (!mounted) {
      return;
    }

    setState(() {
      accessState = access;
    });

    if (!access.canStart) {
      _showMessage(access.message);
      return;
    }

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutPlayerScreen(dayNumber: widget.dayNumber),
      ),
    );

    if (!mounted) {
      return;
    }

    if (completed == true) {
      Navigator.pop(context, true);
      return;
    }

    await _loadWorkout();
  }

  Future<void> _openExerciseVideo(dynamic exercise) async {
    final videoUrl = _videoUrl(exercise);

    if (videoUrl == null) {
      _showMessage("Video gerakan belum tersedia.");
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutVideoScreen(videoUrl: videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "DAY ${widget.dayNumber}",
          style: const TextStyle(
            color: AppColors.lavender,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadWorkout,
              child: exercises.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
                      children: [
                        _buildHeader(),
                        if (_shouldShowAccessBanner()) ...[
                          const SizedBox(height: 16),
                          _buildAccessBanner(),
                        ],
                        const SizedBox(height: 16),
                        const _EmptyExerciseState(),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                      children: [
                        _buildHeader(),
                        if (_shouldShowAccessBanner()) ...[
                          const SizedBox(height: 16),
                          _buildAccessBanner(),
                        ],
                        const SizedBox(height: 22),
                        const Text(
                          "Workout List",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...List.generate(
                          exercises.length,
                          (index) => _ExerciseListTile(
                            index: index,
                            name: _exerciseName(exercises[index]),
                            subtitle: _exerciseSubtitle(exercises[index]),
                            description: _exerciseDescription(
                              exercises[index],
                            ),
                            hasVideo: _videoUrl(exercises[index]) != null,
                            chips: _exerciseChips(exercises[index]),
                            onPlay: () => _openExerciseVideo(
                              exercises[index],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
      bottomNavigationBar: isLoading
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: AppColors.appBar,
                  border: Border(
                    top: BorderSide(color: Colors.white10),
                  ),
                ),
                child: SizedBox(
                  height: 56,
                  child: _buildStartButton(),
                ),
              ),
            ),
    );
  }

  Widget _buildStartButton() {
    final canStart = accessState?.canStart ?? false;
    final label = canStart ? "START" : accessState?.statusLabel ?? "PREVIEW";

    return ElevatedButton.icon(
      onPressed: exercises.isEmpty ? null : _startWorkout,
      icon: Icon(
        canStart ? Icons.play_arrow_rounded : Icons.visibility_outlined,
      ),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }

  bool _shouldShowAccessBanner() {
    final access = accessState;
    return access != null && !access.canStart;
  }

  Widget _buildAccessBanner() {
    final access = accessState;

    if (access == null || access.canStart) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.lavender.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_outlined,
            color: AppColors.lavender,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              access.message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            access.statusLabel,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.lavender,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final estimatedDuration = _estimatedDuration();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Icon(
                  Icons.sports_basketball,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _workoutTitle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Day ${widget.dayNumber} - ${exercises.length} exercises",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: "EXERCISES",
                  value: exercises.length.toString(),
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: "DURATION",
                  value: estimatedDuration == 0 ? "-" : "${estimatedDuration}m",
                  color: AppColors.lavender,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _estimatedDuration() {
    final fromWorkout = _toInt(workoutData?["estimated_duration"]);

    if (fromWorkout != null && fromWorkout > 0) {
      return fromWorkout;
    }

    var totalSeconds = 0;

    for (final exercise in exercises) {
      totalSeconds += (_durationSeconds(exercise) ?? 45) * _sets(exercise);
      totalSeconds += _restSeconds(exercise) * (_sets(exercise) - 1);
    }

    if (totalSeconds == 0) {
      return 0;
    }

    return (totalSeconds / 60).ceil();
  }

  List<String> _exerciseChips(dynamic exercise) {
    final chips = <String>[
      "${_sets(exercise)} SETS",
      "${_workValue(exercise)} ${_workLabel(exercise)}",
      "${_restSeconds(exercise)}s REST",
    ];

    final type = _exerciseType(exercise);

    if (type != "training") {
      chips.insert(0, type.toUpperCase());
    }

    if (_videoUrl(exercise) != null) {
      chips.add("VIDEO");
    }

    return chips;
  }

  String _exerciseSubtitle(dynamic exercise) {
    return "${_sets(exercise)} sets - ${_workValue(exercise)} ${_workLabel(exercise).toLowerCase()}";
  }

  String? _exerciseDescription(dynamic exercise) {
    return _textValue(exercise, "description") ??
        _textValue(exercise, "instructions");
  }

  String _workoutTitle() {
    final title = workoutData?["title"]?.toString().trim();

    if (title != null && title.isNotEmpty && title != "null") {
      return title;
    }

    return "Workout Day ${widget.dayNumber}";
  }

  String _exerciseName(dynamic exercise) {
    final name = _textValue(exercise, "name") ?? _textValue(exercise, "title");
    return name ?? "Exercise";
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

  String _exerciseType(dynamic exercise) {
    return _textValue(exercise, "type") ?? "training";
  }

  String? _videoUrl(dynamic exercise) {
    return _textValue(exercise, "video_url") ?? _textValue(exercise, "video");
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  const _ExerciseListTile({
    required this.index,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.hasVideo,
    required this.chips,
    required this.onPlay,
  });

  final int index;
  final String name;
  final String subtitle;
  final String? description;
  final bool hasVideo;
  final List<String> chips;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.secondary),
            ),
            alignment: Alignment.center,
            child: Text(
              "${index + 1}",
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: hasVideo
                                ? "Play video"
                                : "Video belum tersedia",
                            onPressed: onPlay,
                            icon: const Icon(Icons.play_circle_outline),
                            color:
                                hasVideo ? AppColors.primary : Colors.white54,
                            iconSize: 24,
                            constraints: const BoxConstraints.tightFor(
                              width: 36,
                              height: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "preview",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  hasVideo ? AppColors.primary : Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFC8C4CE),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips
                      .map(
                        (chip) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.panelSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            chip,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExerciseState extends StatelessWidget {
  const _EmptyExerciseState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: const Text(
        "Workout list belum tersedia dari backend.",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
