import '../models/workout_day_model.dart';

class BeginnerWorkoutCatalog {
  static const int restSeconds = 30;

  static const Map<int, List<Map<String, dynamic>>> _exercisesByDay = {
    1: [
      {'name': 'Sprint 15 Meter', 'reps': '15 meter', 'sets': 4},
      {'name': 'Lateral Hurdle Jump', 'reps': '10', 'sets': 3},
      {'name': 'Single Leg Butt Kicks', 'reps': '6', 'sets': 3},
      {'name': 'Tuck Jump', 'reps': '8', 'sets': 3},
      {'name': 'Squat Jump', 'reps': '8', 'sets': 3},
    ],
    2: [
      {'name': 'Foot Fires', 'reps': '20 sec', 'duration': 20, 'sets': 4},
      {'name': 'Split Jump', 'reps': '12', 'sets': 4},
      {'name': 'Tuck Jump', 'reps': '8', 'sets': 3},
      {'name': 'Broad Jump', 'reps': '6', 'sets': 3},
      {'name': 'Alternating Foot Taps', 'reps': '20', 'sets': 3},
    ],
    3: [
      {'name': 'Sprint 15 Meter', 'reps': '15 meter', 'sets': 4},
      {'name': 'Kneeling Jump', 'reps': '6', 'sets': 3},
      {'name': 'Broad Jump', 'reps': '6', 'sets': 3},
      {'name': 'Lateral Bounds', 'reps': '6', 'sets': 3},
      {'name': 'Foot Fire', 'reps': '20 sec', 'duration': 20, 'sets': 4},
    ],
    4: [
      {'name': 'Sprint 15 Meter', 'reps': '15 meter', 'sets': 4},
      {'name': 'Kneeling Jump', 'reps': '6', 'sets': 3},
      {'name': 'Broad Jump', 'reps': '6', 'sets': 3},
      {'name': 'Lateral Bounds', 'reps': '6', 'sets': 3},
      {'name': 'Foot Fire', 'reps': '20 sec', 'duration': 20, 'sets': 4},
    ],
    5: [
      {'name': 'Lateral Hurdle Jump', 'reps': '10', 'sets': 4},
      {'name': 'Kneeling Tuck Jump', 'reps': '6', 'sets': 3},
      {'name': 'Broad Jump', 'reps': '6', 'sets': 3},
      {'name': '180 Degree Jump', 'reps': '8', 'sets': 3},
      {'name': 'Split Jump', 'reps': '12', 'sets': 3},
    ],
    6: [
      {
        'name': 'Superset: 20 High Knee and 10 Lateral Hurdle',
        'reps': '20 high knee + 10 lateral hurdle',
        'sets': 4,
      },
      {
        'name': 'Superset: 6 Kneeling Jumps and 6 Single Leg Butt Kicks',
        'reps': '6 kneeling jumps + 6 single leg butt kicks',
        'sets': 4,
      },
      {
        'name': 'Broad Jump to Vertical Jump',
        'reps': '6',
        'sets': 4,
      },
      {
        'name': 'Superset: 12 Split Jump and 20 Alternating Footsteps',
        'reps': '12 split jump + 20 alternating footsteps',
        'sets': 4,
      },
    ],
    7: [
      {
        'name': 'Superset: 20 High Knee and 10 Lateral Hurdle',
        'reps': '20 high knee + 10 lateral hurdle',
        'sets': 4,
      },
      {
        'name': 'Superset: 6 Kneeling Jumps and 6 Single Leg Butt Kicks',
        'reps': '6 kneeling jumps + 6 single leg butt kicks',
        'sets': 4,
      },
      {
        'name': 'Broad Jump to Vertical Jump',
        'reps': '6',
        'sets': 4,
      },
      {
        'name': 'Superset: 12 Split Jump and 20 Alternating Footsteps',
        'reps': '12 split jump + 20 alternating footsteps',
        'sets': 4,
      },
    ],
    8: [
      {'name': 'Sprint 15 Meter', 'reps': '15 meter', 'sets': 4},
      {
        'name': 'Superset: 180 Degree Jump and Lateral Bounds',
        'reps': '8 jumps + 12 lateral bounds (6 each side)',
        'sets': 4,
      },
      {'name': 'Kneeling Tuck Jump', 'reps': '6', 'sets': 4},
      {
        'name': 'Broad Jump and Alternated Foot Taps',
        'reps': '6 broad jumps + 20 alternated foot taps',
        'sets': 4,
      },
      {'name': 'Foot Fire', 'reps': '20 sec', 'duration': 20, 'sets': 4},
    ],
    9: [
      {
        'name': 'Alternating Foot Taps and Squat Jumps',
        'reps': '20 foot taps + 10 squat jumps',
        'sets': 4,
      },
      {'name': 'Lateral Bound to Broad Jump', 'reps': '6', 'sets': 4},
      {'name': 'Hurdle to Tuck Jump', 'reps': '6', 'sets': 4},
      {'name': 'Single Leg Butt Kick', 'reps': '6', 'sets': 4},
      {
        'name': 'Lateral Hurdles and Foot Fire',
        'reps': '10 lateral hurdles + 20 sec foot fire',
        'sets': 4,
      },
    ],
    10: [
      {
        'name': 'Alternating Foot Taps and Squat Jumps',
        'reps': '20 foot taps + 10 squat jumps',
        'sets': 4,
      },
      {'name': 'Lateral Bound to Broad Jump', 'reps': '6', 'sets': 4},
      {'name': 'Hurdle to Tuck Jump', 'reps': '6', 'sets': 4},
      {'name': 'Single Leg Butt Kick', 'reps': '6', 'sets': 4},
      {
        'name': 'Lateral Hurdles and Foot Fire',
        'reps': '10 lateral hurdles + 20 sec foot fire',
        'sets': 4,
      },
    ],
    11: [
      {'name': 'Sprint 15 Meter', 'reps': '15 meter', 'sets': 4},
      {'name': 'Split Jump', 'reps': '12', 'sets': 4},
      {
        'name': 'Lateral Bound to Tuck Jump to Broad Jump',
        'reps': '6',
        'sets': 4,
      },
      {'name': 'Kneeling Tuck Jump', 'reps': '6', 'sets': 4},
      {
        'name': 'Superset: Lateral Hurdles and Foot Fires',
        'reps': '10 lateral hurdles + 20 sec foot fires',
        'sets': 4,
      },
    ],
    12: [
      {
        'name': 'Alternating Foot Taps and Squat Jump',
        'reps': '20 foot taps + 10 squat jump',
        'sets': 4,
      },
      {'name': 'Broad Jump to Tuck Jump', 'reps': '6', 'sets': 4},
      {'name': 'Kneeling Tuck Jump to Broad Jump', 'reps': '6', 'sets': 4},
      {'name': 'Lateral Bound', 'reps': '6', 'sets': 4},
      {
        'name': 'Kneeling Jump to Foot Fires',
        'reps': '6 kneeling jump + 20 foot fires',
        'sets': 4,
      },
    ],
    13: [
      {
        'name': 'Alternating Foot Taps and Squat Jump',
        'reps': '20 foot taps + 10 squat jump',
        'sets': 4,
      },
      {'name': 'Broad Jump to Tuck Jump', 'reps': '6', 'sets': 4},
      {'name': 'Kneeling Tuck Jump to Broad Jump', 'reps': '6', 'sets': 4},
      {'name': 'Lateral Bound', 'reps': '6', 'sets': 4},
      {
        'name': 'Kneeling Jump to Foot Fires',
        'reps': '6 kneeling jump + 20 foot fires',
        'sets': 4,
      },
    ],
    14: [
      {'name': '15 Meter Sprint', 'reps': '15 meter', 'sets': 4},
      {
        'name': 'Kneeling Broad Jump into Tuck Jump',
        'reps': '6',
        'sets': 4,
      },
      {
        'name': 'Split Jump and Vertical Jump',
        'reps': '12 split jump + 6 vertical jump',
        'sets': 4,
      },
      {
        'name': 'Lateral Hurdle into Single Leg Broad Jump',
        'reps': '6',
        'sets': 4,
      },
      {
        'name': '180 Degree Jump and Alternating Foot Taps',
        'reps': '8 jumps + 20 alternating foot taps',
        'sets': 4,
      },
    ],
  };

