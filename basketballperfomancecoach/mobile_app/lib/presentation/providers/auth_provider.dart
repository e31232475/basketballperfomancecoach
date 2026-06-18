import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  UserProfile? user;
  bool isBootstrapping = true;
  bool isLoading = false;
  String? errorMessage;

  bool get isAuthenticated => user != null;

  Future<void> bootstrap() async {
    isBootstrapping = true;
    notifyListeners();

    try {
      user = await _repository.bootstrap();
      errorMessage = null;
    } on ApiException catch (error) {
      user = null;
      errorMessage = error.message;
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    return _runAuthAction(() async {
      final result = await _repository.login(email: email, password: password);
      user = result.user;
    });
  }

  Future<bool> register(String name, String email, String password) async {
    return _runAuthAction(() async {
      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
      );
      user = result.user;
    });
  }

  Future<bool> savePersonalization({
    required String name,
    required double height,
    required double weight,
    required int age,
    required String trainingLevel,
  }) async {
    final currentUser = user;
    if (currentUser == null) {
      errorMessage = 'Session not found';
      notifyListeners();
      return false;
    }

    return _runAuthAction(() async {
      user = await _repository.savePersonalization(
        userId: currentUser.id,
        name: name,
        height: height,
        weight: weight,
        age: age,
        trainingLevel: trainingLevel,
      );
    });
  }

  Future<void> refreshProfile() async {
    final currentUser = user;
    if (currentUser == null) {
      return;
    }

    try {
      user = await _repository.profile(currentUser.id);
      errorMessage = null;
      notifyListeners();
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    await _repository.logout();
    user = null;
    isLoading = false;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      errorMessage = null;
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
