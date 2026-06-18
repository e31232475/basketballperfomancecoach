import '../../core/network/api_client.dart';
import '../models/progress_summary.dart';
import '../models/workout_models.dart';

class WorkoutRepository {
  WorkoutRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<WorkoutDay>> workoutList(int userId) async {
    final response = await _apiClient.get('/workout-list/$userId');
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => WorkoutDay.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutDetail> workoutDetail({
    required int userId,
    required int dayNumber,
  }) async {
    final response = await _apiClient.get(
      '/workout/$dayNumber?user_id=$userId',
    );
    return WorkoutDetail.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> logPerformance({
    required int userId,
    required int workoutId,
    required int exerciseId,
    required int setNumber,
    required bool success,
  }) async {
    await _apiClient.post(
      '/performance-log',
      body: {
        'user_id': userId,
        'workout_id': workoutId,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'success': success,
      },
    );
  }

  Future<WorkoutScore> completeWorkout({
    required int userId,
    required int dayNumber,
  }) async {
    final response = await _apiClient.post(
      '/complete-workout/$userId/$dayNumber',
    );
    final data = response['data'] as Map<String, dynamic>;
    return WorkoutScore.fromJson(data['score'] as Map<String, dynamic>);
  }

  Future<ProgressSummary> progress(int userId) async {
    final response = await _apiClient.get('/progress/$userId');
    return ProgressSummary.fromJson(response['data'] as Map<String, dynamic>);
  }
}
