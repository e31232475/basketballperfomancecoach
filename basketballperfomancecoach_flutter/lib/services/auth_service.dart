import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';
import '../utils/auth_validators.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const String _athletePortal = "athlete_app";

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (!AuthValidators.isGmail(email)) {
      return {
        "success": false,
        "message": "Please use a valid Gmail address",
      };
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: _jsonHeaders(),
        body: jsonEncode({
          "name": name,
          "email": email,
          "role": "athlete",
          "portal": _athletePortal,
          "password": password,
          "password_confirmation": passwordConfirmation,
        }),
      );

      return _handleAuthResponse(
        response,
        defaultError: "Register failed",
        rememberMe: true,
      );
    } catch (_) {
      return {
        "success": false,
        "message": "Unable to connect to authentication server: $baseUrl",
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    if (!AuthValidators.isGmail(email)) {
      return {
        "success": false,
        "message": "Please use a Gmail address",
      };
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: _jsonHeaders(),
        body: jsonEncode({
          "email": email,
          "password": password,
          "portal": _athletePortal,
        }),
      );

      return _handleAuthResponse(
        response,
        defaultError: "Login failed",
        rememberMe: rememberMe,
      );
    } catch (_) {
      return {
        "success": false,
        "message": "Unable to connect to authentication server: $baseUrl",
      };
    }
  }

  static Future<Map<String, dynamic>> loginWithFirebase({
    required String idToken,
    bool rememberMe = true,
  }) async {
    if (idToken.trim().isEmpty) {
      return {
        "success": false,
        "message": "Firebase token is required",
      };
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/firebase-login"),
        headers: _jsonHeaders(),
        body: jsonEncode({
          "id_token": idToken,
          "portal": _athletePortal,
        }),
      );

      return _handleAuthResponse(
        response,
        defaultError: "Firebase login failed",
        rememberMe: rememberMe,
      );
    } catch (_) {
      return {
        "success": false,
        "message": "Unable to connect to authentication server: $baseUrl",
      };
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token != null && token.isNotEmpty && token != "logged_in") {
      try {
        await http.post(
          Uri.parse("$baseUrl/logout"),
          headers: _jsonHeaders(token: token),
        );
      } catch (_) {
        // Local logout must still happen even if the API is unreachable.
      }
    }

    await prefs.clear();
  }

  static Future<Map<String, dynamic>> cachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = _usableToken(prefs.getString("token"));
    final userId = prefs.getInt("user_id");

    if (token == null || userId == null) {
      return {
        "is_logged_in": false,
        "personalization_completed": false,
        "user": <String, dynamic>{},
      };
    }

    final cachedRole = prefs.getString("role");
    if (cachedRole == null || cachedRole.isEmpty) {
      final verified = await _refreshCachedUser(userId, token);

      if (!verified) {
        await prefs.clear();
        return {
          "is_logged_in": false,
          "personalization_completed": false,
          "user": <String, dynamic>{},
        };
      }
    } else if (!_isAthleteRole(cachedRole)) {
      await prefs.clear();
      return {
        "is_logged_in": false,
        "personalization_completed": false,
        "user": <String, dynamic>{},
      };
    }

    final isPersonalized = prefs.getBool("personalization_completed") ??
        prefs.getBool("is_personalized") ??
        false;

    return {
      "is_logged_in": true,
      "token": token,
      "user_id": userId,
      "username": prefs.getString("username") ?? prefs.getString("user_name"),
      "email": prefs.getString("email"),
      "personalization_completed": isPersonalized,
      "user": {
        "id": userId,
        "name": prefs.getString("username") ?? prefs.getString("user_name"),
        "email": prefs.getString("email"),
        "role": prefs.getString("role") ?? "athlete",
        "height": prefs.getDouble("height"),
        "weight": prefs.getDouble("weight"),
        "age": prefs.getInt("age"),
        "training_level": prefs.getString("training_level"),
        "is_personalized": isPersonalized,
        "personalization_completed": isPersonalized,
      },
    };
  }

  static Future<Map<String, dynamic>> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getInt("user_id");
      final token = _usableToken(prefs.getString("token"));

      if (userId == null || token == null) {
        if (userId != null) {
          await prefs.clear();
        }

        return {
          "success": false,
          "message": "User tidak login",
        };
      }

      final response = await http.get(
        Uri.parse("$baseUrl/user/$userId").replace(
          queryParameters: {
            "portal": _athletePortal,
          },
        ),
        headers: _jsonHeaders(token: token),
      );

      final data = _decode(response.body);

      if (data is Map && data["success"] == true && data["data"] is Map) {
        if (!_isAthleteRole((data["data"] as Map)["role"]?.toString())) {
          await logout();
          return {
            "success": false,
            "message":
                "Akun coach/admin tidak bisa mengakses app atlet. Silakan register akun athlete terlebih dahulu.",
          };
        }

        await _cacheUser(data["data"] as Map);
      }

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        "success": false,
        "message": "Format response tidak valid",
      };
    } catch (_) {
      return {
        "success": false,
        "message": "Unable to load user profile",
      };
    }
  }

  static Future<Map<String, dynamic>> savePersonalization({
    required String name,
    required double height,
    required double weight,
    required int age,
    required String trainingLevel,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");
      final token = _usableToken(prefs.getString("token"));

      if (userId == null || token == null) {
        if (userId != null) {
          await prefs.clear();
        }

        return {
          "success": false,
          "message": "User belum login",
        };
      }

      final response = await http.post(
        Uri.parse("$baseUrl/personalization"),
        headers: _jsonHeaders(token: token),
        body: jsonEncode({
          "user_id": userId,
          "name": name,
          "height": height,
          "weight": weight,
          "age": age,
          "training_level": trainingLevel,
          "portal": _athletePortal,
        }),
      );

      final data = _decode(response.body);

      if (data is Map && data["success"] == true && data["data"] is Map) {
        await _cacheUser(data["data"] as Map);
      }

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        "success": false,
        "message": "Format response tidak valid",
      };
    } catch (_) {
      return {
        "success": false,
        "message": "Unable to save personalization",
      };
    }
  }

  static Future<String?> cachedTrainingLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("training_level");
  }

  static Map<String, String> _jsonHeaders({String? token}) {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty && token != "logged_in")
        "Authorization": "Bearer $token",
    };
  }

  static String? _usableToken(String? value) {
    final token = value?.trim();

    if (token == null || token.isEmpty || token == "logged_in") {
      return null;
    }

    return token;
  }

  static Future<Map<String, dynamic>> _handleAuthResponse(
    http.Response response, {
    required String defaultError,
    required bool rememberMe,
  }) async {
    final data = _decode(response.body);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data is Map &&
        data["success"] == true) {
      final user = _extractUser(data);
      final token = _extractToken(data, user);

      if (user == null || token == null || token.isEmpty) {
        return {
          "success": false,
          "message": "Invalid authentication response",
        };
      }

      if (!_isAthleteRole(user["role"]?.toString())) {
        await logout();
        return {
          "success": false,
          "message":
              "Akun coach/admin hanya bisa mengakses web coach/admin. Untuk memakai app atlet, silakan register akun athlete terlebih dahulu.",
        };
      }

      await _cacheSession(user, token: token, rememberMe: rememberMe);

      final isPersonalized = _isPersonalized(user);

      return {
        "success": true,
        "message": data["message"]?.toString() ?? "Authentication success",
        "data": data,
        "user": Map<String, dynamic>.from(user),
        "is_personalized": isPersonalized,
        "personalization_completed": isPersonalized,
      };
    }

    return {
      "success": false,
      "message": _errorMessage(data, response.statusCode, defaultError),
    };
  }

  static dynamic _decode(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Map? _extractUser(Map data) {
    final responseData = data["data"];

    if (responseData is Map) {
      if (responseData["user"] is Map) {
        return responseData["user"] as Map;
      }

      return responseData;
    }

    if (data["user"] is Map) {
      return data["user"] as Map;
    }

    return null;
  }

  static String? _extractToken(Map data, Map? user) {
    final responseData = data["data"];

    if (responseData is Map && responseData["token"] != null) {
      return responseData["token"].toString();
    }

    if (data["token"] != null) {
      return data["token"].toString();
    }

    if (user != null && user["token"] != null) {
      return user["token"].toString();
    }

    return null;
  }

  static String _errorMessage(
    dynamic data,
    int statusCode,
    String fallback,
  ) {
    if (data is Map) {
      final errors = data["errors"];

      if (errors is Map && errors.isNotEmpty) {
        final firstValue = errors.values.first;

        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }

        return firstValue.toString();
      }

      final message = data["message"]?.toString();

      if (message != null && message.isNotEmpty) {
        return _friendlyAuthMessage(message);
      }
    }

    if (statusCode == 404) {
      return "Email not registered";
    }

    if (statusCode == 401) {
      return "Incorrect password";
    }

    return fallback;
  }

  static String _friendlyAuthMessage(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains("gmail")) {
      return message;
    }

    if (normalized.contains("not registered") ||
        normalized.contains("tidak ditemukan")) {
      return "Email not registered";
    }

    if (normalized.contains("incorrect password") ||
        normalized.contains("password salah")) {
      return "Incorrect password";
    }

    if (normalized.contains("email atau password salah")) {
      return "Email not registered or incorrect password";
    }

    return message;
  }

  static Future<void> _cacheSession(
    Map user, {
    required String token,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _toInt(user["id"]);

    if (userId == null) {
      return;
    }

    await prefs.setString("token", token);
    await prefs.setInt("user_id", userId);
    await prefs.setBool("remember_me", rememberMe);
    await _cacheUser(user);
  }

  static Future<void> _cacheUser(Map user) async {
    final prefs = await SharedPreferences.getInstance();
    final name = user["name"]?.toString();
    final email = user["email"]?.toString();
    final role = user["role"]?.toString();
    final trainingLevel = user["training_level"]?.toString();
    final height = _toDouble(user["height"]);
    final weight = _toDouble(user["weight"]);
    final age = _toInt(user["age"]);
    final isPersonalized = _isPersonalized(user);

    if (name != null && name.isNotEmpty) {
      await prefs.setString("username", name);
      await prefs.setString("user_name", name);
    }

    if (email != null && email.isNotEmpty) {
      await prefs.setString("email", email);
    }

    await prefs.setString(
      "role",
      _isAthleteRole(role) ? "athlete" : (role ?? ""),
    );

    if (trainingLevel != null && trainingLevel.isNotEmpty) {
      await prefs.setString("training_level", trainingLevel);
    }

    if (height != null) {
      await prefs.setDouble("height", height);
    }

    if (weight != null) {
      await prefs.setDouble("weight", weight);
    }

    if (age != null) {
      await prefs.setInt("age", age);
    }

    await prefs.setBool("is_personalized", isPersonalized);
    await prefs.setBool("personalization_completed", isPersonalized);
  }

  static bool _isPersonalized(Map user) {
    final value = user["personalization_completed"] ?? user["is_personalized"];

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value == 1;
    }

    if (value != null) {
      final text = value.toString().toLowerCase();
      return text == "true" || text == "1";
    }

    return user["height"] != null &&
        user["weight"] != null &&
        user["age"] != null &&
        user["training_level"] != null;
  }

  static Future<bool> _refreshCachedUser(int userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/user/$userId").replace(
          queryParameters: {
            "portal": _athletePortal,
          },
        ),
        headers: _jsonHeaders(token: token),
      );
      final data = _decode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data is! Map ||
          data["success"] != true ||
          data["data"] is! Map) {
        return false;
      }

      final user = data["data"] as Map;
      if (!_isAthleteRole(user["role"]?.toString())) {
        return false;
      }

      await _cacheUser(user);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _isAthleteRole(String? role) {
    final normalized = role?.trim().toLowerCase();

    return normalized == null || normalized.isEmpty || normalized == "athlete";
  }

  static double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? "");
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
}
