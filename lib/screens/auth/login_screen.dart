import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/auth_validators.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/bottom_navbar.dart';
import 'personalization_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool isLoading = false;
  bool isGoogleLoading = false;
  bool obscurePassword = true;
  bool rememberMe = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_clearErrorOnChange);
    passwordController.addListener(_clearErrorOnChange);

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
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      _showError("Check the highlighted fields and try again");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await AuthService.login(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      rememberMe: rememberMe,
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
        "Login successful",
        success: true,
      );

      _openNextScreen(result);
      return;
    }

    _showError(result["message"]?.toString() ?? "Login failed");
  }

  Future<void> loginWithGoogle() async {
    FocusScope.of(context).unfocus();

    setState(() {
      isGoogleLoading = true;
      errorMessage = null;
    });

    try {
      final credential = await FirebaseAuthService().signInWithGoogle();
      final idToken = await credential?.user?.getIdToken();

      if (!mounted) {
        return;
      }

      if (credential?.user == null || idToken == null || idToken.isEmpty) {
        setState(() {
          isGoogleLoading = false;
        });
        _showError("Google login dibatalkan");
        return;
      }

      final result = await AuthService.loginWithFirebase(
        idToken: idToken,
        rememberMe: rememberMe,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isGoogleLoading = false;
      });

      if (result["success"] == true) {
        showAuthSnackBar(
          context,
          "Google login successful",
          success: true,
        );

        _openPersonalizationScreen(result);
        return;
      }

      await FirebaseAuthService().logout();
      _showError(result["message"]?.toString() ?? "Google login failed");
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isGoogleLoading = false;
      });
      _showError(_friendlyGoogleError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AuthScreenShell(
          title: "Welcome Back",
          subtitle: "Masuk dengan Gmail untuk melanjutkan training kamu.",
          footer: TextButton(
            onPressed: isLoading || isGoogleLoading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
            child: const Text(
              "BELUM PUNYA AKUN? REGISTER",
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
                    label: "Password",
                    hint: "Enter your password",
                    icon: Icons.lock_outline,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Password is required";
                      }

                      return null;
                    },
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
                  const SizedBox(height: 12),
                  _buildRememberMe(),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: "LOGIN",
                    icon: Icons.login_rounded,
                    isLoading: isLoading,
                    onPressed: isGoogleLoading ? null : login,
                  ),
                  const SizedBox(height: 16),
                  _buildAuthDivider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed:
                          isLoading || isGoogleLoading ? null : loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.72),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: isGoogleLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: Text(
                        isGoogleLoading
                            ? "PLEASE WAIT"
                            : "LOGIN WITH GOOGLE",
                        style: const TextStyle(
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
          ],
        ),
      ),
    );
  }

  Widget _buildRememberMe() {
    return InkWell(
      onTap: isLoading
          ? null
          : () {
              setState(() {
                rememberMe = !rememberMe;
              });
            },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: isLoading
                  ? null
                  : (value) {
                      setState(() {
                        rememberMe = value ?? true;
                      });
                    },
              activeColor: AppColors.primary,
              checkColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const Text(
              "Remember me",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "OR",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }

  void _openNextScreen(Map<String, dynamic> result) {
    final user = result["user"];
    final userData = user is Map<String, dynamic>
        ? user
        : user is Map
            ? Map<String, dynamic>.from(user)
            : <String, dynamic>{};
    final isPersonalized = result["personalization_completed"] == true ||
        result["is_personalized"] == true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isPersonalized
            ? const BottomNavbar()
            : PersonalizationScreen(initialData: userData),
      ),
    );
  }

  void _openPersonalizationScreen(Map<String, dynamic> result) {
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
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
    });

    showAuthSnackBar(context, message);
  }

  String _friendlyGoogleError(Object error) {
    final text = error.toString();

    if (text.contains('popup-closed-by-user')) {
      return 'Google login dibatalkan';
    }

    if (text.contains('unauthorized-domain')) {
      return 'Domain localhost belum diizinkan di Firebase Auth';
    }

    if (text.contains('operation-not-allowed')) {
      return 'Provider Google belum aktif di Firebase Authentication';
    }

    return text.replaceFirst('Exception: ', '');
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
