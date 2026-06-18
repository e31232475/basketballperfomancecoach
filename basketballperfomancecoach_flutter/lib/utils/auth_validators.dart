class AuthValidators {
  static final RegExp _gmailPattern = RegExp(
    r'^[a-z0-9._%+-]+@gmail\.com$',
  );

  static final RegExp _passwordPattern = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d).{8,}$',
  );

  static bool isGmail(String email) {
    return _gmailPattern.hasMatch(email.trim().toLowerCase());
  }

  static bool isStrongPassword(String password) {
    return _passwordPattern.hasMatch(password);
  }

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }

    return null;
  }

  static String? gmail(
    String? value, {
    String message = "Please use a Gmail address",
  }) {
    final requiredError = requiredField(value, "Gmail address");

    if (requiredError != null) {
      return requiredError;
    }

    if (!isGmail(value!)) {
      return message;
    }

    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredField(value, "Password");

    if (requiredError != null) {
      return requiredError;
    }

    if (!isStrongPassword(value!)) {
      return "Password must be at least 8 characters and include letters and numbers";
    }

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final requiredError = requiredField(value, "Confirm password");

    if (requiredError != null) {
      return requiredError;
    }

    if (value != password) {
      return "Passwords do not match";
    }

    return null;
  }
}
