import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'views/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any uncaught Flutter errors and print them (prevents silent blank screens)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exceptionAsString()}');
  };

  // Pre-load Google Fonts safely — if offline, falls back to system font
  try {
    await GoogleFonts.pendingFonts([
      GoogleFonts.tinos(),
    ]);
  } catch (e) {
    debugPrint('GoogleFonts preload failed (using system fallback): $e');
  }

  // Set system UI overlay style to clean dark icons on surgical light background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: SentinelWardApp(),
    ),
  );
}

/// Root Application widget for SENTINEL-Ward.
class SentinelWardApp extends StatelessWidget {
  const SentinelWardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SENTINEL-Ward Vitals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OnboardingScreen(),
    );
  }
}
