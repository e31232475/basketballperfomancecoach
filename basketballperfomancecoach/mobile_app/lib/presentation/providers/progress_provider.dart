import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../data/models/progress_summary.dart';
import '../../data/repositories/workout_repository.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._repository);

  final WorkoutRepository _repository;

  ProgressSummary summary = ProgressSummary.empty();
  bool isLoading = false;
  String? errorMessage;

  Future<void> load(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      summary = await _repository.progress(userId);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
