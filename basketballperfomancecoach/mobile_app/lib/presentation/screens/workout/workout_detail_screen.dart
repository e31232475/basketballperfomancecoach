import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/glass_panel.dart';
import 'exercise_training_screen.dart';

class WorkoutDetailScreen extends StatefulWidget {
  const WorkoutDetailScreen({super.key, required this.dayNumber});

  final int dayNumber;

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      return;
    }
    await context.read<WorkoutProvider>().loadWorkoutDetail(
      userId: userId,
      dayNumber: widget.dayNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final detail = provider.selectedWorkout;
    final firstExercise = detail?.exercises.isNotEmpty == true
        ? detail!.exercises.first
        : null;

    return Scaffold(
      appBar: const BpcTopBar(showBack: true, compact: true),
      body: EliteBackground(
        child: provider.isLoading && detail == null
            ? const Center(child: CircularProgressIndicator())
            : detail == null
            ? EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Workout unavailable',
                message: provider.errorMessage ?? 'Try again later.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                children: [
                  _TechniquePreview(dayNumber: detail.workout.dayNumber),
                  const SizedBox(height: 34),
                  EliteBadge(
                    label: detail.workout.difficulty.toUpperCase(),
                    color: AppColors.cyan,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    firstExercise?.name ?? detail.workout.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontFamily: 'serif',
                      fontSize: 34,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    detail.workout.title,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _WorkoutMetaCard(
                          value: '${firstExercise?.sets ?? 0}',
                          label: 'SETS',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WorkoutMetaCard(
                          value: firstExercise?.reps ?? '-',
                          label: 'REPS',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WorkoutMetaCard(
                          value: '${firstExercise?.restSeconds ?? 0}s',
                          label: 'REST',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      const Expanded(
                        child: SectionTitle(title: 'Exercise Sets'),
                      ),
                      Text(
                        '${detail.exercises.where((item) => item.completed).length} / ${detail.exercises.length} COMPLETED',
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...detail.exercises.asMap().entries.map(
                    (entry) =>
                        _ExerciseRow(exercise: entry.value, index: entry.key),
                  ),
                  const SizedBox(height: 20),
                  GlassPanel(
                    borderColor: AppColors.lavenderSoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PERFORMANCE STATS',
                          style: TextStyle(
                            color: AppColors.lavender,
                            fontFamily: 'serif',
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _InfoLine(label: 'Target Intensity', value: '85%'),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: 0.85,
                          minHeight: 7,
                          color: AppColors.lavender,
                          backgroundColor: AppColors.panelSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 28),
                        const _InfoLine(
                          label: 'Vertical Velocity',
                          value: '2.4 m/s',
                          valueColor: AppColors.cyan,
                        ),
                        const SizedBox(height: 18),
                        const _InfoLine(
                          label: 'Peak Power',
                          value: '1,420 W',
                          valueColor: AppColors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    label: 'Start Exercise',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: detail.exercises.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExerciseTrainingScreen(detail: detail),
                              ),
                            );
                          },
                  ),
                ],
              ),
      ),
    );
  }
}

class _TechniquePreview extends StatelessWidget {
  const _TechniquePreview({required this.dayNumber});

  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      borderColor: AppColors.orange,
      child: Container(
        height: 190,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5A230E), Color(0xFF111018), Color(0xFF143449)],
          ),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(
                Icons.sports_basketball_rounded,
                color: AppColors.lavender,
                size: 82,
              ),
            ),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 12,
              child: EliteBadge(
                label: 'TECHNIQUE PREVIEW',
                color: AppColors.lavender,
                icon: Icons.movie_outlined,
              ),
            ),
            Positioned(
              right: 14,
              top: 12,
              child: Text(
                'DAY $dayNumber',
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutMetaCard extends StatelessWidget {
  const _WorkoutMetaCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.lavender,
              fontFamily: 'serif',
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontFamily: 'serif',
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.index});

  final ExerciseItem exercise;
  final int index;

  @override
  Widget build(BuildContext context) {
    final target = exercise.duration != null
        ? '${exercise.duration} sec'
        : '${exercise.reps} Reps';
    final active = !exercise.completed && index == 0;

    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderColor: exercise.completed
          ? AppColors.orange
          : active
          ? AppColors.cyan
          : null,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: exercise.completed
                  ? AppColors.orange
                  : active
                  ? AppColors.cyan.withValues(alpha: 0.14)
                  : AppColors.panelSoft,
              border: Border.all(
                color: active ? AppColors.cyan : AppColors.line,
              ),
            ),
            child: Center(
              child: exercise.completed
                  ? const Icon(Icons.check_rounded, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active ? AppColors.cyan : AppColors.muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set ${(index + 1).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: active ? AppColors.cyan : AppColors.text,
                    fontSize: 18,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$target - ${exercise.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            exercise.reps,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.text, fontFamily: 'serif'),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: 'serif',
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
