class AthleteNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final int? reviewId;
  final int? recordingId;
  final int? workoutId;
  final String? workoutTitle;
  final int? dayNumber;
  final String? status;
  final String? statusLabel;
  final int? score;
  final String? feedback;
  final DateTime? reviewedAt;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;

  const AthleteNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.reviewId,
    this.recordingId,
    this.workoutId,
    this.workoutTitle,
    this.dayNumber,
    this.status,
    this.statusLabel,
    this.score,
    this.feedback,
    this.reviewedAt,
    required this.isRead,
    this.readAt,
    this.createdAt,
  });

  factory AthleteNotification.fromJson(Map<String, dynamic> json) {
    return AthleteNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'notification',
      title: json['title']?.toString() ?? 'Notifikasi',
      message: json['message']?.toString() ?? '',
      reviewId: _toInt(json['review_id']),
      recordingId: _toInt(json['recording_id']),
      workoutId: _toInt(json['workout_id']),
      workoutTitle: json['workout_title']?.toString(),
      dayNumber: _toInt(json['day_number']),
      status: json['status']?.toString(),
      statusLabel: json['status_label']?.toString(),
      score: _toInt(json['score']),
      feedback: json['feedback']?.toString(),
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
      isRead: _toBool(json['is_read']),
      readAt: DateTime.tryParse(json['read_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  AthleteNotification copyWith({bool? isRead, DateTime? readAt}) {
    return AthleteNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      reviewId: reviewId,
      recordingId: recordingId,
      workoutId: workoutId,
      workoutTitle: workoutTitle,
      dayNumber: dayNumber,
      status: status,
      statusLabel: statusLabel,
      score: score,
      feedback: feedback,
      reviewedAt: reviewedAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }
}
