import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../models/user_profile.dart';

class AuthResult {
  const AuthResult({required this.user, this.token});

  final UserProfile user;
  final String? token;
}

class AuthRepository {
  AuthRepository(this._apiClient, this._sessionStorage);

  final ApiClient _apiClient;
  final SessionStorage _sessionStorage;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/login',
      body: {'email': email, 'password': password},
    );
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token']?.toString();
    _apiClient.setToken(token);
    final user = UserProfile.fromJson(data);
    await _sessionStorage.saveSession(userId: user.id, token: token);
    return AuthResult(user: user, token: token);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token']?.toString();
    _apiClient.setToken(token);
    final user = UserProfile.fromJson(data);
    await _sessionStorage.saveSession(userId: user.id, token: token);
    return AuthResult(user: user, token: token);
  }

  Future<UserProfile?> bootstrap() async {
    final userId = await _sessionStorage.getUserId();
    final token = await _sessionStorage.getToken();

    if (userId == null) {
      return null;
    }

    _apiClient.setToken(token);
    return profile(userId);
  }

  Future<UserProfile> profile(int userId) async {
    final response = await _apiClient.get('/profile/$userId');
    return UserProfile.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserProfile> savePersonalization({
    required int userId,
    required String name,
    required double height,
    required double weight,
    required int age,
    required String gender,
    String? profilePhotoPath,
    bool removeProfilePhoto = false,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      if (removeProfilePhoto) 'profile_photo_url': null,
    };
    final response = profilePhotoPath == null
        ? await _apiClient.post('/personalization', body: body)
        : await _apiClient.postMultipart(
            '/personalization',
            fields: {
              'user_id': userId.toString(),
              'name': name,
              'height': height.toString(),
              'weight': weight.toString(),
              'age': age.toString(),
              'gender': gender,
            },
            fileField: 'profile_photo',
            filePath: profilePhotoPath,
          );
    final user = UserProfile.fromJson(response['data'] as Map<String, dynamic>);
    await _sessionStorage.saveSession(userId: user.id);
    return user;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/logout');
    } on ApiException {
      // Local session cleanup should still happen if the token has expired.
    }
    _apiClient.setToken(null);
    await _sessionStorage.clear();
  }
}
