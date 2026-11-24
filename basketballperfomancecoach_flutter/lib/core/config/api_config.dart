import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _webBaseUrl = 'http://127.0.0.1:8001/api';
  // Default Android ditujukan untuk HP fisik melalui `adb reverse`.
  // Emulator tetap bisa memakai 10.0.2.2 lewat --dart-define.
  static const String _androidBaseUrl = 'http://127.0.0.1:8001/api';

  static String get baseUrl {
    if (_overrideBaseUrl.trim().isNotEmpty) {
      return _normalize(_overrideBaseUrl);
    }

    if (kIsWeb) {
      return _webBaseUrl;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidBaseUrl;
    }

    return _webBaseUrl;
  }

  static String normalizeBackendAssetUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return trimmed;
    }

    final assetUri = Uri.tryParse(trimmed);
    final apiUri = Uri.parse(baseUrl);
    final apiOrigin = _origin(apiUri);

    if (assetUri == null) {
      return trimmed;
    }

    if (!assetUri.hasScheme && trimmed.startsWith('/')) {
      return '$apiOrigin$trimmed';
    }

    if (assetUri.hasAuthority && _isLoopbackHost(assetUri.host)) {
      final suffix = StringBuffer(assetUri.path);

      if (assetUri.hasQuery) {
        suffix.write('?${assetUri.query}');
      }

      if (assetUri.hasFragment) {
        suffix.write('#${assetUri.fragment}');
      }

      return '$apiOrigin$suffix';
    }

    return trimmed;
  }

  static String _normalize(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  static String _origin(Uri uri) {
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  static bool _isLoopbackHost(String host) {
    final normalized = host.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0';
  }
}
