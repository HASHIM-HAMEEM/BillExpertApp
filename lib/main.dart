import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/routes/app_router.dart';
import 'app/themes/app_theme.dart';
import 'core/services/hive_service.dart';
import 'core/services/theme_controller.dart';

/// Main entry point for the Invoice App
/// 
/// A modern, minimalistic invoice management application with:
/// - Clean iOS-style design
/// - Client management
/// - Manual invoice creation
/// - Multi-currency support
/// - PDF generation
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.instance.init();
  runApp(const ProviderScope(child: MyApp()));
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
    return MaterialApp.router(
      title: 'Invoice Generator',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
 
