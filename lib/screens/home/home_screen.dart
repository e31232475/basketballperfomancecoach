import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/workout_day_model.dart';
import '../../services/auth_service.dart';
import '../../services/workout_service.dart';
import '../workout/workout_day_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<WorkoutDayModel> workouts = [];
  String? recommendedLevel;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final data = await WorkoutService.getWorkoutList();
    final level = await AuthService.cachedTrainingLevel();

    if (!mounted) {
      return;
    }

    setState(() {
      workouts = data;
      recommendedLevel = _normalizeLevel(level);
      isLoading = false;
    });
  }

  List<WorkoutDayModel> get _focusWorkouts {
    final recommended = workouts
        .where((workout) => _normalizeLevel(workout.level) == recommendedLevel)
        .toList();

    if (recommended.isNotEmpty) {
      return recommended.take(2).toList();
    }

    final unlocked = workouts.where((workout) => !workout.locked).toList();

    if (unlocked.isEmpty) {
      return workouts.take(2).toList();
    }

    return unlocked.take(2).toList();
  }

  List<WorkoutDayModel> get _previewWorkouts {
    if (recommendedLevel == null) {
      return [];
    }

    return workouts
        .where((workout) => _normalizeLevel(workout.level) != recommendedLevel)
        .take(3)
        .toList();
  }

  List<WorkoutDayModel> get _recentUnfinishedWorkouts {
    final sameLevel = workouts
        .where((workout) => _normalizeLevel(workout.level) == recommendedLevel)
        .where((workout) => !workout.completed)
        .toList()
      ..sort((a, b) {
        if (a.locked != b.locked) {
          return a.locked ? 1 : -1;
        }

        return a.dayNumber.compareTo(b.dayNumber);
      });

    if (sameLevel.isNotEmpty) {
      return sameLevel.take(3).toList();
    }

    final unfinished = workouts.where((workout) => !workout.completed).toList()
      ..sort((a, b) {
        if (a.locked != b.locked) {
          return a.locked ? 1 : -1;
        }

        return a.dayNumber.compareTo(b.dayNumber);
      });

    return unfinished.take(3).toList();
  }

  Future<void> _openWorkout(WorkoutDayModel workout) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDayDetailScreen(dayNumber: workout.dayNumber),
      ),
    );

    if (!mounted || completed != true) {
      return;
    }

    await _loadWorkouts();
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
          "BPC ELITE",
          style: TextStyle(
            color: AppColors.lavender,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(),
            const SizedBox(height: 28),
            _buildSectionTitle(
              recommendedLevel == null
                  ? "Today's Focus"
                  : "$recommendedLevel Recommendation",
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
            else if (_focusWorkouts.isEmpty)
              _buildEmptyWorkout()
            else
              ..._focusWorkouts.map((workout) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkoutCard(
                    workout: workout,
                    active: !workout.completed && !workout.locked,
                    preview: false,
                    onTap: () => _openWorkout(workout),
                  ),
                );
              }),
            if (!isLoading && _previewWorkouts.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildSectionTitle("Other Level Preview"),
              const SizedBox(height: 14),
              ..._previewWorkouts.map((workout) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWorkoutCard(
                    workout: workout,
                    active: false,
                    preview: true,
                    onTap: () => _openWorkout(workout),
                  ),
                );
              }),
            ],
            const SizedBox(height: 28),
            _buildSectionTitle("Recent Workout"),
            const SizedBox(height: 14),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_recentUnfinishedWorkouts.isEmpty)
              _buildAllDoneWorkout()
            else
              ..._recentUnfinishedWorkouts.map((workout) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecentWorkoutCard(workout),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final completed = workouts.where((workout) => workout.completed).length;
    final total = workouts.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 144,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2B1710),
                  Color(0xFF17171E),
                  Color(0xFF102529),
                ],
              ),
              border: Border.all(color: Colors.white10),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CourtLinePainter(),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.sports_basketball,
                    color: AppColors.primary,
                    size: 72,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.7),
              ),
            ),
            child: const Text(
              "ATHLETE DASHBOARD",
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Basketball Performance Coaching",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.04,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  title: "DONE",
                  value: total == 0 ? "-" : "$completed/$total",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  title: "PROGRAMS",
                  value: total.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }

  Widget _buildEmptyWorkout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: Colors.white12),
      ),
      child: const Text(
        "Workout belum tersedia dari backend.",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildAllDoneWorkout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Semua workout di level ini sudah selesai.",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkoutCard(WorkoutDayModel workout) {
    final progress = workout.progressPercentage.clamp(0, 100);
    final access = WorkoutService.workoutAccessFor(workout, workouts);
    final canStart = access.canStart;
    final accent = workout.completed
        ? AppColors.secondary
        : canStart
            ? AppColors.primary
            : Colors.white38;
    final status = workout.completed ? "DONE" : access.statusLabel;

    return InkWell(
      onTap: () => _openWorkout(workout),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.75)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress / 100,
                    strokeWidth: 5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                  Icon(
                    !canStart && !workout.completed
                        ? Icons.lock_outline
                        : workout.completed
                            ? Icons.check_circle_outline
                            : Icons.play_arrow_rounded,
                    color: accent,
                    size: 30,
                  ),
                ],
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
                  const SizedBox(height: 6),
                  Text(
                    "${workout.exerciseCount} exercises - ${workout.level}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$progress%",
                  style: TextStyle(
                    color: accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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

  Widget _buildWorkoutCard({
    required WorkoutDayModel workout,
    required bool active,
    required bool preview,
    required VoidCallback onTap,
  }) {
    final access = WorkoutService.workoutAccessFor(workout, workouts);
    final startLocked = !access.canStart && !workout.completed;
    final accent = startLocked
        ? Colors.white38
        : preview
            ? AppColors.lavender
            : active
                ? AppColors.primary
                : AppColors.secondary;
    final subtitle =
        "${workout.exerciseCount} exercises - Day ${workout.dayNumber} - ${workout.level}";
    final duration = workout.estimatedDuration > 0
        ? "${workout.estimatedDuration} MIN"
        : "${workout.progressPercentage}%";
    final trailing = startLocked
        ? access.statusLabel
        : preview
            ? "PREVIEW"
            : duration;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(
            color: active ? AppColors.primary : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: accent),
              ),
              child: Icon(
                startLocked
                    ? Icons.visibility_outlined
                    : preview
                        ? Icons.visibility_outlined
                        : active
                            ? Icons.play_arrow
                            : Icons.fitness_center,
                color: accent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                trailing,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.lavender,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orangePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final cyanPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, size.height * 0.24),
      Offset(size.width * 0.36, size.height * 0.24),
      orangePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.24),
      Offset(size.width, size.height * 0.24),
      cyanPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.72),
        width: size.width * 0.52,
        height: size.height * 0.54,
      ),
      3.14,
      3.14,
      false,
      orangePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
