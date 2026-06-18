class ChartPoint {
  const ChartPoint({
    required this.label,
    required this.sets,
    required this.successPercentage,
  });

  final String label;
  final int sets;
  final int successPercentage;

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      label: json['label']?.toString() ?? '',
      sets: (json['sets'] as num?)?.toInt() ?? 0,
      successPercentage: (json['success_percentage'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProgressSummary {
  const ProgressSummary({
    required this.workoutCompletionPercentage,
    required this.performanceTrend,
    required this.successfulSetsRatio,
    required this.failedSetsRatio,
    required this.weeklyConsistency,
    required this.completedWorkoutTotal,
    required this.currentStreak,
    required this.totalWorkouts,
    required this.totalSets,
    required this.successfulSets,
    required this.failedSets,
    required this.successPercentage,
    required this.performanceScore,
    required this.feedback,
    required this.chart,
  });

  final int workoutCompletionPercentage;
  final String performanceTrend;
  final double successfulSetsRatio;
  final double failedSetsRatio;
  final int weeklyConsistency;
  final int completedWorkoutTotal;
  final int currentStreak;
  final int totalWorkouts;
  final int totalSets;
  final int successfulSets;
  final int failedSets;
  final int successPercentage;
  final int performanceScore;
  final String feedback;
  final List<ChartPoint> chart;

  factory ProgressSummary.empty() {
    return const ProgressSummary(
      workoutCompletionPercentage: 0,
      performanceTrend: 'No data yet',
      successfulSetsRatio: 0,
      failedSetsRatio: 0,
      weeklyConsistency: 0,
      completedWorkoutTotal: 0,
      currentStreak: 0,
      totalWorkouts: 0,
      totalSets: 0,
      successfulSets: 0,
      failedSets: 0,
      successPercentage: 0,
      performanceScore: 0,
      feedback: 'Start logging your sets',
      chart: [],
    );
  }

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    final chartJson = json['chart'] as List<dynamic>? ?? [];

    return ProgressSummary(
      workoutCompletionPercentage:
          (json['workout_completion_percentage'] as num?)?.toInt() ?? 0,
      performanceTrend: json['performance_trend']?.toString() ?? 'No data yet',
      successfulSetsRatio:
          (json['successful_sets_ratio'] as num?)?.toDouble() ?? 0,
      failedSetsRatio: (json['failed_sets_ratio'] as num?)?.toDouble() ?? 0,
      weeklyConsistency: (json['weekly_consistency'] as num?)?.toInt() ?? 0,
      completedWorkoutTotal:
          (json['completed_workout_total'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      successfulSets: (json['successful_sets'] as num?)?.toInt() ?? 0,
      failedSets: (json['failed_sets'] as num?)?.toInt() ?? 0,
      successPercentage: (json['success_percentage'] as num?)?.toInt() ?? 0,
      performanceScore: (json['performance_score'] as num?)?.toInt() ?? 0,
      feedback: json['feedback']?.toString() ?? 'Keep Improving',
      chart: chartJson
          .map((item) => ChartPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
