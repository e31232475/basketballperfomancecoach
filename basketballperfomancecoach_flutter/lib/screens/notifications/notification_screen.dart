import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/athlete_notification.dart';
import '../../services/notification_service.dart';
import '../progress/progress_screen.dart';

class NotificationScreen extends StatefulWidget {
  final VoidCallback? onNotificationsChanged;

  const NotificationScreen({
    super.key,
    this.onNotificationsChanged,
  });

  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen> {
  List<AthleteNotification> notifications = [];
  bool isLoading = true;
  bool isUpdating = false;
  String? errorMessage;

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final inbox = await NotificationService.getNotifications();
      if (!mounted) return;

      setState(() {
        notifications = inbox.notifications;
        isLoading = false;
        errorMessage = null;
      });
      widget.onNotificationsChanged?.call();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = _cleanError(error);
      });
    }
  }

  Future<void> refresh() => _loadNotifications(showLoader: false);

  Future<void> _openNotification(AthleteNotification notification) async {
    if (!notification.isRead) {
      try {
        await NotificationService.markAsRead(notification.id);
        if (!mounted) return;

        setState(() {
          notifications = notifications
              .map(
                (item) => item.id == notification.id
                    ? item.copyWith(isRead: true, readAt: DateTime.now())
                    : item,
              )
              .toList();
        });
        widget.onNotificationsChanged?.call();
      } catch (error) {
        if (!mounted) return;
        _showMessage(_cleanError(error));
        return;
      }
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationDetailSheet(
        notification: notification.copyWith(isRead: true),
        onOpenProgress: () {
          Navigator.pop(context);
          Navigator.push(
            this.context,
            MaterialPageRoute(builder: (_) => const ProgressScreen()),
          );
        },
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    if (unreadCount == 0 || isUpdating) return;

    setState(() => isUpdating = true);
    try {
      await NotificationService.markAllAsRead();
      if (!mounted) return;

      setState(() {
        notifications = notifications
            .map(
              (notification) => notification.copyWith(
                isRead: true,
                readAt: DateTime.now(),
              ),
            )
            .toList();
        isUpdating = false;
      });
      widget.onNotificationsChanged?.call();
    } catch (error) {
      if (!mounted) return;
      setState(() => isUpdating = false);
      _showMessage(_cleanError(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
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
          'NOTIFIKASI',
          style: TextStyle(
            color: AppColors.lavender,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: isUpdating ? null : _markAllAsRead,
              child: Text(
                isUpdating ? 'MEMPROSES' : 'BACA SEMUA',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 130),
            const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.primary,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 18),
            Center(
              child: ElevatedButton(
                onPressed: _loadNotifications,
                child: const Text('Coba lagi'),
              ),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 130),
            Icon(
              Icons.notifications_none_rounded,
              color: AppColors.lavender,
              size: 62,
            ),
            SizedBox(height: 16),
            Text(
              'Belum ada notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hasil review dan feedback baru dari coach akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.45),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _loadNotifications(showLoader: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _NotificationCard(
            notification: notification,
            onTap: () => _openNotification(notification),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AthleteNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final needsRevision = notification.status == 'needs_revision' ||
        notification.status == 'rejected';
    final accent = needsRevision ? AppColors.primary : AppColors.success;

    return Material(
      color: notification.isRead
          ? AppColors.card
          : AppColors.panelSoft.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.white10
                  : accent.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  needsRevision ? Icons.replay_rounded : Icons.verified_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (notification.dayNumber != null)
                          _MiniChip(label: 'Day ${notification.dayNumber}'),
                        if (notification.statusLabel != null)
                          _MiniChip(
                            label: notification.statusLabel!,
                            color: accent,
                          ),
                        if (notification.score != null)
                          _MiniChip(label: 'Score ${notification.score}%'),
                        _MiniChip(label: _formatDate(notification.createdAt)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final AthleteNotification notification;
  final VoidCallback onOpenProgress;

  const _NotificationDetailSheet({
    required this.notification,
    required this.onOpenProgress,
  });

  @override
  Widget build(BuildContext context) {
    final needsRevision = notification.status == 'needs_revision' ||
        notification.status == 'rejected';
    final accent = needsRevision ? AppColors.primary : AppColors.success;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review_rounded, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white60),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (notification.dayNumber != null)
                  _MiniChip(label: 'Day ${notification.dayNumber}'),
                if (notification.statusLabel != null)
                  _MiniChip(label: notification.statusLabel!, color: accent),
                if (notification.score != null)
                  _MiniChip(label: 'Score ${notification.score}%'),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'FEEDBACK COACH',
              style: TextStyle(
                color: AppColors.lavender,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notification.feedback?.trim().isNotEmpty == true
                  ? notification.feedback!
                  : 'Tidak ada feedback tambahan.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpenProgress,
                icon: const Icon(Icons.show_chart_rounded),
                label: const Text('BUKA PROGRESS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _MiniChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.lavender;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  final date = value?.toLocal();
  if (date == null) return '-';

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
