import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';
import '../data/beginner_workout_catalog.dart';
import '../models/workout_day_model.dart';

class WorkoutActionResult {
  final bool success;
  final String message;

  const WorkoutActionResult({
    required this.success,
    required this.message,
  });
}

class WorkoutAccessState {
  final bool canStart;
  final bool canPreview;
  final String statusLabel;
  final String message;
  final Duration? waitRemaining;
  final DateTime? availableAt;
  final int? requiredDayNumber;

  const WorkoutAccessState({
    required this.canStart,
    required this.canPreview,
    required this.statusLabel,
    required this.message,
    this.waitRemaining,
    this.availableAt,
    this.requiredDayNumber,
  });
}

class WorkoutService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const Duration workoutUnlockDelay = Duration(hours: 12);
  static const int _firstGatedDay = 1;
  static const int _lastGatedDay = 14;
  static const int _testingUnlockYear = 2026;
  static const int _testingUnlockMonth = 6;
  static const int _testingUnlockDay = 5;

  static Future<Map<String, dynamic>> getWorkoutByDay(int dayNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");
      final token = _tokenFrom(prefs);
      final hasAuthenticatedUser = userId != null && token != null;
      final uri = Uri.parse("$baseUrl/workout/$dayNumber").replace(
        queryParameters: hasAuthenticatedUser
            ? {
                "user_id": userId.toString(),
              }
            : null,
      );

      final response = await http.get(
        uri,
        headers: _authHeaders(token: hasAuthenticatedUser ? token : null),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          "success": false,
          "message": "Gagal mengambil workout",
        };
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return _withNormalizedMediaUrls(
          BeginnerWorkoutCatalog.normalizeWorkoutResponse(data),
        );
      }

      return {
        "success": false,
        "message": "Format response workout tidak valid",
      };
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");
      final token = _tokenFrom(prefs);

      if (userId == null || token == null) {
        return {
          "success": false,
          "message": "User belum login",
        };
      }

      final response = await http.get(
        Uri.parse("$baseUrl/progress/$userId"),
        headers: _authHeaders(token: token),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          "success": false,
          "message": "Gagal mengambil progress",
        };
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        "success": false,
        "message": "Format response progress tidak valid",
      };
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getTodayWorkout() async {
    return getWorkoutByDay(1);
  }

  static Future<List<WorkoutDayModel>> getWorkoutList() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int? userId = prefs.getInt("user_id");
      final token = _tokenFrom(prefs);

      if (userId == null || token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse("$baseUrl/workout-list/$userId"),
        headers: _authHeaders(token: token),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        List workouts = data["data"];

        final parsedWorkouts = workouts
            .map((e) => WorkoutDayModel.fromJson(e))
            .map(BeginnerWorkoutCatalog.normalizeWorkoutSummary)
            .toList();

        final hydratedWorkouts = await _withLocalCompletionTimestamps(
          parsedWorkouts,
          userId,
        );

        return applyWorkoutAccessRules(hydratedWorkouts);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Set<int>> getCompletedExerciseIds(int workoutId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int? userId = prefs.getInt("user_id");
      final token = _tokenFrom(prefs);

      if (userId == null || token == null) {
        return {};
      }

      final response = await http.get(
        Uri.parse("$baseUrl/exercise-progress/$userId/$workoutId"),
        headers: _authHeaders(token: token),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {};
      }

      final data = jsonDecode(response.body);
      final progressList = data is Map ? data["data"] : null;

      if (progressList is! List) {
        return {};
      }

      return progressList
          .where((progress) {
            if (progress is! Map) {
              return false;
            }

            return _isCompletedValue(progress["status"]);
          })
          .map((progress) => _toInt((progress as Map)["exercise_id"]))
          .whereType<int>()
          .toSet();
    } catch (e) {
      return {};
    }
  }

  static Future<WorkoutActionResult> completeExercise({
    required int workoutId,
    required int exerciseId,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int? userId = prefs.getInt("user_id");
      final token = _tokenFrom(prefs);

      if (userId == null || token == null) {
        return const WorkoutActionResult(
          success: false,
          message: "User belum login",
        );
      }

      final response = await http.post(
        Uri.parse("$baseUrl/exercise-progress"),
        headers: _authHeaders(token: token),
        body: {
          "user_id": userId.toString(),
          "workout_id": workoutId.toString(),
          "exercise_id": exerciseId.toString(),
          "status": "completed",
          "set_number": "1",
        },
      );

      return _actionResultFromResponse(response);
    } catch (e) {
      return WorkoutActionResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  static Future<WorkoutActionResult> logPerformance({
    required int workoutId,
    required int exerciseId,
    required int setNumber,
    required bool success,
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int? userId = prefs.getInt("user_id");
      final token = _tokenFrom(prefs);

      if (userId == null || token == null) {
        return const WorkoutActionResult(
          success: false,
          message: "User belum login",
        );
      }

      final response = await http.post(
        Uri.parse("$baseUrl/performance-log"),
        headers: _authHeaders(token: token),
        body: {
          "user_id": userId.toString(),
          "workout_id": workoutId.toString(),
          "exercise_id": exerciseId.toString(),
          "set_number": setNumber.toString(),
          "success": success ? "1" : "0",
        },
      );

      return _actionResultFromResponse(response);
    } catch (e) {
      return WorkoutActionResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  static Future<WorkoutActionResult> completeWorkout(
    int dayNumber,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      int? userId = prefs.getInt("user_id");
      final token = _tokenFrom(prefs);

      if (userId == null || token == null) {
        return const WorkoutActionResult(
          success: false,
          message: "User belum login",
        );
      }

      final response = await http.post(
        Uri.parse(
          "$baseUrl/complete-workout/$userId/$dayNumber",
        ),
        headers: _authHeaders(token: token),
      );

      final result = _actionResultFromResponse(response);

      if (result.success) {
        await _rememberWorkoutCompletedAt(
          prefs,
          userId,
          dayNumber,
          DateTime.now(),
        );
      }

      return result;
    } catch (e) {
      return WorkoutActionResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  static Future<WorkoutActionResult> uploadWorkoutRecording({
    required int workoutId,
    required int dayNumber,
    required Uint8List videoBytes,
    required String filename,
    required String mimeType,
    int? durationSeconds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");
      final token = _tokenFrom(prefs);

      if (userId == null || token == null) {
        return const WorkoutActionResult(
          success: false,
          message: "User belum login",
        );
      }

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/workout-recordings"),
      );

      request.fields.addAll({
        "user_id": userId.toString(),
        "workout_id": workoutId.toString(),
        "day_number": dayNumber.toString(),
        "mime_type": mimeType,
        if (durationSeconds != null)
          "duration_seconds": durationSeconds.toString(),
      });
      request.files.add(
        http.MultipartFile.fromBytes(
          "video",
          videoBytes,
          filename: filename,
        ),
      );
      request.headers["Accept"] = "application/json";
      request.headers["Authorization"] = "Bearer $token";

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _actionResultFromResponse(response);
    } catch (e) {
      return WorkoutActionResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  static Future<WorkoutAccessState> getWorkoutAccess(int dayNumber) async {
    final workouts = await getWorkoutList();

    WorkoutDayModel? workout;

    for (final item in workouts) {
      if (item.dayNumber == dayNumber) {
        workout = item;
        break;
      }
    }

    if (workout == null) {
      if (dayNumber == _firstGatedDay) {
        return const WorkoutAccessState(
          canStart: true,
          canPreview: true,
          statusLabel: "START",
          message: "Day 1 siap dimulai.",
        );
      }

      return WorkoutAccessState(
        canStart: false,
        canPreview: true,
        statusLabel: "PREVIEW",
        message: "Selesaikan Day ${dayNumber - 1} terlebih dahulu.",
        requiredDayNumber: dayNumber - 1,
      );
    }

    return workoutAccessFor(workout, workouts);
  }

  static List<WorkoutDayModel> applyWorkoutAccessRules(
    List<WorkoutDayModel> workouts, {
    DateTime? now,
  }) {
    if (_isTestingUnlockAllDaysActive(now)) {
      return workouts
          .map((workout) => workout.copyWith(locked: false))
          .toList(growable: false);
    }

    return workouts.map((workout) {
      final access = workoutAccessFor(
        workout,
        workouts,
        now: now,
      );

      return workout.copyWith(
        locked: workout.completed ? false : !access.canStart,
      );
    }).toList(growable: false);
  }

  static WorkoutAccessState workoutAccessFor(
    WorkoutDayModel workout,
    List<WorkoutDayModel> workouts, {
    DateTime? now,
  }) {
    if (_isTestingUnlockAllDaysActive(now)) {
      return WorkoutAccessState(
        canStart: true,
        canPreview: true,
        statusLabel: workout.completed ? "DONE" : "START",
        message: workout.completed
            ? "Day ${workout.dayNumber} sudah selesai."
            : "Testing hari ini: semua day terbuka.",
      );
    }

    if (!_isGatedWorkoutDay(workout.dayNumber)) {
      if (workout.completed || !workout.locked) {
        return const WorkoutAccessState(
          canStart: true,
          canPreview: true,
          statusLabel: "START",
          message: "Workout siap dimulai.",
        );
      }

      return const WorkoutAccessState(
        canStart: false,
        canPreview: true,
        statusLabel: "PREVIEW",
        message: "Workout ini masih terkunci, tetapi preview tetap tersedia.",
      );
    }

    if (workout.completed) {
      return WorkoutAccessState(
        canStart: true,
        canPreview: true,
        statusLabel: "DONE",
        message: "Day ${workout.dayNumber} sudah selesai.",
      );
    }

    if (workout.dayNumber == _firstGatedDay) {
      return const WorkoutAccessState(
        canStart: true,
        canPreview: true,
        statusLabel: "START",
        message: "Day 1 siap dimulai.",
      );
    }

    final previousDayNumber = workout.dayNumber - 1;
    final previousWorkout = _previousWorkoutFor(workout, workouts);

    if (previousWorkout == null || !previousWorkout.completed) {
      return WorkoutAccessState(
        canStart: false,
        canPreview: true,
        statusLabel: "PREVIEW",
        message: "Selesaikan Day $previousDayNumber terlebih dahulu.",
        requiredDayNumber: previousDayNumber,
      );
    }

    final previousCompletedAt = previousWorkout.completedAt;

    if (previousCompletedAt == null) {
      return WorkoutAccessState(
        canStart: true,
        canPreview: true,
        statusLabel: "START",
        message: "Day ${workout.dayNumber} siap dimulai.",
      );
    }

    final currentTime = now ?? DateTime.now();
    final availableAt = previousCompletedAt.add(workoutUnlockDelay);

    if (currentTime.isBefore(availableAt)) {
      final remaining = availableAt.difference(currentTime);

      return WorkoutAccessState(
        canStart: false,
        canPreview: true,
        statusLabel: _formatWaitStatus(remaining),
        message:
            "Day ${workout.dayNumber} bisa dimulai dalam ${_formatWaitMessage(remaining)}.",
        waitRemaining: remaining,
        availableAt: availableAt,
        requiredDayNumber: previousDayNumber,
      );
    }

    return WorkoutAccessState(
      canStart: true,
      canPreview: true,
      statusLabel: "START",
      message: "Day ${workout.dayNumber} siap dimulai.",
    );
  }

  static WorkoutActionResult _actionResultFromResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return WorkoutActionResult(
          success: false,
          message: "Request gagal (${response.statusCode})",
        );
      }

      return const WorkoutActionResult(
        success: true,
        message: "Berhasil",
      );
    }

    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (e) {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return WorkoutActionResult(
          success: false,
          message: "Request gagal (${response.statusCode})",
        );
      }

      return const WorkoutActionResult(
        success: true,
        message: "Berhasil",
      );
    }

    if (data is Map) {
      final success = response.statusCode >= 200 && response.statusCode < 300
          ? data["success"] == true
          : false;
      return WorkoutActionResult(
        success: success,
        message: data["message"]?.toString() ??
            (success ? "Berhasil" : "Request gagal"),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return WorkoutActionResult(
        success: false,
        message: "Request gagal (${response.statusCode})",
      );
    }

    return const WorkoutActionResult(
      success: true,
      message: "Berhasil",
    );
  }

  static Map<String, String> _authHeaders({String? token}) {
    return {
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  static String? _tokenFrom(SharedPreferences prefs) {
    final token = prefs.getString("token")?.trim();

    if (token == null || token.isEmpty || token == "logged_in") {
      return null;
    }

    return token;
  }

  static Map<String, dynamic> _withNormalizedMediaUrls(
    Map<String, dynamic> data,
  ) {
    return Map<String, dynamic>.from(_normalizeMediaUrls(data) as Map);
  }

  static dynamic _normalizeMediaUrls(dynamic value, [Object? key]) {
    if (value is Map) {
      return value.map(
        (entryKey, entryValue) => MapEntry(
          entryKey,
          _normalizeMediaUrls(entryValue, entryKey),
        ),
      );
    }

    if (value is List) {
      return value
          .map((item) => _normalizeMediaUrls(item))
          .toList(growable: false);
    }

    if (value is String && _isMediaUrlKey(key)) {
      return ApiConfig.normalizeBackendAssetUrl(value);
    }

    return value;
  }

  static bool _isMediaUrlKey(Object? key) {
    final normalized = key?.toString().toLowerCase();
    return normalized == 'video' ||
        normalized == 'video_url' ||
        normalized == 'recording_url';
  }

  static bool _isCompletedValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase();
    return text == "completed" ||
        text == "complete" ||
        text == "true" ||
        text == "1";
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? "");
  }

  static Future<List<WorkoutDayModel>> _withLocalCompletionTimestamps(
    List<WorkoutDayModel> workouts,
    int userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final hydrated = <WorkoutDayModel>[];

    for (final workout in workouts) {
      if (!workout.completed) {
        hydrated.add(workout);
        continue;
      }

      final localCompletedAt = _dateTimeFromText(
        prefs.getString(_completedAtKey(userId, workout.dayNumber)),
      );
      final completedAt = _latestDateTime(
        workout.completedAt,
        localCompletedAt,
      );

      if (completedAt != null) {
        await _rememberWorkoutCompletedAt(
          prefs,
          userId,
          workout.dayNumber,
          completedAt,
        );

        hydrated.add(workout.copyWith(completedAt: completedAt));
        continue;
      }

      hydrated.add(workout);
    }

    return hydrated;
  }

  static Future<void> _rememberWorkoutCompletedAt(
    SharedPreferences prefs,
    int userId,
    int dayNumber,
    DateTime completedAt,
  ) {
    return prefs.setString(
      _completedAtKey(userId, dayNumber),
      completedAt.toUtc().toIso8601String(),
    );
  }

  static String _completedAtKey(int userId, int dayNumber) {
    return "workout_completed_at_v1_${userId}_$dayNumber";
  }

  static WorkoutDayModel? _previousWorkoutFor(
    WorkoutDayModel workout,
    List<WorkoutDayModel> workouts,
  ) {
    final previousDayNumber = workout.dayNumber - 1;
    final level = _normalizeLevel(workout.level);

    for (final candidate in workouts) {
      final sameDay = candidate.dayNumber == previousDayNumber;
      final sameLevel = _normalizeLevel(candidate.level) == level;

      if (sameDay && sameLevel) {
        return candidate;
      }
    }

    return null;
  }

  static bool _isGatedWorkoutDay(int dayNumber) {
    return dayNumber >= _firstGatedDay && dayNumber <= _lastGatedDay;
  }

  static bool _isTestingUnlockAllDaysActive(DateTime? now) {
    final currentTime = now ?? DateTime.now();

    return currentTime.year == _testingUnlockYear &&
        currentTime.month == _testingUnlockMonth &&
        currentTime.day == _testingUnlockDay;
  }

  static String? _normalizeLevel(String? value) {
    final text = value?.trim().toLowerCase();

    if (text == null || text.isEmpty || text == "-") {
      return null;
    }

    if (text == "intermediate" || text == "intermeditate") {
      return "intermediate";
    }

    if (text == "beginner" || text == "begiener" || text == "beginer") {
      return "beginner";
    }

    return text;
  }

  static DateTime? _latestDateTime(DateTime? first, DateTime? second) {
    if (first == null) {
      return second;
    }

    if (second == null) {
      return first;
    }

    return first.isAfter(second) ? first : second;
  }

  static DateTime? _dateTimeFromText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text)?.toLocal();
  }

  static String _formatWaitStatus(Duration duration) {
    final totalMinutes = _ceilMinutes(duration);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours <= 0) {
      return "WAIT ${minutes}M";
    }

    if (minutes == 0) {
      return "WAIT ${hours}H";
    }

    return "WAIT ${hours}H ${minutes}M";
  }

  static String _formatWaitMessage(Duration duration) {
    final totalMinutes = _ceilMinutes(duration);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours <= 0) {
      return "$minutes menit";
    }

    if (minutes == 0) {
      return "$hours jam";
    }

    return "$hours jam $minutes menit";
  }

  static int _ceilMinutes(Duration duration) {
    final seconds = duration.inSeconds;

    if (seconds <= 0) {
      return 0;
    }

    return (seconds / 60).ceil();
  }
}
