import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/workout_day_model.dart';
import '../../services/auth_service.dart';
import '../../services/workout_service.dart';
import 'workout_day_detail_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  List<WorkoutDayModel> workouts = [];
  String? recommendedLevel;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWorkoutList();
  }

  Future<void> loadWorkoutList({
    bool showLoading = false,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        isLoading = true;
      });
    }

    final data = await WorkoutService.getWorkoutList();
    var level = await AuthService.cachedTrainingLevel();

    if (level == null || level.isEmpty) {
      final userResponse = await AuthService.getUser();
      final userData = userResponse["data"];

      if (userData is Map) {
        level = userData["training_level"]?.toString();
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      workouts = data;
      recommendedLevel = _normalizeLevel(level);
      isLoading = false;
    });
  }

  bool isWorkoutLocked(int index) {
    final workout = _visibleWorkouts[index];
    final access = WorkoutService.workoutAccessFor(workout, _visibleWorkouts);

    return !workout.completed && !access.canStart;
  }

  Future<void> openWorkout(WorkoutDayModel workout) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDayDetailScreen(
          dayNumber: workout.dayNumber,
        ),
      ),
    );

    await loadWorkoutList(showLoading: true);

    if (!mounted || completed != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Workout selesai. Day berikutnya bisa dimulai setelah 12 jam.",
        ),
      ),
    );
  }

  bool _matchesUserLevel(WorkoutDayModel workout) {
    if (recommendedLevel == null || recommendedLevel!.isEmpty) {
      return true;
    }

    return _normalizeLevel(workout.level) == recommendedLevel;
  }

  List<WorkoutDayModel> get _visibleWorkouts {
    if (recommendedLevel == null || recommendedLevel!.isEmpty) {
      return workouts;
    }

    return workouts.where(_matchesUserLevel).toList();
  }

  String? _normalizeLevel(String? value) {
    final text = value?.trim().toLowerCase();

    if (text == null || text.isEmpty || text == "-") {
      return null;
    }

    if (text == "intermediate" || text == "intermeditate") {
      return "Intermediate";
    }

    if (text == "beginner" || text == "begiener" || text == "beginer") {
      return "Beginner";
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "WORKOUT PROGRAM",
          style: TextStyle(
            color: AppColors.lavender,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadWorkoutList,
              color: AppColors.primary,
              child: _visibleWorkouts.isEmpty
                  ? const Center(
                      child: Text(
                        "No workouts available",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                      itemCount: _visibleWorkouts.length,
                      itemBuilder: (context, index) {
                        final workout = _visibleWorkouts[index];
                        final access = WorkoutService.workoutAccessFor(
                          workout,
                          _visibleWorkouts,
                        );
                        final locked = isWorkoutLocked(index);
                        final completed = workout.completed;

                        return _WorkoutDayTile(
                          workout: workout,
                          locked: locked,
                          completed: completed,
                          statusLabel: completed ? "DONE" : access.statusLabel,
                          onTap: () => openWorkout(workout),
                        );
                      },
                    ),
            ),
    );
  }
}

class _WorkoutDayTile extends StatelessWidget {
  const _WorkoutDayTile({
    required this.workout,
    required this.locked,
    required this.completed,
    required this.statusLabel,
    required this.onTap,
  });

  final WorkoutDayModel workout;
  final bool locked;
  final bool completed;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = completed
        ? AppColors.secondary
        : locked
            ? Colors.white38
            : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: locked ? 0.74 : 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: accent.withValues(alpha: 0.8)),
              boxShadow: [
                if (!locked)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.13),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
              ],
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
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.14),
                              border: Border.all(color: accent, width: 2),
                            ),
                            child: Icon(
                              completed
                                  ? Icons.check
                                  : locked
                                      ? Icons.visibility_outlined
                                      : Icons.play_arrow,
                              color: accent,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Day ${workout.dayNumber}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _Tag(
                                      label: "DAY ${workout.dayNumber}",
                                      color: AppColors.lavender,
                                    ),
                                    _Tag(
                                      label: workout.level.toUpperCase(),
                                      color: AppColors.secondary,
                                    ),
                                    _Tag(
                                      label:
                                          "${workout.exerciseCount} EXERCISES",
                                      color: Colors.white70,
                                    ),
                                    if (workout.estimatedDuration > 0)
                                      _Tag(
                                        label:
                                            "${workout.estimatedDuration} MIN",
                                        color: AppColors.lavender,
                                      ),
                                    _Tag(
                                      label: completed ? "DONE" : statusLabel,
                                      color: accent,
                                    ),
                                    _Tag(
                                      label: "YOUR LEVEL",
                                      color: AppColors.success,
                                    ),
                                  ],
                                ),
                                if (workout.progressPercentage > 0) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: workout.progressPercentage
                                              .clamp(0, 100) /
                                          100,
                                      minHeight: 5,
                                      backgroundColor: Colors.white10,
                                      valueColor:
                                          AlwaysStoppedAnimation(accent),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            locked
                                ? Icons.visibility_outlined
                                : completed
                                    ? Icons.check_circle_outline
                                    : Icons.arrow_forward_ios,
                            color: accent,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
