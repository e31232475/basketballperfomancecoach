class WorkoutDayModel {
  final int id;
  final String title;
  final int dayNumber;
  final String level;
  final bool completed;
  final bool locked;
  final DateTime? completedAt;
  final int exerciseCount;
  final int estimatedDuration;
  final int progressPercentage;

  WorkoutDayModel({
    required this.id,
    required this.title,
    required this.dayNumber,
    required this.level,
    required this.completed,
    required this.locked,
    this.completedAt,
    required this.exerciseCount,
    required this.estimatedDuration,
    required this.progressPercentage,
  });

  WorkoutDayModel copyWith({
    int? id,
    String? title,
    int? dayNumber,
    String? level,
    bool? completed,
    bool? locked,
    DateTime? completedAt,
    int? exerciseCount,
    int? estimatedDuration,
    int? progressPercentage,
  }) {
    return WorkoutDayModel(
      id: id ?? this.id,
      title: title ?? this.title,
      dayNumber: dayNumber ?? this.dayNumber,
      level: level ?? this.level,
      completed: completed ?? this.completed,
      locked: locked ?? this.locked,
      completedAt: completedAt ?? this.completedAt,
      exerciseCount: exerciseCount ?? this.exerciseCount,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }

  factory WorkoutDayModel.fromJson(Map<String, dynamic> json) {
    return WorkoutDayModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? "-",
      dayNumber: _toInt(json['day_number']),
      level: json['level']?.toString() ?? "-",
      completed: _toBool(json['completed']),
      locked: _toBool(json['locked']),
      completedAt: _toDateTime(
        json['completed_at'] ??
            json['completedAt'] ??
            json['completion_time'] ??
            json['finished_at'] ??
            json['finishedAt'],
      ),
      exerciseCount: _toInt(json['exercise_count']),
      estimatedDuration: _toInt(json['estimated_duration']),
      progressPercentage: _toInt(json['progress_percentage']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase();
    return text == "true" || text == "1" || text == "completed";
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is num) {
      final milliseconds =
          value > 1000000000000 ? value.toInt() : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }

    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text)?.toLocal();
  }
}
