import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/routes/app_router.dart';
import 'app/themes/app_theme.dart';
import 'core/services/hive_service.dart';
import 'core/services/theme_controller.dart';
import 'core/services/currency_service.dart';
import 'core/services/error_service.dart';

/// Main entry point for the Invoice App
/// 
/// A modern, minimalistic invoice management application with:
/// - Clean iOS-style design
/// - Client management
/// - Manual invoice creation
/// - Multi-currency support
/// - PDF generation
Future<void> main() async {
  // Initialize Flutter binding first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize global error handling
  ErrorService.instance.initialize();

  try {
    // Initialize Hive database
    await HiveService.instance.init();

    // Initialize Google Mobile Ads
    await MobileAds.instance.initialize();

    runApp(const ProviderScope(child: MyApp()));
  } catch (error, stackTrace) {
    ErrorService.handleError(
      error,
      stackTrace,
      context: 'App initialization',
      fatal: true,
    );
    
    // Run a minimal error app if main app fails to initialize
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${error.toString()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final appThemeMode = ref.watch(themeControllerProvider);
    final themeMode = appThemeMode == AppThemeMode.dark
        ? ThemeMode.dark
        : appThemeMode == AppThemeMode.light
            ? ThemeMode.light
            : ThemeMode.system;

    // Initialize currency service in background
    ref.watch(currencyServiceProvider).initialize();

    return MaterialApp.router(
      title: 'BillExpert',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
 
