import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
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
  final imagePicker = ImagePicker();

  String selectedGender = "male";
  String? currentProfilePhotoUrl;
  Uint8List? selectedPhotoBytes;
  String? selectedPhotoName;
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
      selectedGender =
          data["gender"]?.toString() == "female" ? "female" : "male";
      currentProfilePhotoUrl = data["profile_photo_url"]?.toString();
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

  Future<void> _pickPhoto() async {
    try {
      final picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (picked == null || !mounted) {
        return;
      }

      final bytes = await picked.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        selectedPhotoBytes = bytes;
        selectedPhotoName =
            picked.name.isEmpty ? "profile-photo.jpg" : picked.name;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage("Foto belum bisa dipilih");
    }
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
      gender: selectedGender,
      profilePhotoBytes: selectedPhotoBytes,
      profilePhotoFileName: selectedPhotoName,
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
              _buildPhotoPicker(),
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
              const SizedBox(height: 16),
              _buildGenderSelector(),
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
            "Personalize Your Profile",
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
            "Lengkapi data profil atlet. Akses level hanya dapat diberikan oleh coach dari web coach.",
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

  Widget _buildPhotoPicker() {
    final currentUrl = currentProfilePhotoUrl?.trim();
    final hasCurrentPhoto = currentUrl != null && currentUrl.isNotEmpty;
    ImageProvider? photoProvider;

    if (selectedPhotoBytes != null) {
      photoProvider = MemoryImage(selectedPhotoBytes!);
    } else if (hasCurrentPhoto) {
      photoProvider =
          NetworkImage(ApiConfig.normalizeBackendAssetUrl(currentUrl));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          _buildPhotoPreview(
            photoBytes: selectedPhotoBytes,
            photoUrl: hasCurrentPhoto
                ? ApiConfig.normalizeBackendAssetUrl(currentUrl)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "FOTO PROFIL",
                  style: TextStyle(
                    color: AppColors.lavender,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedPhotoBytes != null
                      ? "Foto baru siap disimpan"
                      : hasCurrentPhoto
                          ? "Foto profil sudah tersimpan"
                          : "Belum ada foto profil",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _pickPhoto,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    photoProvider == null
                        ? "Tambah foto profil"
                        : "Ganti foto profil",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview({
    Uint8List? photoBytes,
    String? photoUrl,
  }) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Center(
            child: Icon(
              Icons.person,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          if (photoBytes != null)
            Image.memory(
              photoBytes,
              fit: BoxFit.cover,
            )
          else if (photoUrl != null)
            Image.network(
              photoUrl,
              fit: BoxFit.cover,
              webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "JENIS KELAMIN",
          style: TextStyle(
            color: AppColors.lavender,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedGender,
          dropdownColor: AppColors.card,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          decoration: const InputDecoration(
            prefixIcon: Icon(
              Icons.wc_outlined,
              color: AppColors.secondary,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: "male",
              child: Text("Laki-laki"),
            ),
            DropdownMenuItem(
              value: "female",
              child: Text("Perempuan"),
            ),
          ],
          onChanged: isSaving
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedGender = value;
                  });
                },
        ),
      ],
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
