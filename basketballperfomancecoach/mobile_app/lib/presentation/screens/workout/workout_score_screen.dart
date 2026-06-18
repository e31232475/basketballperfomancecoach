import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_models.dart';
import '../../widgets/app_button.dart';
import '../../widgets/glass_panel.dart';

class WorkoutScoreScreen extends StatelessWidget {
  const WorkoutScoreScreen({super.key, required this.score});

  final WorkoutScore score;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BpcTopBar(showBack: true, compact: true),
      body: EliteBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassPanel(
                child: Column(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      color: AppColors.orange,
                      size: 58,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${score.performanceScore}',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const Text(
                      'Performance Score',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      score.motivationalFeedback,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  MetricTile(
                    label: 'Success',
                    value: '${score.successPercentage}%',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.green,
                  ),
                  MetricTile(
                    label: 'Consistency',
                    value: '${score.workoutConsistency}%',
                    icon: Icons.repeat_rounded,
                    color: AppColors.cyan,
                  ),
                  MetricTile(
                    label: 'Successful sets',
                    value: '${score.totalSuccessfulSets}',
                    icon: Icons.add_task_rounded,
                    color: AppColors.green,
                  ),
                  MetricTile(
                    label: 'Failed sets',
                    value: '${score.failedSets}',
                    icon: Icons.close_rounded,
                    color: AppColors.red,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Back To Workout List',
                icon: Icons.list_alt_rounded,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
