import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/personalization_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final result = await AuthService.getUser();
    final firebaseUser = FirebaseAuthService().currentUser;

    if (!mounted) {
      return;
    }

    setState(() {
      userData = result["success"] == true
          ? result["data"]
          : firebaseUser == null
              ? null
              : {
                  "name": firebaseUser.displayName,
                  "email": firebaseUser.email,
                };
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ATHLETE PROFILE",
          style: TextStyle(
            color: AppColors.lavender,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadUser,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            children: [
              _buildProfilePanel(),
              const SizedBox(height: 22),
              _buildMenuTile(
                icon: Icons.edit_outlined,
                title: "Edit Profile",
                color: AppColors.primary,
                onTap: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonalizationScreen(
                        initialData: userData,
                        showBackButton: true,
                      ),
                    ),
                  );

                  if (updated == true) {
                    await loadUser();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMenuTile(
                icon: Icons.flag_outlined,
                title: "Training Goals",
                color: AppColors.secondary,
              ),
              const SizedBox(height: 12),
              _buildMenuTile(
                icon: Icons.analytics_outlined,
                title: "Performance Analytics",
                color: AppColors.lavender,
              ),
              const SizedBox(height: 12),
              _buildMenuTile(
                icon: Icons.settings_outlined,
                title: "Settings",
                color: Colors.white70,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService.logout();
                    await FirebaseAuthService().logout();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "LOGOUT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AppColors.panelSoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              Icons.person,
              size: 62,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            userData?["name"]?.toString() ?? "-",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            userData?["email"]?.toString() ?? "-",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  title: "HEIGHT",
                  value: _valueWithUnit("height", "cm"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStat(
                  title: "WEIGHT",
                  value: _valueWithUnit("weight", "kg"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStat(
                  title: "AGE",
                  value: userData?["age"]?.toString() ?? "-",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.lavender,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(color: color),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _valueWithUnit(String key, String unit) {
    final value = userData?[key];

    if (value == null || value.toString().isEmpty) {
      return "-";
    }

    return "$value $unit";
  }
}
