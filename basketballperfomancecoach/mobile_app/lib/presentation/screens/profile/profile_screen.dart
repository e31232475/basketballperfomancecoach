import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/glass_panel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      context.read<ProgressProvider>().load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final progress = context.watch<ProgressProvider>().summary;

    return Scaffold(
      appBar: const BpcTopBar(compact: true),
      body: EliteBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            final progressProvider = context.read<ProgressProvider>();
            await auth.refreshProfile();
            final userId = auth.user?.id;
            if (userId != null) {
              await progressProvider.load(userId);
            }
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              GlassPanel(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.panelSoft,
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'Athlete',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.athleteInfo.profileLabel ?? 'Basketball Athlete',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.28,
                children: [
                  MetricTile(
                    label: 'Height',
                    value: user?.height == null
                        ? '-'
                        : '${user!.height!.round()} cm',
                    icon: Icons.height_rounded,
                  ),
                  MetricTile(
                    label: 'Weight',
                    value: user?.weight == null
                        ? '-'
                        : '${user!.weight!.round()} kg',
                    icon: Icons.monitor_weight_outlined,
                  ),
                  MetricTile(
                    label: 'Age',
                    value: user?.age?.toString() ?? '-',
                    icon: Icons.calendar_today_rounded,
                  ),
                  MetricTile(
                    label: 'Training level',
                    value: user?.trainingLevel ?? '-',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: 'Athlete Stats'),
                    const SizedBox(height: 14),
                    _InfoLine(
                      label: 'BMI',
                      value: user?.athleteInfo.bmi?.toStringAsFixed(1) ?? '-',
                    ),
                    _InfoLine(
                      label: 'Athlete info',
                      value: user?.athleteInfo.bmiCategory ?? '-',
                    ),
                    _InfoLine(
                      label: 'Completed workouts',
                      value: '${progress.completedWorkoutTotal}',
                    ),
                    _InfoLine(
                      label: 'Performance score',
                      value: '${progress.performanceScore}',
                    ),
                    _InfoLine(
                      label: 'Current streak',
                      value: '${progress.currentStreak} days',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Logout',
                icon: Icons.logout_rounded,
                isLoading: auth.isLoading,
                onPressed: auth.logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
