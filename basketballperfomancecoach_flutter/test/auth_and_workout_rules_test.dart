import 'package:basketballperfomancecoach_flutter/models/workout_day_model.dart';
import 'package:basketballperfomancecoach_flutter/services/workout_service.dart';
import 'package:basketballperfomancecoach_flutter/utils/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidators', () {
    test('accepts only Gmail addresses', () {
      expect(AuthValidators.isGmail('ATHLETE@gmail.com'), isTrue);
      expect(AuthValidators.isGmail(' athlete.name@gmail.com '), isTrue);
      expect(AuthValidators.isGmail('athlete@yahoo.com'), isFalse);
      expect(AuthValidators.isGmail('athlete@gmail.co'), isFalse);
    });

    test('requires strong passwords with letters and numbers', () {
      expect(AuthValidators.isStrongPassword('player123'), isTrue);
      expect(AuthValidators.isStrongPassword('12345678'), isFalse);
      expect(AuthValidators.isStrongPassword('password'), isFalse);
      expect(AuthValidators.isStrongPassword('abc12'), isFalse);
    });
  });

  group('Workout access rules', () {
    test('locks day 2 until day 1 is completed', () {
      final workouts = [
        _workout(dayNumber: 1),
        _workout(dayNumber: 2),
      ];

      final day1Access = WorkoutService.workoutAccessFor(
        workouts[0],
        workouts,
        now: DateTime(2026, 6, 18, 8),
      );
      final day2Access = WorkoutService.workoutAccessFor(
        workouts[1],
        workouts,
        now: DateTime(2026, 6, 18, 8),
      );

      expect(day1Access.canStart, isTrue);
      expect(day2Access.canStart, isFalse);
      expect(day2Access.requiredDayNumber, 1);
    });

    test('waits 12 hours after previous day completion', () {
      final completedAt = DateTime(2026, 6, 18, 8);
      final workouts = [
        _workout(dayNumber: 1, completed: true, completedAt: completedAt),
        _workout(dayNumber: 2),
      ];

      final waitingAccess = WorkoutService.workoutAccessFor(
        workouts[1],
        workouts,
        now: completedAt.add(const Duration(hours: 6)),
      );
      final readyAccess = WorkoutService.workoutAccessFor(
        workouts[1],
        workouts,
        now: completedAt.add(const Duration(hours: 12)),
      );

      expect(waitingAccess.canStart, isFalse);
      expect(waitingAccess.waitRemaining, const Duration(hours: 6));
      expect(readyAccess.canStart, isTrue);
    });

    test('testing unlock date opens all workout days', () {
      final workouts = [
        _workout(dayNumber: 1),
        _workout(dayNumber: 2),
      ];

      final unlocked = WorkoutService.applyWorkoutAccessRules(
        workouts,
        now: DateTime(2026, 6, 5, 10),
      );

      expect(unlocked.every((workout) => !workout.locked), isTrue);
    });
  });
}

WorkoutDayModel _workout({
  required int dayNumber,
  bool completed = false,
  DateTime? completedAt,
}) {
  return WorkoutDayModel(
    id: dayNumber,
    title: 'Day $dayNumber',
    dayNumber: dayNumber,
    level: 'Beginner',
    completed: completed,
    locked: !completed && dayNumber > 1,
    completedAt: completedAt,
    exerciseCount: 5,
    estimatedDuration: 15,
    progressPercentage: completed ? 100 : 0,
  );
}
