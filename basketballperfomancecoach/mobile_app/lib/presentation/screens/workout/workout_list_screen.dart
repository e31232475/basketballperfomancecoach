import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/glass_panel.dart';
import 'workout_detail_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      context.read<WorkoutProvider>().loadWorkoutList(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<WorkoutProvider>();
    final workouts = provider.workouts;
    final completed = workouts.where((workout) => workout.completed).length;
    final current = workouts.cast<WorkoutDay?>().firstWhere(
      (workout) => workout != null && !workout.completed && !workout.locked,
      orElse: () => null,
    );

    return Scaffold(
      appBar: const BpcTopBar(compact: true),
      body: EliteBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            final userId = auth.user?.id;
            if (userId != null) {
              await context.read<WorkoutProvider>().loadWorkoutList(userId);
            }
          },
          child: provider.isLoading && workouts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : workouts.isEmpty
              ? const EmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: 'No workouts',
                  message: 'Seed the backend workout program first.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
                  children: [
                    const Text(
                      '14-Day Plyometric\nProgram',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 30,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PERFORMANCE LAB     .     EXPLOSIVE POWER',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        height: 1.5,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 70),
                    Row(
                      children: [
                        Expanded(
                          child: GlassPanel(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                const Text(
                                  'OVERALL\nPROGRESS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.cyan,
                                    fontSize: 16,
                                    height: 1.25,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '$completed/${workouts.length}',
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                LinearProgressIndicator(
                                  value: workouts.isEmpty
                                      ? 0
                                      : completed / workouts.length,
                                  minHeight: 5,
                                  color: AppColors.cyan,
                                  backgroundColor: AppColors.line,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GlassPanel(
                            borderColor: AppColors.orange,
                            glowColor: AppColors.orange,
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                const Text(
                                  'NEXT UP',
                                  style: TextStyle(
                                    color: AppColors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  current == null
                                      ? 'Done'
                                      : 'Day ${current.dayNumber}',
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  current?.title ?? 'Program complete',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 42),
                    ...workouts.map(
                      (workout) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WorkoutCard(
                          workout: workout,
                          isCurrent: current?.id == workout.id,
                          onPreview: () => _open(workout),
                          onStart: workout.locked ? null : () => _open(workout),
                          onLocked: () => _lockedDialog(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Center(
                      child: Text(
                        'DAYS 8-14 LOCKED',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _open(WorkoutDay workout) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(dayNumber: workout.dayNumber),
      ),
    );
  }

  void _lockedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Locked Workout'),
        content: const Text('Complete previous workout first'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.workout,
    required this.isCurrent,
    required this.onPreview,
    required this.onStart,
    required this.onLocked,
  });

  final WorkoutDay workout;
  final bool isCurrent;
  final VoidCallback onPreview;
  final VoidCallback? onStart;
  final VoidCallback onLocked;

  @override
  Widget build(BuildContext context) {
    final completed = workout.completed;
    final locked = workout.locked;
    final color = completed
        ? AppColors.cyan
        : isCurrent
        ? AppColors.orange
        : locked
        ? AppColors.muted
        : AppColors.lavender;

    return Opacity(
      opacity: locked ? 0.52 : 1,
      child: InkWell(
        onTap: locked ? onLocked : onPreview,
        borderRadius: BorderRadius.circular(8),
        child: GlassPanel(
          borderColor: isCurrent ? AppColors.orange : null,
          glowColor: isCurrent ? AppColors.orange : null,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.18),
                  border: Border.all(color: color),
                ),
                child: Icon(
                  completed
                      ? Icons.check_circle_outline_rounded
                      : locked
                      ? Icons.lock_outline_rounded
                      : Icons.play_arrow_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Day ${workout.dayNumber}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: locked ? AppColors.muted : AppColors.text,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          const EliteBadge(
                            label: 'CURRENT',
                            color: AppColors.orange,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        EliteBadge(
                          label: workout.difficulty,
                          color: isCurrent ? AppColors.orange : AppColors.line,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: AppColors.text,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${workout.estimatedDuration} mins',
                              style: const TextStyle(color: AppColors.text),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    tooltip: 'Start Workout',
                    onPressed: onStart,
                    icon: const Icon(Icons.fitness_center_rounded),
                    color: Colors.black,
                  ),
                )
              else
                Icon(
                  locked
                      ? Icons.lock_outline_rounded
                      : Icons.chevron_right_rounded,
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