  static bool hasBeginnerDay(int dayNumber) {
    return dayNumber >= 1 && dayNumber <= 14;
  }

  static bool hasExerciseOverride(int dayNumber) {
    return _exercisesByDay.containsKey(dayNumber);
  }

  static String titleForDay(int dayNumber) {
    return 'Day $dayNumber';
  }

  static int? exerciseCountForDay(int dayNumber) {
    return _exercisesByDay[dayNumber]?.length;
  }

  static int estimatedDurationForDay(int dayNumber) {
    final exercises = _exercisesByDay[dayNumber];

    if (exercises == null || exercises.isEmpty) {
      return 0;
    }

    var seconds = 0;

    for (final exercise in exercises) {
      final sets = _toInt(exercise['sets']) ?? 1;
      final duration = _toInt(exercise['duration']) ?? 40;
      final restCount = sets > 1 ? sets - 1 : 0;
      seconds += (sets * duration) + (restCount * restSeconds);
    }

    return (seconds / 60).ceil();
  }

  static WorkoutDayModel normalizeWorkoutSummary(WorkoutDayModel workout) {
    if (!_isBeginner(workout.level) || !hasBeginnerDay(workout.dayNumber)) {
      return workout;
    }

    final estimatedDuration = estimatedDurationForDay(workout.dayNumber);

    return workout.copyWith(
      title: _fallbackText(workout.title, titleForDay(workout.dayNumber)),
      exerciseCount: workout.exerciseCount > 0
          ? workout.exerciseCount
          : exerciseCountForDay(workout.dayNumber) ?? workout.exerciseCount,
      estimatedDuration: workout.estimatedDuration > 0
          ? workout.estimatedDuration
          : estimatedDuration,
    );
  }

