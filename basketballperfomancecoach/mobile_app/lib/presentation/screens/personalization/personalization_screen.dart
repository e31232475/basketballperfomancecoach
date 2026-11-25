import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/glass_panel.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key, this.isEditing = false});

  final bool isEditing;

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _selectedPhoto;
  String? _currentProfilePhotoUrl;
  bool _removeProfilePhoto = false;
  String _gender = 'male';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? '';
    _heightController.text = user?.height?.round().toString() ?? '';
    _weightController.text = user?.weight?.round().toString() ?? '';
    _ageController.text = user?.age?.toString() ?? '';
    _gender = user?.gender == 'female' ? 'female' : 'male';
    _currentProfilePhotoUrl = user?.profilePhotoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: BpcTopBar(
        compact: true,
        showBack: widget.isEditing,
        trailing: widget.isEditing
            ? const SizedBox(width: 48)
            : IconButton(
                tooltip: 'Logout',
                onPressed: auth.isLoading ? null : auth.logout,
                icon: const Icon(Icons.logout_rounded),
              ),
      ),
      body: EliteBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
            children: [
              Text(
                widget.isEditing ? 'EDIT\nPROFILE' : 'ATHLETE\nPROFILE SETUP',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 36,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isEditing
                    ? 'Update your profile details for coach monitoring.'
                    : 'Calibrate your biometric baseline before the Beginner program starts.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              GlassPanel(
                borderColor: AppColors.lavenderSoft,
                glowColor: AppColors.orange,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _buildPhotoPicker(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Height cm',
                                prefixIcon: Icon(Icons.height_rounded),
                              ),
                              validator: _number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Weight kg',
                                prefixIcon: Icon(Icons.monitor_weight_outlined),
                              ),
                              validator: _number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                        validator: _number,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kelamin',
                          prefixIcon: Icon(Icons.wc_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'male',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _gender = value);
                          }
                        },
                      ),
                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          auth.errorMessage!,
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ],
                      const SizedBox(height: 18),
                      AppButton(
                        label: 'Save Profile',
                        icon: Icons.check_circle_outline_rounded,
                        isLoading: auth.isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _number(String? value) {
    final parsed = num.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Invalid';
    }
    return null;
  }

  Widget _buildPhotoPicker() {
    final image = _profilePhotoImage();
    final currentUrl = _currentProfilePhotoUrl?.trim();
    final hasCurrentPhoto = currentUrl != null && currentUrl.isNotEmpty;
    final showSecondaryAction = _selectedPhoto != null || hasCurrentPhoto;
    final secondaryLabel = _selectedPhoto != null
        ? 'Batal pilih'
        : (_removeProfilePhoto ? 'Batal hapus' : 'Hapus foto');
    final note = _selectedPhoto != null
        ? 'Foto baru siap diupload.'
        : (_removeProfilePhoto
              ? 'Foto akan dihapus saat profil disimpan.'
              : (hasCurrentPhoto
                    ? 'Foto tersimpan akan tampil di app dan web coach.'
                    : 'Belum ada foto profil.'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.74),
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.panelSoft,
                backgroundImage: image,
                child: image == null
                    ? const Icon(
                        Icons.person_rounded,
                        size: 42,
                        color: AppColors.orange,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Foto Profil',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _pickProfilePhoto,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(
                  image == null ? 'Tambah foto profil' : 'Ganti foto profil',
                ),
              ),
              if (showSecondaryAction) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _toggleSecondaryPhotoAction,
                  icon: Icon(
                    _removeProfilePhoto
                        ? Icons.undo_rounded
                        : Icons.delete_outline_rounded,
                  ),
                  label: Text(secondaryLabel),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider? _profilePhotoImage() {
    if (_selectedPhoto != null) {
      return FileImage(File(_selectedPhoto!.path));
    }

    final currentUrl = _currentProfilePhotoUrl?.trim();
    if (!_removeProfilePhoto && currentUrl != null && currentUrl.isNotEmpty) {
      return NetworkImage(currentUrl);
    }

    return null;
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (picked == null || !mounted) {
        return;
      }

      setState(() {
        _selectedPhoto = picked;
        _removeProfilePhoto = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto belum bisa dipilih.')));
    }
  }

  void _toggleSecondaryPhotoAction() {
    setState(() {
      if (_selectedPhoto != null) {
        _selectedPhoto = null;
        _removeProfilePhoto = false;
        return;
      }

      _removeProfilePhoto = !_removeProfilePhoto;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await context.read<AuthProvider>().savePersonalization(
      name: _nameController.text.trim(),
      height: double.parse(_heightController.text),
      weight: double.parse(_weightController.text),
      age: int.parse(_ageController.text),
      gender: _gender,
      profilePhotoPath: _selectedPhoto?.path,
      removeProfilePhoto: _selectedPhoto == null && _removeProfilePhoto,
      redirectToProgram: !widget.isEditing,
    );

    if (ok && widget.isEditing && mounted) {
      Navigator.of(context).pop();
    }
  }
}
