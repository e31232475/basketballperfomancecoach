import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

import '../screens/home/home_screen.dart';
import '../screens/notifications/notification_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/workout/workout_list_screen.dart';
import '../services/notification_service.dart';

class BottomNavbar extends StatefulWidget {
  const BottomNavbar({super.key});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  int unreadNotificationCount = 0;
  bool hasLoadedNotificationCount = false;
  Timer? notificationTimer;
  final notificationScreenKey = GlobalKey<NotificationScreenState>();

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pages = [
      const HomeScreen(),
      const WorkoutListScreen(),
      const ProgressScreen(),
      const ProfileScreen(),
      NotificationScreen(
        key: notificationScreenKey,
        onNotificationsChanged: _refreshNotificationCount,
      ),
    ];
    _refreshNotificationCount();
    notificationTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshNotificationCount(announceNew: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotificationCount(announceNew: true);
    }
  }

  Future<void> _refreshNotificationCount({bool announceNew = false}) async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (!mounted) return;

      final hasNewNotification = hasLoadedNotificationCount &&
          announceNew &&
          count > unreadNotificationCount;

      setState(() {
        unreadNotificationCount = count;
        hasLoadedNotificationCount = true;
      });

      if (hasNewNotification) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Review dan feedback baru dari coach.'),
              action: SnackBarAction(
                label: 'BUKA',
                onPressed: () {
                  if (!mounted) return;
                  setState(() => currentIndex = 4);
                  notificationScreenKey.currentState?.refresh();
                },
              ),
            ),
          );
      }
    } catch (_) {
      // Polling badge tidak boleh mengganggu penggunaan aplikasi saat offline.
    }
  }

  Widget _notificationIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_rounded),
        if (unreadNotificationCount > 0)
          Positioned(
            top: -7,
            right: -10,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.appBar, width: 1.5),
              ),
              child: Text(
                unreadNotificationCount > 99
                    ? '99+'
                    : unreadNotificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    notificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.appBar,
          border: Border(
            top: BorderSide(color: Colors.white10),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() {
                currentIndex = index;
              });
              if (index == 4) {
                _refreshNotificationCount();
                notificationScreenKey.currentState?.refresh();
              }
            },
            backgroundColor: AppColors.appBar,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.white54,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: "Home",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center),
                label: "Workout",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.show_chart),
                label: "Progress",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
              BottomNavigationBarItem(
                icon: _notificationIcon(),
                label: "Notifikasi",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
