import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../data/models/workout_models.dart';
import '../../data/repositories/workout_repository.dart';

class WorkoutProvider extends ChangeNotifier {
  WorkoutProvider(this._repository);

  final WorkoutRepository _repository;

  List<WorkoutDay> workouts = [];
  WorkoutDetail? selectedWorkout;
  WorkoutScore? lastScore;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadWorkoutList(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      workouts = await _repository.workoutList(userId);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<WorkoutDetail?> loadWorkoutDetail({
    required int userId,
    required int dayNumber,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      selectedWorkout = await _repository.workoutDetail(
        userId: userId,
        dayNumber: dayNumber,
      );
      return selectedWorkout;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logSet({
    required int userId,
    required int workoutId,
    required int exerciseId,
    required int setNumber,
    required bool success,
  }) async {
    try {
      await _repository.logPerformance(
        userId: userId,
        workoutId: workoutId,
        exerciseId: exerciseId,
        setNumber: setNumber,
        success: success,
      );
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  Future<WorkoutScore?> completeWorkout({
    required int userId,
    required int dayNumber,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      lastScore = await _repository.completeWorkout(
        userId: userId,
        dayNumber: dayNumber,
      );
      await loadWorkoutList(userId);
      return lastScore;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
