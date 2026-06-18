class WorkoutDayModel {
  final int id;
  final String title;
  final int dayNumber;
  final String level;

  final bool completed;
  final bool locked;

  WorkoutDayModel({
    required this.id,
    required this.title,
    required this.dayNumber,
    required this.level,
    required this.completed,
    required this.locked,
  });

  factory WorkoutDayModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return WorkoutDayModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? "-",
      dayNumber: _toInt(json['day_number']),
      level: json['level']?.toString() ?? "-",
      completed: _toBool(json['completed']),
      locked: _toBool(json['locked']),
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
}