  static Map<String, dynamic> normalizeWorkoutResponse(
    Map<String, dynamic> response,
  ) {
    final data = response['data'];

    if (data is! Map) {
      return response;
    }

    final workout = _asMap(data['workout']);
    final dayNumber = _toInt(workout?['day_number']);
    final level = workout?['level']?.toString();

    if (dayNumber == null ||
        !_isBeginner(level) ||
        !hasBeginnerDay(dayNumber)) {
      return response;
    }

    final normalizedData = Map<String, dynamic>.from(data);
    final normalizedWorkout = Map<String, dynamic>.from(workout ?? {});
    normalizedWorkout['title'] = _fallbackText(
      normalizedWorkout['title'],
      titleForDay(dayNumber),
    );
    normalizedWorkout['name'] = _fallbackText(
      normalizedWorkout['name'],
      normalizedWorkout['title'],
    );

    final serverEstimatedDuration =
        _toInt(normalizedWorkout['estimated_duration']);
    final estimatedDuration = estimatedDurationForDay(dayNumber);
    if ((serverEstimatedDuration == null || serverEstimatedDuration <= 0) &&
        estimatedDuration > 0) {
      normalizedWorkout['estimated_duration'] = estimatedDuration;
    }

    normalizedData['workout'] = normalizedWorkout;

    final loadedExercises = data['exercises'];
    final exerciseList = loadedExercises is List ? loadedExercises : const [];
    if (exerciseList.isEmpty && hasExerciseOverride(dayNumber)) {
      normalizedData['exercises'] = applyExerciseOverride(
        dayNumber,
        exerciseList,
      );
    }

    return {
      ...response,
      'data': normalizedData,
    };
  }

  static List<Map<String, dynamic>> applyExerciseOverride(
    int dayNumber,
    List<dynamic> loadedExercises,
  ) {
    final catalogExercises = _exercisesByDay[dayNumber];

    if (catalogExercises == null) {
      return loadedExercises
          .map((exercise) => _asMap(exercise) ?? {'name': exercise.toString()})
          .toList(growable: false);
    }

    return List.generate(catalogExercises.length, (index) {
      final base = index < loadedExercises.length
          ? Map<String, dynamic>.from(_asMap(loadedExercises[index]) ?? {})
          : <String, dynamic>{};
      final catalog = catalogExercises[index];
      final duration = _toInt(catalog['duration']);
      final serverExerciseId = base['id'] ?? base['exercise_id'];
      final serverSets = base['sets'];

      return {
        ...base,
        'id': -(dayNumber * 100 + index + 1),
        'exercise_id': -(dayNumber * 100 + index + 1),
        'local_only': true,
        'server_exercise_id': serverExerciseId,
        'server_sets': serverSets,
        'name': catalog['name'],
        'title': catalog['name'],
        'sets': catalog['sets'],
        'reps': catalog['reps'],
        'duration': duration,
        'duration_seconds': duration,
        'rest_seconds': restSeconds,
        'type': duration == null ? 'training' : 'time',
      };
    }, growable: false);
  }

  static bool _isBeginner(String? value) {
    final text = value?.trim().toLowerCase();
    return text == 'beginner' || text == 'beginer' || text == 'begiener';
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static String _fallbackText(dynamic value, String fallback) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty || text == '-') {
      return fallback;
    }

    return text;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }
}
