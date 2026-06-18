import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/workout_provider.dart';
import '../../widgets/glass_panel.dart';
import '../workout/workout_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      context.read<ProgressProvider>().load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final workouts = context.watch<WorkoutProvider>().workouts;
    final progress = context.watch<ProgressProvider>().summary;
    final todayWorkout = _todayWorkout(workouts);
    final verticalJump = 28 + (progress.workoutCompletionPercentage * 0.13);

    return Scaffold(
      appBar: const BpcTopBar(compact: true),
      body: EliteBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            final userId = context.read<AuthProvider>().user?.id;
            if (userId == null) {
              return;
            }
            await Future.wait([
              context.read<WorkoutProvider>().loadWorkoutList(userId),
              context.read<ProgressProvider>().load(userId),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
            children: [
              Text(
                'Hello, ${user?.name.isNotEmpty == true ? user!.name : 'Athlete'}!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your training peak is scheduled for 5:00 PM today.',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              GlassPanel(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'VERTICAL JUMP',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.monitor_heart_outlined,
                          color: AppColors.line,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: verticalJump.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.lavender,
                              fontFamily: 'serif',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const TextSpan(
                            text: ' INCHES',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '+1.2 this week',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HomeStatCard(
                      label: 'STREAK',
                      value: '${progress.currentStreak}\nDAYS',
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.orange,
                      highlighted: true,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _HomeStatCard(
                      label: 'SETS',
                      value: '${progress.totalSets}',
                      icon: Icons.bolt_rounded,
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GlassPanel(
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRAINING LOAD',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Optimum',
                            style: TextStyle(
                              color: AppColors.lavender,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox.square(
                      dimension: 58,
                      child: CircularProgressIndicator(
                        value: (progress.performanceScore / 100).clamp(0, 1),
                        strokeWidth: 7,
                        backgroundColor: AppColors.panelSoft,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: 'Weekly Progress'),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 150,
                      child: CustomPaint(
                        painter: _WeeklyBarsPainter(progress.chart),
                        child: Container(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SectionTitle(
                title: 'Quick Training',
                trailing: Icon(Icons.bolt_rounded, color: AppColors.lavender),
              ),
              const SizedBox(height: 12),
              _QuickTrainingTile(
                title: todayWorkout == null
                    ? 'Program Complete'
                    : 'Start Workout',
                subtitle: todayWorkout == null
                    ? '14-day block finished'
                    : 'Day ${todayWorkout.dayNumber}: ${todayWorkout.title}',
                icon: Icons.fitness_center_rounded,
                color: AppColors.orange,
                onTap: todayWorkout == null
                    ? null
                    : () => _openWorkout(todayWorkout),
              ),
              const SizedBox(height: 12),
              _QuickTrainingTile(
                title: 'Jump Training',
                subtitle: 'Focus: Explosiveness',
                icon: Icons.vertical_align_top_rounded,
                color: AppColors.lavenderSoft,
                onTap: todayWorkout == null
                    ? null
                    : () => _openWorkout(todayWorkout),
              ),
              const SizedBox(height: 12),
              _QuickTrainingTile(
                title: 'Shooting Drill',
                subtitle: 'Focus: Form and arc',
                icon: Icons.sports_basketball_rounded,
                color: AppColors.cyan,
                onTap: todayWorkout == null
                    ? null
                    : () => _openWorkout(todayWorkout),
              ),
              const SizedBox(height: 28),
              const _CoachingTipCard(),
            ],
          ),
        ),
      ),
    );
  }

  WorkoutDay? _todayWorkout(List<WorkoutDay> workouts) {
    for (final workout in workouts) {
      if (!workout.completed && !workout.locked) {
        return workout;
      }
    }
    return null;
  }

  void _openWorkout(WorkoutDay workout) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(dayNumber: workout.dayNumber),
      ),
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderColor: highlighted ? AppColors.orange : null,
      glowColor: highlighted ? AppColors.orange : null,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTrainingTile extends StatelessWidget {
  const _QuickTrainingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: GlassPanel(
        borderColor: color == AppColors.orange ? AppColors.orange : null,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.text),
          ],
        ),
      ),
    );
  }
}

class _CoachingTipCard extends StatelessWidget {
  const _CoachingTipCard();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7A2B12),
                  Color(0xFF111018),
                  Color(0xFF193145),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.sports_basketball_rounded,
                color: AppColors.orange,
                size: 64,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                EliteBadge(label: 'COACHING TIP', color: AppColors.cyan),
                SizedBox(height: 14),
                Text(
                  'Mastering the Triple Threat Positioning',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Learn how to explode from triple threat position, beat any defender, and create clean separation.',
                  style: TextStyle(color: AppColors.text, height: 1.35),
                ),
                SizedBox(height: 16),
                Text(
                  'WATCH DRILL',
                  style: TextStyle(
                    color: AppColors.lavender,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarsPainter extends CustomPainter {
  _WeeklyBarsPainter(this.points);

  final List<dynamic> points;

  @override
  void paint(Canvas canvas, Size size) {
    final labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final barPaint = Paint()..color = AppColors.lavenderSoft;
    final activePaint = Paint()..color = AppColors.orange;
    const gap = 12.0;
    final barWidth = (size.width - gap * (labels.length - 1)) / labels.length;
    final values = List<double>.generate(labels.length, (index) {
      if (index < points.length) {
        final point = points[index];
        final value = point.successPercentage as int? ?? 0;
        return value == 0
            ? (0.25 + index * 0.05).clamp(0.18, 0.8)
            : value / 100;
      }
      return 0.25 + index * 0.06;
    });

    for (var index = 0; index < labels.length; index++) {
      final left = index * (barWidth + gap);
      final height = (size.height - 28) * values[index].clamp(0.18, 1);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, size.height - 28 - height, barWidth, height),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, index == 2 ? activePaint : barPaint);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: barWidth + gap);
      labelPainter.paint(
        canvas,
        Offset(left + (barWidth - labelPainter.width) / 2, size.height - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarsPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
