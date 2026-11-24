import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';
import '../models/athlete_notification.dart';

class NotificationInbox {
  final List<AthleteNotification> notifications;
  final int unreadCount;

  const NotificationInbox({
    required this.notifications,
    required this.unreadCount,
  });
}

class NotificationService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<NotificationInbox> getNotifications({int limit = 50}) async {
    final token = await _token();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications').replace(
        queryParameters: {'limit': limit.toString()},
      ),
      headers: _headers(token),
    );
    final body = _decode(response.body);
    _ensureSuccess(response, body, 'Gagal mengambil notifikasi');

    final rawItems = body['data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => AthleteNotification.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <AthleteNotification>[];
    final meta = body['meta'];
    final unreadCount = meta is Map
        ? _toInt(meta['unread_count'])
        : items.where((item) => !item.isRead).length;

    return NotificationInbox(
      notifications: items,
      unreadCount: unreadCount,
    );
  }

  static Future<int> getUnreadCount() async {
    final token = await _token();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread-count'),
      headers: _headers(token),
    );
    final body = _decode(response.body);
    _ensureSuccess(response, body, 'Gagal mengambil jumlah notifikasi');
    final data = body['data'];

    return data is Map ? _toInt(data['unread_count']) : 0;
  }

  static Future<void> markAsRead(String notificationId) async {
    final token = await _token();
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: _headers(token),
    );
    final body = _decode(response.body);
    _ensureSuccess(response, body, 'Gagal memperbarui notifikasi');
  }

  static Future<void> markAllAsRead() async {
    final token = await _token();
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: _headers(token),
    );
    final body = _decode(response.body);
    _ensureSuccess(response, body, 'Gagal membaca semua notifikasi');
  }

  static Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')?.trim();

    if (token == null || token.isEmpty || token == 'logged_in') {
      throw Exception('Sesi login atlet tidak ditemukan');
    }

    return token;
  }

  static Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static void _ensureSuccess(
    http.Response response,
    Map<String, dynamic> body,
    String fallback,
  ) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body['success'] == true) {
      return;
    }

    throw Exception(body['message']?.toString() ?? fallback);
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
