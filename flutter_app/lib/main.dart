import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_service.dart';
import 'utils/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
  runApp(const FixoraApp());
}

Future<void> _initFirebase() async {
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options.apiKey.startsWith('YOUR_')) {
      debugPrint('Firebase not configured - running in local-only mode.');
      return;
    }
    await Firebase.initializeApp(options: options);
    FirebaseService.instance.enable();
  } catch (e) {
    debugPrint('Firebase init failed - running in local-only mode: $e');
  }
}

class FixoraApp extends StatelessWidget {
  const FixoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppConstants.primaryColor),
        appBarTheme: const AppBarTheme(centerTitle: true),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
