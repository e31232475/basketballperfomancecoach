import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_navbar.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({
    super.key,
    this.initialData,
    this.showBackButton = false,
  });

  final Map<String, dynamic>? initialData;
  final bool showBackButton;

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  final nameController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final ageController = TextEditingController();

  String selectedLevel = "Beginner";
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    if (data != null) {
      nameController.text = data["name"]?.toString() ?? "";
      heightController.text = data["height"]?.toString() ?? "";
      weightController.text = data["weight"]?.toString() ?? "";
      ageController.text = data["age"]?.toString() ?? "";
      selectedLevel = _normalizeLevel(data["training_level"]) ?? "Beginner";
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final height = double.tryParse(heightController.text.trim());
    final weight = double.tryParse(weightController.text.trim());
    final age = int.tryParse(ageController.text.trim());

    if (name.isEmpty || height == null || weight == null || age == null) {
      _showMessage("Nama, tinggi, berat badan, dan umur wajib diisi");
      return;
    }

    setState(() {
      isSaving = true;
    });

    final result = await AuthService.savePersonalization(
      name: name,
      height: height,
      weight: weight,
      age: age,
      trainingLevel: selectedLevel,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });

    if (result["success"] != true) {
      _showMessage(result["message"]?.toString() ?? "Gagal menyimpan");
      return;
    }

    if (widget.showBackButton) {
      Navigator.pop(context, true);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const BottomNavbar(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: widget.showBackButton,
        title: const Text(
          "BPC ELITE",
          style: TextStyle(
            color: AppColors.lavender,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildInput(
                controller: nameController,
                label: "Name",
                hint: "Masukkan nama atlet",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: heightController,
                label: "Height",
                hint: "Contoh: 175",
                icon: Icons.height,
                keyboardType: TextInputType.number,
                suffixText: "cm",
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: weightController,
                label: "Weight",
                hint: "Contoh: 70",
                icon: Icons.monitor_weight_outlined,
                keyboardType: TextInputType.number,
                suffixText: "kg",
              ),
              const SizedBox(height: 16),
              _buildInput(
                controller: ageController,
                label: "Age",
                hint: "Contoh: 18",
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                suffixText: "years",
              ),
              const SizedBox(height: 26),
              const Text(
                "ABILITY LEVEL",
                style: TextStyle(
                  color: AppColors.lavender,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              _buildLevelCard(
                title: "Beginner",
                subtitle: "Recommended for foundation, control, and basics.",
                icon: Icons.flag_outlined,
              ),
              const SizedBox(height: 12),
              _buildLevelCard(
                title: "Intermediate",
                subtitle:
                    "Recommended for stronger intensity and progressions.",
                icon: Icons.bolt_outlined,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text(
                    "SAVE PERSONALIZATION",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.7),
              ),
            ),
            child: const Text(
              "ATHLETE SETUP",
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Personalize Your Training",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Your selected level keeps the Workout menu focused, while other levels stay available as previews on Home.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.lavender,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: AppColors.secondary,
            ),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = selectedLevel == title;
    final accent = selected ? AppColors.primary : Colors.white24;

    return InkWell(
      onTap: () {
        setState(() {
          selectedLevel = title;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.panelSoft : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: selected ? 0.16 : 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: accent),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.primary : Colors.white54,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? AppColors.primary : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.primary : Colors.white30,
            ),
          ],
        ),
      ),
    );
  }

  String? _normalizeLevel(dynamic value) {
    final text = value?.toString().toLowerCase();

    if (text == "intermediate") {
      return "Intermediate";
    }

    if (text == "beginner") {
      return "Beginner";
    }

    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
