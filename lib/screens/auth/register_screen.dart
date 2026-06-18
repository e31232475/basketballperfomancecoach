import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../utils/auth_validators.dart';
import '../../widgets/auth_widgets.dart';
import 'login_screen.dart';
import 'personalization_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    nameController.addListener(_clearErrorOnChange);
    emailController.addListener(_clearErrorOnChange);
    passwordController.addListener(_clearErrorOnChange);
    confirmPasswordController.addListener(_clearErrorOnChange);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    nameController.removeListener(_clearErrorOnChange);
    emailController.removeListener(_clearErrorOnChange);
    passwordController.removeListener(_clearErrorOnChange);
    confirmPasswordController.removeListener(_clearErrorOnChange);
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showError("Check the highlighted fields and try again");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await AuthService.register(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      passwordConfirmation: confirmPasswordController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });

    if (result["success"] == true) {
      showAuthSnackBar(
        context,
        "Account created successfully",
        success: true,
      );

      final user = result["user"];
      final userData = user is Map<String, dynamic>
          ? user
          : user is Map
              ? Map<String, dynamic>.from(user)
              : <String, dynamic>{};

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PersonalizationScreen(initialData: userData),
        ),
      );
      return;
    }

    _showError(result["message"]?.toString() ?? "Register failed");
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AuthScreenShell(
          title: "Create Account",
          subtitle: "Daftar dengan Gmail agar sesi latihan tersimpan aman.",
          footer: TextButton(
            onPressed: isLoading
                ? null
                : () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                      return;
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
            child: const Text(
              "SUDAH PUNYA AKUN? LOGIN",
              style: TextStyle(
                color: AppColors.lavender,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          children: [
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  AuthErrorCard(message: errorMessage),
                  AuthTextField(
                    controller: nameController,
                    label: "Full Name",
                    hint: "Athlete name",
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      return AuthValidators.requiredField(value, "Full name");
                    },
                  ),
                  const SizedBox(height: 18),
                  AuthTextField(
                    controller: emailController,
                    label: "Gmail Address",
                    hint: "user@gmail.com",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      return AuthValidators.gmail(
                        value,
                        message: "Please use a valid Gmail address",
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  AuthTextField(
                    controller: passwordController,
                    label: "Password",
                    hint: "Min. 8 chars, letters and numbers",
                    icon: Icons.lock_outline,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.password,
                    suffix: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AuthTextField(
                    controller: confirmPasswordController,
                    label: "Confirm Password",
                    hint: "Repeat your password",
                    icon: Icons.verified_user_outlined,
                    obscureText: obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      return AuthValidators.confirmPassword(
                        value,
                        passwordController.text,
                      );
                    },
                    suffix: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  AuthPrimaryButton(
                    label: "REGISTER",
                    icon: Icons.person_add_alt_1_rounded,
                    isLoading: isLoading,
                    onPressed: register,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
    });

    showAuthSnackBar(context, message);
  }

  void _clearErrorOnChange() {
    if (errorMessage == null) {
      return;
    }

    setState(() {
      errorMessage = null;
    });
  }
}
