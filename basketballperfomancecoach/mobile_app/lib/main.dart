import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/session_storage.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/providers/workout_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/personalization/personalization_screen.dart';
import 'presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  final apiClient = ApiClient(baseUrl: baseUrl);
  final sessionStorage = SessionStorage();
  final authRepository = AuthRepository(apiClient, sessionStorage);
  final workoutRepository = WorkoutRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository)..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (_) => WorkoutProvider(workoutRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProgressProvider(workoutRepository),
        ),
      ],
      child: const BasketballPerformanceCoachApp(),
    ),
  );
}

class BasketballPerformanceCoachApp extends StatelessWidget {
  const BasketballPerformanceCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basketball Performance Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isBootstrapping) {
            return const SplashScreen();
          }

          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }

          final user = auth.user;
          if (user == null || !user.isPersonalized) {
            return const PersonalizationScreen();
          }

          return const MainShell();
        },
      ),
    );
  }
}
