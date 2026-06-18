import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/workout_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic> progress = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await WorkoutService.getProgress();
    final data = response["data"];

    if (!mounted) {
      return;
    }

    if (response["success"] != true || data is! Map) {
      setState(() {
        isLoading = false;
        errorMessage = response["message"]?.toString() ?? "Progress not found";
      });
      return;
    }

    setState(() {
      progress = Map<String, dynamic>.from(data);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PROGRESS",
          style: TextStyle(
            color: AppColors.lavender,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadProgress,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntroCard(),
                        const SizedBox(height: 18),
                        _ConsistencyChartCard(
                          title: "Consistency Progress",
                          subtitle:
                              "Berdasarkan aktivitas latihan dan waktu upload.",
                          value: _toInt(progress["consistency_progress"]),
                          color: AppColors.secondary,
                          chartItems: _consistencyChartItems(),
                          details: [
                            _DetailItem(
                              label: "Completed workouts",
                              value: _toInt(
                                progress["completed_workout_total"],
                              ).toString(),
                            ),
                            _DetailItem(
                              label: "Current streak",
                              value:
                                  "${_toInt(progress["current_streak"])} day",
                            ),
                            _DetailItem(
                              label: "Weekly consistency",
                              value:
                                  "${_toInt(progress["weekly_consistency"])}%",
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ProgressCard(
                          title: "Performance Based Progress",
                          subtitle:
                              "Berdasarkan score dan validasi dari coach.",
                          value: _toInt(
                            progress["performance_based_progress"] ??
                                progress["performance_score"],
                          ),
                          icon: Icons.verified_rounded,
                          color: AppColors.primary,
                          details: [
                            _DetailItem(
                              label: "Coach reviews",
                              value: _toInt(progress["coach_review_count"])
                                  .toString(),
                            ),
                            _DetailItem(
                              label: "Last status",
                              value: _reviewStatusLabel(
                                progress["coach_review_status"],
                              ),
                            ),
                            _DetailItem(
                              label: "Last reviewed",
                              value: _formatDate(
                                progress["coach_reviewed_at"]?.toString(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildCoachFeedback(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insights,
              color: AppColors.primary,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              errorMessage ?? "Progress not found",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _loadProgress,
              child: const Text("Reload"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Training Progress",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Progress dibagi menjadi konsistensi latihan dan kualitas performa yang divalidasi coach.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachFeedback() {
    final feedback = progress["coach_feedback"]?.toString().trim();
    final fallback = progress["feedback"]?.toString().trim();
    final message = (feedback?.isNotEmpty == true ? feedback : fallback) ??
        "Menunggu validasi coach.";
    final reviews = _coachReviewItems();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lavender.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.rate_review_rounded,
              color: AppColors.lavender,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Coach Feedback",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (reviews.isEmpty)
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  )
                else ...[
                  const Text(
                    "Semua review dari coach ditampilkan sesuai day latihan.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...reviews.map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CoachReviewTile(review: review),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _reviewStatusLabel(dynamic value) {
    final text = value?.toString().trim().toLowerCase();

    if (text == "approved") {
      return "Approved";
    }

    if (text == "needs_revision" || text == "rejected") {
      return "Perlu ulang";
    }

    return "Menunggu review";
  }

  String _formatDate(String? value) {
    final date = DateTime.tryParse(value ?? "")?.toLocal();

    if (date == null) {
      return "-";
    }

    final day = date.day.toString().padLeft(2, "0");
    final month = date.month.toString().padLeft(2, "0");
    final hour = date.hour.toString().padLeft(2, "0");
    final minute = date.minute.toString().padLeft(2, "0");
    return "$day/$month $hour:$minute";
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? "") ?? 0;
  }

  List<_CoachReviewItem> _coachReviewItems() {
    final reviews = progress["coach_reviews_by_day"];

    if (reviews is! Iterable) {
      return const [];
    }

    final items = <_CoachReviewItem>[];

    for (final review in reviews) {
      if (review is! Map) {
        continue;
      }

      final status = review["status"];
      final scoreValue = review["score"];
      final feedback = review["feedback"]?.toString().trim();

      items.add(
        _CoachReviewItem(
          dayNumber: _toInt(review["day_number"]),
          statusLabel: _reviewStatusLabel(status),
          statusColor: _reviewStatusColor(status),
          score: scoreValue == null ? null : _toInt(scoreValue),
          feedback: feedback?.isNotEmpty == true
              ? feedback!
              : "Tidak ada catatan tambahan.",
          reviewedAtLabel: _formatDate(review["reviewed_at"]?.toString()),
        ),
      );
    }

    return items;
  }

  Color _reviewStatusColor(dynamic value) {
    final text = value?.toString().trim().toLowerCase();

    if (text == "approved") {
      return AppColors.success;
    }

    if (text == "needs_revision" || text == "rejected") {
      return AppColors.primary;
    }

    return AppColors.lavender;
  }

  List<_ConsistencyChartItem> _consistencyChartItems() {
    final chart = progress["chart"];

    if (chart is! Iterable) {
      return const [];
    }

    return chart.map((item) {
      if (item is! Map) {
        return const _ConsistencyChartItem(label: "-", activityCount: 0);
      }

      final activityCount = _toInt(
        item["activity_count"] ??
            item["recorded_sessions"] ??
            item["completed_workouts"] ??
            item["sets"],
      );

      return _ConsistencyChartItem(
        label: _dayLabel(item["label"]?.toString()),
        activityCount: activityCount,
      );
    }).toList(growable: false);
  }

  String _dayLabel(String? value) {
    final label = value?.trim();

    return switch (label) {
      "Mon" => "Mon",
      "Tue" => "Tue",
      "Wed" => "Wed",
      "Thu" => "Thu",
      "Fri" => "Fri",
      "Sat" => "Sat",
      "Sun" => "Sun",
      _ => label?.isNotEmpty == true ? label! : "-",
    };
  }
}

class _CoachReviewTile extends StatelessWidget {
  const _CoachReviewTile({required this.review});

  final _CoachReviewItem review;

  @override
  Widget build(BuildContext context) {
    final scoreText = review.score == null ? "-" : "${review.score}%";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: review.statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "D${review.dayNumber}",
              style: TextStyle(
                color: review.statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Day ${review.dayNumber}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      scoreText,
                      style: TextStyle(
                        color: review.statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallPill(
                      label: review.statusLabel,
                      color: review.statusColor,
                    ),
                    _SmallPill(
                      label: review.reviewedAtLabel,
                      color: AppColors.lavender,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  review.feedback,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CoachReviewItem {
  const _CoachReviewItem({
    required this.dayNumber,
    required this.statusLabel,
    required this.statusColor,
    required this.score,
    required this.feedback,
    required this.reviewedAtLabel,
  });

  final int dayNumber;
  final String statusLabel;
  final Color statusColor;
  final int? score;
  final String feedback;
  final String reviewedAtLabel;
}

class _ConsistencyChartCard extends StatelessWidget {
  const _ConsistencyChartCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.chartItems,
    required this.details,
  });

  final String title;
  final String subtitle;
  final int value;
  final Color color;
  final List<_ConsistencyChartItem> chartItems;
  final List<_DetailItem> details;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "$safeValue%",
                    style: TextStyle(
                      color: color,
                      fontSize: compact ? 34 : 46,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _WeeklyConsistencyChart(
                items: chartItems,
                color: color,
                compact: compact,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: details
                    .map((item) => _DetailChip(item: item))
                    .toList(growable: false),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeeklyConsistencyChart extends StatelessWidget {
  const _WeeklyConsistencyChart({
    required this.items,
    required this.color,
    required this.compact,
  });

  final List<_ConsistencyChartItem> items;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.isEmpty ? _emptyItems : items;
    final maxActivity = visibleItems.fold<int>(
      1,
      (max, item) => item.activityCount > max ? item.activityCount : max,
    );

    return Container(
      height: compact ? 170 : 210,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: visibleItems
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ConsistencyBar(
                    item: item,
                    maxActivity: maxActivity,
                    color: color,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  static const _emptyItems = [
    _ConsistencyChartItem(label: "Mon", activityCount: 0),
    _ConsistencyChartItem(label: "Tue", activityCount: 0),
    _ConsistencyChartItem(label: "Wed", activityCount: 0),
    _ConsistencyChartItem(label: "Thu", activityCount: 0),
    _ConsistencyChartItem(label: "Fri", activityCount: 0),
    _ConsistencyChartItem(label: "Sat", activityCount: 0),
    _ConsistencyChartItem(label: "Sun", activityCount: 0),
  ];
}

class _ConsistencyBar extends StatelessWidget {
  const _ConsistencyBar({
    required this.item,
    required this.maxActivity,
    required this.color,
  });

  final _ConsistencyChartItem item;
  final int maxActivity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasActivity = item.activityCount > 0;
    final heightFactor = hasActivity
        ? (item.activityCount / maxActivity).clamp(0.18, 1.0)
        : 0.05;

    return Column(
      children: [
        SizedBox(
          height: 24,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.activityCount.toString(),
              style: TextStyle(
                color: hasActivity ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              widthFactor: 0.72,
              heightFactor: heightFactor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hasActivity ? color : Colors.white24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                    bottom: Radius.circular(3),
                  ),
                  boxShadow: hasActivity
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 18,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsistencyChartItem {
  const _ConsistencyChartItem({
    required this.label,
    required this.activityCount,
  });

  final String label;
  final int activityCount;
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.details,
  });

  final String title;
  final String subtitle;
  final int value;
  final IconData icon;
  final Color color;
  final List<_DetailItem> details;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0, 100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: safeValue / 100,
                      strokeWidth: 9,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                    Icon(icon, color: color, size: 34),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "$safeValue%",
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 34 : 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: safeValue / 100,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: details
                    .map((item) => _DetailChip(item: item))
                    .toList(growable: false),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailItem {
  const _DetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.item});

  final _DetailItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
