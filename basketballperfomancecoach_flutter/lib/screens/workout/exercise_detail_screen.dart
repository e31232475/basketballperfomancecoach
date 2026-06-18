import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/workout_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.dayNumber,
  });

  final int dayNumber;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  static const Color _background = Color(0xFF111116);
  static const Color _panel = Color(0xFF1D1D24);
  static const Color _panelSoft = Color(0xFF24242D);
  static const Color _orange = Color(0xFFFF660F);
  static const Color _cyan = Color(0xFF12E7FF);
  static const Color _lavender = Color(0xFFD6C7FF);

  bool isLoading = true;
  bool isSavingSet = false;
  bool isCompletingWorkout = false;
  bool isResting = false;

  int currentExerciseIndex = 0;
  int? pendingExerciseIndex;
  int restRemaining = 0;
  int restTotal = 0;

  Map<String, dynamic>? workoutData;
  List<dynamic> exercises = [];
  Set<int> completedExerciseIds = {};
  Map<int, Map<int, bool>> setResults = {};

  Timer? restTimer;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  @override
  void dispose() {
    restTimer?.cancel();
    super.dispose();
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
    final workoutMap = _asMap(workout);
    final workoutId = _toInt(workoutMap?["id"]);
    final savedCompletedIds = workoutId == null
        ? <int>{}
        : await WorkoutService.getCompletedExerciseIds(workoutId);
    final normalizedExercises = exerciseList
        .map((exercise) => _asMap(exercise) ?? exercise)
        .toList(growable: false);
    final loadedSetResults = _setResultsFromExercises(normalizedExercises);
    final loadedCompletedIds = {
      ..._completedExerciseIdsFrom(normalizedExercises),
      ...savedCompletedIds,
    };

    for (final exercise in normalizedExercises) {
      final id = _exerciseId(exercise);

      if (id != null &&
          loadedCompletedIds.contains(id) &&
          (loadedSetResults[id]?.isEmpty ?? true)) {
        loadedSetResults[id] = {
          for (var setNumber = 1; setNumber <= _sets(exercise); setNumber++)
            setNumber: true,
        };
      }

      if (_isExerciseCompleteWithData(
        exercise,
        loadedSetResults,
        loadedCompletedIds,
      )) {
        if (id != null) {
          loadedCompletedIds.add(id);
        }
      }
    }

    final firstActiveIndex = normalizedExercises.indexWhere(
      (exercise) => !_isExerciseCompleteWithData(
        exercise,
        loadedSetResults,
        loadedCompletedIds,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      workoutData = workoutMap;
      exercises = normalizedExercises;
      setResults = loadedSetResults;
      completedExerciseIds = loadedCompletedIds;
      currentExerciseIndex = firstActiveIndex == -1 ? 0 : firstActiveIndex;
      isLoading = false;
    });
  }

  Future<void> _logCurrentSet(bool success) async {
    if (isSavingSet || isCompletingWorkout || isResting) {
      return;
    }

    final exercise = _currentExercise;
    final workoutId = _workoutId;
    final exerciseId = _exerciseId(exercise);

    if (workoutId == null || exerciseId == null) {
      _showMessage("Data latihan tidak valid");
      return;
    }

    if (_isExerciseComplete(exercise)) {
      _moveToNextExercise();
      return;
    }

    final setNumber = _activeSetNumber(exercise);

    setState(() {
      isSavingSet = true;
    });

    final result = await WorkoutService.logPerformance(
      workoutId: workoutId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      success: success,
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      setState(() {
        isSavingSet = false;
      });
      _showMessage(result.message);
      return;
    }

    final updatedResults = Map<int, Map<int, bool>>.from(setResults);
    final exerciseResults = Map<int, bool>.from(
      updatedResults[exerciseId] ?? {},
    );
    exerciseResults[setNumber] = success;
    updatedResults[exerciseId] = exerciseResults;

    final updatedCompletedIds = Set<int>.from(completedExerciseIds);
    final exerciseCompleted = exerciseResults.length >= _sets(exercise);

    if (exerciseCompleted) {
      updatedCompletedIds.add(exerciseId);
    }

    setState(() {
      setResults = updatedResults;
      completedExerciseIds = updatedCompletedIds;
      isSavingSet = false;
    });

    if (_areAllExercisesCompleted()) {
      await _finishWorkoutDay();
      return;
    }

    final nextIndex = exerciseCompleted ? _nextIncompleteExerciseIndex() : null;

    _startRest(
      _restSeconds(exercise),
      nextExerciseIndex: nextIndex,
    );
  }

  Future<void> _finishWorkoutDay() async {
    if (isCompletingWorkout) {
      return;
    }

    setState(() {
      isCompletingWorkout = true;
    });

    final result = await WorkoutService.completeWorkout(widget.dayNumber);

    if (!mounted) {
      return;
    }

    if (result.success) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      isCompletingWorkout = false;
    });

    _showMessage(result.message);
  }

  void _startRest(int seconds, {int? nextExerciseIndex}) {
    restTimer?.cancel();
    pendingExerciseIndex = nextExerciseIndex;

    if (seconds <= 0) {
      _finishRest();
      return;
    }

    setState(() {
      isResting = true;
      restRemaining = seconds;
      restTotal = seconds;
    });

    restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  void _finishRest() {
    restTimer?.cancel();
    restTimer = null;

    if (!mounted) {
      return;
    }

    setState(() {
      isResting = false;
      restRemaining = 0;
      restTotal = 0;

      if (pendingExerciseIndex != null) {
        currentExerciseIndex = pendingExerciseIndex!;
      }

      pendingExerciseIndex = null;
    });
  }

  void _moveToNextExercise() {
    final nextIndex = _nextIncompleteExerciseIndex();

    if (nextIndex == null) {
      return;
    }

    setState(() {
      currentExerciseIndex = nextIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF17171E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "BPC ELITE",
          style: TextStyle(
            color: _lavender,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _orange,
              ),
            )
          : isResting
              ? _buildRestScreen()
              : _buildTrackerBody(),
      bottomNavigationBar: isLoading || isResting || exercises.isEmpty
          ? null
          : _buildActionBar(),
    );
  }

  Widget _buildTrackerBody() {
    final exercise = _currentExercise;

    if (workoutData == null || exercise == null) {
      return const Center(
        child: Text(
          "No Workout Available",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return RefreshIndicator(
      color: _orange,
      onRefresh: _loadWorkout,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          _buildWorkoutSummary(exercise),
          const SizedBox(height: 18),
          _buildPreviewCard(exercise),
          const SizedBox(height: 28),
          _buildExerciseIntro(exercise),
          const SizedBox(height: 24),
          _buildMetricRow(exercise),
          const SizedBox(height: 36),
          _buildSetsHeader(exercise),
          const SizedBox(height: 14),
          ...List.generate(
            _sets(exercise),
            (index) => _buildSetTile(exercise, index + 1),
          ),
          const SizedBox(height: 14),
          _buildPerformanceStats(exercise),
        ],
      ),
    );
  }

  Widget _buildWorkoutSummary(dynamic exercise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: _orange),
            ),
            child: Center(
              child: Text(
                "${currentExerciseIndex + 1}",
                style: const TextStyle(
                  color: _orange,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _workoutTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Day ${widget.dayNumber} • ${exercises.length} exercises • active: ${_exerciseName(exercise)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(dynamic exercise) {
    final videoUrl = _videoUrl(exercise);

    return Container(
      height: 192,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.15, -0.1),
                radius: 1,
                colors: [
                  _orange.withValues(alpha: 0.48),
                  const Color(0xFF152035),
                  const Color(0xFF0D0D13),
                ],
              ),
            ),
          ),
          Positioned(
            left: -36,
            top: 22,
            child: _glowCircle(_orange.withValues(alpha: 0.28), 150),
          ),
          Positioned(
            right: -20,
            bottom: -30,
            child: _glowCircle(_cyan.withValues(alpha: 0.22), 126),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: _orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    videoUrl == null ? Icons.fitness_center : Icons.play_arrow,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    _exerciseName(exercise),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                "ID ${_exerciseId(exercise) ?? '-'}",
                style: const TextStyle(
                  color: _lavender,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.44),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                videoUrl == null ? "DATABASE EXERCISE" : "VIDEO FROM DATABASE",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_orange, _cyan],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildExerciseIntro(dynamic exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cyan.withValues(alpha: 0.7)),
          ),
          child: Text(
            _exerciseType(exercise).toUpperCase(),
            style: const TextStyle(
              color: _cyan,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _exerciseName(exercise),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _exerciseDescription(exercise),
          style: const TextStyle(
            color: Color(0xFFE7E3EA),
            fontSize: 16,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        _buildBackendChips(exercise),
      ],
    );
  }

  Widget _buildBackendChips(dynamic exercise) {
    final reps = _reps(exercise);
    final details = <String>[
      if (reps != "-") "JUMLAH REPETISI: $reps",
      "SETS: ${_sets(exercise)}",
      "REST: ${_restSeconds(exercise)}s",
      if (_equipment(exercise) != null) "EQUIPMENT: ${_equipment(exercise)}",
      if (_muscleGroup(exercise) != null) "TARGET: ${_muscleGroup(exercise)}",
      if (_durationSeconds(exercise) != null)
        "DURATION: ${_durationSeconds(exercise)}s",
      if (_videoUrl(exercise) != null) "VIDEO: AVAILABLE",
    ];

    if (details.isEmpty) {
      details.add("SOURCE: BACKEND DATABASE");
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: details.map((detail) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _panelSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Text(
            detail,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricRow(dynamic exercise) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            value: _sets(exercise).toString(),
            label: "SETS",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            value: _workValue(exercise),
            label: _workLabel(exercise),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            value: "${_restSeconds(exercise)}s",
            label: "REST",
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String value,
    required String label,
  }) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: _lavender,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetsHeader(dynamic exercise) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Exercise Sets",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          "${_completedSetCount(exercise)} / ${_sets(exercise)} COMPLETED",
          style: const TextStyle(
            color: Color(0xFFFFC29C),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSetTile(dynamic exercise, int setNumber) {
    final result = _setResult(exercise, setNumber);
    final isLogged = result != null;
    final activeSet = _activeSetNumber(exercise);
    final isActive = !isLogged && setNumber == activeSet;
    final locked = !isLogged && !isActive;
    final accent = isLogged ? _orange : (isActive ? _cyan : Colors.white10);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: locked ? 0.42 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isActive ? _panelSoft : _panel,
          border: Border.all(color: Colors.white10),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                color: accent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
                  child: Row(
                    children: [
                      _buildSetBadge(setNumber, result, isActive, locked),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Set ${setNumber.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                color: isActive
                                    ? _cyan
                                    : locked
                                        ? Colors.white38
                                        : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _setSubtitle(exercise, result, isActive),
                              style: TextStyle(
                                color: locked ? Colors.white30 : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSetTrailing(exercise, result, isActive, locked),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetBadge(
    int setNumber,
    bool? result,
    bool isActive,
    bool locked,
  ) {
    if (result != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: _orange,
          shape: BoxShape.circle,
        ),
        child: Icon(
          result ? Icons.check : Icons.close,
          color: Colors.white,
          size: 24,
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? _cyan : Colors.white30,
          width: 2,
        ),
      ),
      child: Center(
        child: locked
            ? const Icon(
                Icons.lock_outline,
                color: Colors.white38,
                size: 18,
              )
            : Text(
                setNumber.toString(),
                style: const TextStyle(
                  color: _cyan,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }

  Widget _buildSetTrailing(
    dynamic exercise,
    bool? result,
    bool isActive,
    bool locked,
  ) {
    if (locked) {
      return const Icon(
        Icons.lock_outline,
        color: Colors.white38,
      );
    }

    if (isActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _workValue(exercise),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.edit,
            color: Colors.white70,
            size: 22,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _workValue(exercise),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          result == true ? "REPS DONE" : "FAILED SET",
          style: TextStyle(
            color: result == true ? Colors.white70 : const Color(0xFFFFA58A),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceStats(dynamic exercise) {
    final logged = _completedSetCount(exercise);
    final sets = _sets(exercise);
    final successful = _successfulSetCount(exercise);
    final failed = _failedSetCount(exercise);
    final successPercentage =
        logged == 0 ? 0 : ((successful / logged) * 100).round();
    final volumePercentage = sets == 0 ? 0 : ((logged / sets) * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PERFORMANCE STATS",
            style: TextStyle(
              color: _lavender,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
          _buildStatLine(
            "Success Rate",
            "$successPercentage%",
            Colors.white,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: successPercentage / 100,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(_lavender),
            ),
          ),
          const SizedBox(height: 28),
          _buildStatLine(
            "Logged Sets",
            "$logged / $sets",
            _cyan,
          ),
          const SizedBox(height: 24),
          _buildStatLine(
            "Failed Sets",
            failed.toString(),
            const Color(0xFFFFA58A),
          ),
          const SizedBox(height: 34),
          Center(
            child: SizedBox(
              width: 136,
              height: 136,
              child: CustomPaint(
                painter: _ProgressRingPainter(volumePercentage / 100),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$volumePercentage%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const Text(
                        "VOLUME",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLine(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildRestScreen() {
    final progress = restTotal <= 0 ? 0.0 : restRemaining / restTotal;
    final nextExercise = pendingExerciseIndex == null
        ? _currentExercise
        : exercises[pendingExerciseIndex!];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            const Text(
              "REST",
              style: TextStyle(
                color: _cyan,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(_orange),
                    ),
                  ),
                  Text(
                    _formatDuration(restRemaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _exerciseName(nextExercise),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Next set ${_activeSetNumber(nextExercise).toString().padLeft(2, '0')}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _finishRest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: _orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "SKIP REST",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    final exercise = _currentExercise;
    final canLog = exercise != null &&
        !_isExerciseComplete(exercise) &&
        !isSavingSet &&
        !isCompletingWorkout;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        decoration: const BoxDecoration(
          color: Color(0xFF101015),
          border: Border(
            top: BorderSide(color: Colors.white10),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: canLog ? () => _logCurrentSet(false) : null,
                icon: const Icon(Icons.close),
                color: Colors.white,
                disabledColor: Colors.white30,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: canLog ? () => _logCurrentSet(true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    disabledBackgroundColor: _orange.withValues(alpha: 0.42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  icon: isSavingSet || isCompletingWorkout
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    isCompletingWorkout ? "FINISHING" : "COMPLETE SET",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: _lavender,
                ),
                Text(
                  _formatDuration(_restSeconds(exercise)),
                  style: const TextStyle(
                    color: _lavender,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<int, Map<int, bool>> _setResultsFromExercises(List<dynamic> items) {
    final results = <int, Map<int, bool>>{};

    for (final exercise in items) {
      final id = _exerciseId(exercise);

      if (id == null) {
        continue;
      }

      final setLogs = _asMap(exercise)?["set_logs"];

      if (setLogs is List) {
        final logs = <int, bool>{};

        for (final log in setLogs) {
          final logMap = _asMap(log);
          final setNumber = _toInt(logMap?["set_number"]);

          if (setNumber == null) {
            continue;
          }

          logs[setNumber] = _toBool(logMap?["success"]);
        }

        if (logs.isNotEmpty) {
          results[id] = logs;
          continue;
        }
      }

      final successful = _toInt(_asMap(exercise)?["successful_sets"]) ?? 0;
      final failed = _toInt(_asMap(exercise)?["failed_sets"]) ?? 0;
      final logged = math.max(
        _toInt(_asMap(exercise)?["logged_sets"]) ?? 0,
        successful + failed,
      );
      final sets = _sets(exercise);
      final logs = <int, bool>{};

      for (var setNumber = 1;
          setNumber <= math.min(successful, sets);
          setNumber++) {
        logs[setNumber] = true;
      }

      for (var setNumber = successful + 1;
          setNumber <= math.min(logged, sets);
          setNumber++) {
        logs[setNumber] = false;
      }

      if (logs.isNotEmpty) {
        results[id] = logs;
      }
    }

    return results;
  }

  Set<int> _completedExerciseIdsFrom(List<dynamic> exerciseList) {
    final ids = <int>{};

    for (final exercise in exerciseList) {
      final id = _exerciseId(exercise);

      if (id != null && _isCompletedValue(_asMap(exercise)?["completed"])) {
        ids.add(id);
      }
    }

    return ids;
  }

  bool _isExerciseComplete(dynamic exercise) {
    return _isExerciseCompleteWithData(
      exercise,
      setResults,
      completedExerciseIds,
    );
  }

  bool _isExerciseCompleteWithData(
    dynamic exercise,
    Map<int, Map<int, bool>> results,
    Set<int> completedIds,
  ) {
    final id = _exerciseId(exercise);

    if (id == null) {
      return false;
    }

    if (completedIds.contains(id)) {
      return true;
    }

    return (results[id]?.length ?? 0) >= _sets(exercise);
  }

  bool _areAllExercisesCompleted() {
    if (exercises.isEmpty) {
      return false;
    }

    return exercises.every(_isExerciseComplete);
  }

  int? _nextIncompleteExerciseIndex() {
    for (var index = currentExerciseIndex + 1;
        index < exercises.length;
        index++) {
      if (!_isExerciseComplete(exercises[index])) {
        return index;
      }
    }

    for (var index = 0;
        index <= currentExerciseIndex && index < exercises.length;
        index++) {
      if (!_isExerciseComplete(exercises[index])) {
        return index;
      }
    }

    return null;
  }

  int _activeSetNumber(dynamic exercise) {
    final id = _exerciseId(exercise);
    final sets = _sets(exercise);
    final results = id == null ? <int, bool>{} : setResults[id] ?? {};

    for (var setNumber = 1; setNumber <= sets; setNumber++) {
      if (!results.containsKey(setNumber)) {
        return setNumber;
      }
    }

    return sets;
  }

  bool? _setResult(dynamic exercise, int setNumber) {
    final id = _exerciseId(exercise);

    if (id == null) {
      return null;
    }

    return setResults[id]?[setNumber];
  }

  int _completedSetCount(dynamic exercise) {
    final id = _exerciseId(exercise);

    if (id == null) {
      return 0;
    }

    return setResults[id]?.length ?? 0;
  }

  int _successfulSetCount(dynamic exercise) {
    final id = _exerciseId(exercise);

    if (id == null) {
      return 0;
    }

    return setResults[id]?.values.where((value) => value).length ?? 0;
  }

  int _failedSetCount(dynamic exercise) {
    final id = _exerciseId(exercise);

    if (id == null) {
      return 0;
    }

    return setResults[id]?.values.where((value) => !value).length ?? 0;
  }

  String _setSubtitle(dynamic exercise, bool? result, bool isActive) {
    final work = _workValue(exercise);
    final label = _workLabel(exercise).toLowerCase();

    if (result == true) {
      return "$work $label done";
    }

    if (result == false) {
      return "$work $label attempted";
    }

    if (isActive) {
      return "Current Active Set";
    }

    return "$work $label";
  }

  dynamic get _currentExercise {
    if (exercises.isEmpty) {
      return null;
    }

    final safeIndex =
        currentExerciseIndex.clamp(0, exercises.length - 1).toInt();
    return exercises[safeIndex];
  }

  int? get _workoutId => _toInt(workoutData?["id"]);

  int? _exerciseId(dynamic exercise) {
    final map = _asMap(exercise);

    if (_toBool(map?["local_only"])) {
      return _toInt(map?["server_exercise_id"]) ??
          _toInt(map?["id"] ?? map?["exercise_id"]);
    }

    return _toInt(
      map?["server_exercise_id"] ?? map?["id"] ?? map?["exercise_id"],
    );
  }

  int _sets(dynamic exercise) {
    return math.max(_toInt(_asMap(exercise)?["sets"]) ?? 1, 1);
  }

  String _reps(dynamic exercise) {
    final reps = _asMap(exercise)?["reps"]?.toString().trim();

    if (reps == null || reps.isEmpty || reps == "null") {
      final duration = _toInt(_asMap(exercise)?["duration"]);
      return duration == null ? "-" : "${duration}s";
    }

    return reps;
  }

  String _workValue(dynamic exercise) {
    final duration = _durationSeconds(exercise);

    if (_exerciseType(exercise).toLowerCase() == "time" && duration != null) {
      return "${duration}s";
    }

    return _reps(exercise);
  }

  String _workLabel(dynamic exercise) {
    if (_exerciseType(exercise).toLowerCase() == "time" ||
        _durationSeconds(exercise) != null) {
      return "DURATION";
    }

    return "REPS";
  }

  int? _durationSeconds(dynamic exercise) {
    return _toInt(_asMap(exercise)?["duration"]);
  }

  int _restSeconds(dynamic exercise) {
    return math.max(_toInt(_asMap(exercise)?["rest_seconds"]) ?? 60, 0);
  }

  String _exerciseType(dynamic exercise) {
    final type = _asMap(exercise)?["type"]?.toString().trim();

    if (type == null || type.isEmpty || type == "null") {
      return "training";
    }

    return type;
  }

  String _exerciseName(dynamic exercise) {
    final name = _asMap(exercise)?["name"]?.toString().trim();

    if (name == null || name.isEmpty || name == "null") {
      return "Exercise";
    }

    return name;
  }

  String _exerciseDescription(dynamic exercise) {
    final description = _textValue(exercise, "description");

    if (description != null) {
      return description;
    }

    final instructions = _textValue(exercise, "instructions");

    if (instructions != null) {
      return instructions;
    }

    final type = _exerciseType(exercise);
    final rest = _restSeconds(exercise);
    final sets = _sets(exercise);
    final work = _workValue(exercise);
    final label = _workLabel(exercise).toLowerCase();

    return "Program dari database backend: $sets set, $work $label per set, tipe $type, istirahat $rest detik.";
  }

  String _workoutTitle() {
    final title = workoutData?["title"]?.toString().trim();

    if (title != null && title.isNotEmpty && title != "null") {
      return title;
    }

    return "Workout Day ${widget.dayNumber}";
  }

  String? _videoUrl(dynamic exercise) {
    return _textValue(exercise, "video_url") ?? _textValue(exercise, "video");
  }

  String? _equipment(dynamic exercise) {
    return _textValue(exercise, "equipment");
  }

  String? _muscleGroup(dynamic exercise) {
    return _textValue(exercise, "muscle_group") ??
        _textValue(exercise, "target_area");
  }

  String? _textValue(dynamic exercise, String key) {
    final value = _asMap(exercise)?[key]?.toString().trim();

    if (value == null || value.isEmpty || value == "null") {
      return null;
    }

    return value;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  bool _isCompletedValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase();
    return text == "completed" ||
        text == "complete" ||
        text == "true" ||
        text == "1";
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase();
    return text == "true" || text == "1" || text == "success";
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
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) / 2) - 8;
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF660F),
          Color(0xFFFF8D18),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.72,
      math.pi * 2 * value.clamp(0, 1).toDouble(),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
