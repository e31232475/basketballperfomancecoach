class WorkoutDay {
  const WorkoutDay({
    required this.id,
    required this.title,
    required this.dayNumber,
    required this.level,
    required this.difficulty,
    required this.estimatedDuration,
    required this.status,
    required this.completed,
    required this.locked,
    required this.exerciseCount,
    required this.progressPercentage,
    required this.totalSets,
    required this.loggedSets,
    required this.successfulSets,
    required this.failedSets,
  });

  final int id;
  final String title;
  final int dayNumber;
  final String level;
  final String difficulty;
  final int estimatedDuration;
  final String status;
  final bool completed;
  final bool locked;
  final int exerciseCount;
  final int progressPercentage;
  final int totalSets;
  final int loggedSets;
  final int successfulSets;
  final int failedSets;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      dayNumber: (json['day_number'] as num).toInt(),
      level: json['level']?.toString() ?? 'Beginner',
      difficulty:
          json['difficulty']?.toString() ??
          json['level']?.toString() ??
          'Beginner',
      estimatedDuration: (json['estimated_duration'] as num?)?.toInt() ?? 15,
      status: json['status']?.toString() ?? 'locked',
      completed: json['completed'] == true,
      locked: json['locked'] == true,
      exerciseCount: (json['exercise_count'] as num?)?.toInt() ?? 0,
      progressPercentage: (json['progress_percentage'] as num?)?.toInt() ?? 0,
      totalSets: (json['total_sets'] as num?)?.toInt() ?? 0,
      loggedSets: (json['logged_sets'] as num?)?.toInt() ?? 0,
      successfulSets: (json['successful_sets'] as num?)?.toInt() ?? 0,
      failedSets: (json['failed_sets'] as num?)?.toInt() ?? 0,
    );
  }
}

class ExerciseItem {
  const ExerciseItem({
    required this.id,
    required this.name,
    required this.type,
    required this.videoUrl,
    required this.sets,
    required this.reps,
    required this.duration,
    required this.restSeconds,
    required this.completed,
    required this.loggedSets,
  });

  final int id;
  final String name;
  final String type;
  final String? videoUrl;
  final int sets;
  final String reps;
  final int? duration;
  final int restSeconds;
  final bool completed;
  final int loggedSets;

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'training',
      videoUrl: json['video_url']?.toString(),
      sets: (json['sets'] as num?)?.toInt() ?? 1,
      reps: json['reps']?.toString() ?? '-',
      duration: (json['duration'] as num?)?.toInt(),
      restSeconds: (json['rest_seconds'] as num?)?.toInt() ?? 60,
      completed: json['completed'] == true,
      loggedSets: (json['logged_sets'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorkoutDetail {
  const WorkoutDetail({required this.workout, required this.exercises});

  final WorkoutDay workout;
  final List<ExerciseItem> exercises;

  factory WorkoutDetail.fromJson(Map<String, dynamic> json) {
    final workoutJson = json['workout'] as Map<String, dynamic>;
    final exerciseJson = json['exercises'] as List<dynamic>? ?? [];

    return WorkoutDetail(
      workout: WorkoutDay.fromJson({
        ...workoutJson,
        'status': workoutJson['status'] ?? 'unlocked',
        'completed': workoutJson['completed'] ?? false,
        'locked': workoutJson['locked'] ?? false,
      }),
      exercises: exerciseJson
          .map((item) => ExerciseItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WorkoutScore {
  const WorkoutScore({
    required this.successPercentage,
    required this.totalSuccessfulSets,
    required this.failedSets,
    required this.performanceScore,
    required this.workoutConsistency,
    required this.motivationalFeedback,
  });

  final int successPercentage;
  final int totalSuccessfulSets;
  final int failedSets;
  final int performanceScore;
  final int workoutConsistency;
  final String motivationalFeedback;

  factory WorkoutScore.fromJson(Map<String, dynamic> json) {
    return WorkoutScore(
      successPercentage: (json['success_percentage'] as num?)?.toInt() ?? 0,
      totalSuccessfulSets:
          (json['total_successful_sets'] as num?)?.toInt() ?? 0,
      failedSets: (json['failed_sets'] as num?)?.toInt() ?? 0,
      performanceScore: (json['performance_score'] as num?)?.toInt() ?? 0,
      workoutConsistency: (json['workout_consistency'] as num?)?.toInt() ?? 0,
      motivationalFeedback:
          json['motivational_feedback']?.toString() ?? 'Keep Improving',
    );
  }
}
