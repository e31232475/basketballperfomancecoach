import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/glass_panel.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EliteBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
            child: Column(
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BPC',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 56,
                        height: 0.9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.lavender,
                      ),
                    ),
                    Spacer(),
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'EST. 2024',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    color: AppColors.panelSoft.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.lavender.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.lavender.withValues(alpha: 0.22),
                            width: 2,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.sports_basketball_rounded,
                        color: AppColors.lavender,
                        size: 88,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 42),
                const Text(
                  'UNLEASH ELITE\nMOMENTUM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 36,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Precision coaching. Pro-grade analytics. Your digital high-tech training facility.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Row(
                  children: const [
                    Expanded(
                      child: _SplashMetric(
                        label: 'PEAK SPEED',
                        value: '18.4 mph',
                        icon: Icons.bolt_rounded,
                        color: AppColors.lavenderSoft,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SplashMetric(
                        label: 'TARGET',
                        value: '38.5 in',
                        icon: Icons.adjust_rounded,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('GET STARTED'),
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: AppColors.orange,
                    disabledForegroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SIGN IN TO EXISTING PROFILE',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashMetric extends StatelessWidget {
  const _SplashMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
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
