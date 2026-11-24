import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../utils/auth_validators.dart';
import '../../widgets/auth_widgets.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
  });

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
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
    emailController.text = widget.initialEmail;
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
    emailController.removeListener(_clearErrorOnChange);
    passwordController.removeListener(_clearErrorOnChange);
    confirmPasswordController.removeListener(_clearErrorOnChange);
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showError("Check the highlighted fields and try again");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await AuthService.forgotPassword(
      email: emailController.text.trim(),
      newPassword: passwordController.text.trim(),
      newPasswordConfirmation: confirmPasswordController.text.trim(),
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
        "Password updated. Please login again",
        success: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 650));

      if (!mounted) {
        return;
      }

      _openLogin();
      return;
    }

    _showError(result["message"]?.toString() ?? "Reset failed");
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AuthScreenShell(
          title: "Reset Password",
          subtitle: "Masukkan Gmail akun dan password baru untuk login ulang.",
          footer: TextButton(
            onPressed: isLoading ? null : _openLogin,
            child: const Text(
              "KEMBALI KE LOGIN",
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
                    controller: emailController,
                    label: "Gmail Address",
                    hint: "user@gmail.com",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: AuthValidators.gmail,
                  ),
                  const SizedBox(height: 18),
                  AuthTextField(
                    controller: passwordController,
                    label: "New Password",
                    hint: "Min. 8 chars, letters and numbers",
                    icon: Icons.lock_reset_rounded,
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
                    label: "Confirm New Password",
                    hint: "Repeat your new password",
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
                    label: "UPDATE PASSWORD",
                    icon: Icons.password_rounded,
                    isLoading: isLoading,
                    onPressed: resetPassword,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLogin() {
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
