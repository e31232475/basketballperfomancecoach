import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/progress_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/glass_panel.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
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
      context.read<ProgressProvider>().load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ProgressProvider>();
    final summary = provider.summary;
    final verticalGain = (summary.workoutCompletionPercentage / 10).clamp(
      0.4,
      5.2,
    );

    return Scaffold(
      appBar: const BpcTopBar(compact: true),
      body: EliteBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            final userId = auth.user?.id;
            if (userId != null) {
              await context.read<ProgressProvider>().load(userId);
            }
          },
          child: provider.isLoading && summary.totalWorkouts == 0
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  children: [
                    const Text(
                      'ATHLETE\nPERFORMANCE',
                      style: TextStyle(
                        color: AppColors.lavender,
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'REAL-TIME BIOMETRICS & ANALYTICS',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        height: 1.45,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 34),
                    GlassPanel(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Vertical Jump',
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Last 30 Days Growth',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+${verticalGain.toStringAsFixed(1)}"',
                                    style: const TextStyle(
                                      color: AppColors.orange,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'MAX ${(32 + verticalGain).toStringAsFixed(1)}"',
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 170,
                            child: CustomPaint(
                              painter: _EliteLineChartPainter(summary.chart),
                              child: Container(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('WK 1', style: _AxisLabelStyle()),
                              Text('WK 2', style: _AxisLabelStyle()),
                              Text('WK 3', style: _AxisLabelStyle()),
                              Text('WK 4', style: _AxisLabelStyle()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassPanel(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SKILL DNA',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 250,
                            child: CustomPaint(
                              painter: _RadarPainter(summary),
                              child: Container(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(title: 'Weekly Consistency'),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 118,
                            child: CustomPaint(
                              painter: _WeeklyDotsPainter(summary.chart),
                              child: Container(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: SectionTitle(title: 'Achievements'),
                              ),
                              Text(
                                '${summary.completedWorkoutTotal} / ${summary.totalWorkouts} UNLOCKED',
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _Achievement(
                                icon: Icons.workspace_premium_outlined,
                                label: 'FAST BREAK',
                                active: summary.completedWorkoutTotal >= 1,
                                color: AppColors.orange,
                              ),
                              _Achievement(
                                icon: Icons.timer_outlined,
                                label: 'CLUTCH',
                                active: summary.currentStreak >= 2,
                                color: AppColors.lavender,
                              ),
                              _Achievement(
                                icon: Icons.bolt_rounded,
                                label: 'JUMP KING',
                                active: summary.successPercentage >= 70,
                                color: AppColors.cyan,
                              ),
                              _Achievement(
                                icon: Icons.lock_outline_rounded,
                                label: 'ELITE',
                                active: summary.completedWorkoutTotal >= 14,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(title: 'Performance Milestones'),
                          const SizedBox(height: 18),
                          _Milestone(
                            title: 'New PR: Squat Max',
                            subtitle:
                                'Reached ${summary.successfulSets} successful sets',
                            time: '2d ago',
                            icon: Icons.fitness_center_rounded,
                            color: AppColors.orange,
                          ),
                          const SizedBox(height: 12),
                          _Milestone(
                            title: 'Agility Drill Mastery',
                            subtitle: '${summary.performanceTrend} trend',
                            time: '5d ago',
                            icon: Icons.directions_run_rounded,
                            color: AppColors.lavender,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AxisLabelStyle extends TextStyle {
  const _AxisLabelStyle()
    : super(color: AppColors.text, fontSize: 10, fontWeight: FontWeight.w700);
}

class _EliteLineChartPainter extends CustomPainter {
  _EliteLineChartPainter(this.points);

  final List<ChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final values = _values();
    final path = Path();
    final fillPath = Path();
    final step = size.width / (values.length - 1);

    for (var index = 0; index < values.length; index++) {
      final x = index * step;
      final y = size.height - (values[index] * size.height * 0.72) - 28;
      if (index == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final previousX = (index - 1) * step;
        final previousY =
            size.height - (values[index - 1] * size.height * 0.72) - 28;
        path.cubicTo(
          previousX + step * 0.45,
          previousY,
          x - step * 0.45,
          y,
          x,
          y,
        );
        fillPath.cubicTo(
          previousX + step * 0.45,
          previousY,
          x - step * 0.45,
          y,
          x,
          y,
        );
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.orange.withValues(alpha: 0.42),
          AppColors.orange.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);
    final linePaint = Paint()
      ..color = AppColors.orange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  List<double> _values() {
    if (points.isEmpty) {
      return [0.18, 0.25, 0.38, 0.42, 0.5, 0.44, 0.78];
    }

    return points.map((point) {
      final value = point.successPercentage == 0
          ? point.sets * 12
          : point.successPercentage;
      return (value / 100).clamp(0.16, 0.92);
    }).toList();
  }

  @override
  bool shouldRepaint(covariant _EliteLineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.summary);

  final ProgressSummary summary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    final gridPaint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = AppColors.line.withValues(alpha: 0.68)
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.lavender
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var ring = 1; ring <= 3; ring++) {
      canvas.drawCircle(center, radius * ring / 3, gridPaint);
    }

    final values = [
      (summary.performanceScore / 100).clamp(0.28, 0.95),
      (summary.successfulSetsRatio).clamp(0.35, 0.95),
      (summary.weeklyConsistency / 100).clamp(0.30, 0.95),
      (summary.workoutCompletionPercentage / 100).clamp(0.35, 0.95),
    ];
    final labels = ['STRENGTH', 'AGILITY', 'STAMINA', 'SHOOTING'];
    final path = Path();

    for (var index = 0; index < 4; index++) {
      final angle = -math.pi / 2 + index * math.pi / 2;
      final axisEnd = Offset(
        center.dx + math.cos(angle) * radius * 1.18,
        center.dy + math.sin(angle) * radius * 1.18,
      );
      canvas.drawLine(center, axisEnd, axisPaint);

      final point = Offset(
        center.dx + math.cos(angle) * radius * values[index],
        center.dy + math.sin(angle) * radius * values[index],
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }

      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: const TextStyle(
            color: AppColors.lavender,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelOffset = Offset(
        center.dx + math.cos(angle) * radius * 1.36 - labelPainter.width / 2,
        center.dy + math.sin(angle) * radius * 1.36 - labelPainter.height / 2,
      );
      labelPainter.paint(canvas, labelOffset);
    }

    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.summary != summary;
  }
}

class _WeeklyDotsPainter extends CustomPainter {
  _WeeklyDotsPainter(this.points);

  final List<ChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final step = size.width / labels.length;
    final baseY = size.height - 28;

    for (var index = 0; index < labels.length; index++) {
      final point = index < points.length ? points[index] : null;
      final active =
          point != null && (point.sets > 0 || point.successPercentage > 0);
      final center = Offset(step * index + step / 2, active ? 38 : 58);
      final paint = Paint()
        ..color = active ? AppColors.orange : AppColors.panelSoft
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, active ? 9 : 6, paint);
      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: const TextStyle(color: AppColors.text, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(step * index + step / 2 - labelPainter.width / 2, baseY),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyDotsPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _Achievement extends StatelessWidget {
  const _Achievement({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: active
            ? AppColors.panelSoft
            : AppColors.panelSoft.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            active ? icon : Icons.lock_outline_rounded,
            color: color,
            size: 22,
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? AppColors.text : AppColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panelSoft.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
