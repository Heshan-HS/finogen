import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/security_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/main/presentation/main_layout.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'core/services/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/transaction_category.dart';
import 'firebase_options.dart';
import 'features/accounts/services/mexc_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Release native splash hold immediately so OS transitions swiftly to first frame
  FlutterNativeSplash.remove();

  // Defer non-critical local database initialization to avoid blocking first frame
  Hive.initFlutter().catchError((e) {
    debugPrint('Hive init error: $e');
  });

  // Parallel critical startup futures (Firebase & SharedPreferences)
  final results = await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).catchError((e) {
      debugPrint('Firebase not configured: $e');
      return Firebase.app();
    }),
    SharedPreferences.getInstance(),
  ]);

  final prefs = results[1] as SharedPreferences;
  final isGuest = prefs.getBool('isGuest') ?? false;
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final currentUser = FirebaseAuth.instance.currentUser;

  // Listen to auth state changes to auto-persist login session
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    final p = await SharedPreferences.getInstance();
    if (user != null) {
      await p.setBool('isLoggedIn', true);
    }
  });

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: NovaFinanceApp(
        initialScreen: (currentUser != null || isGuest || isLoggedIn) ? '/main' : '/welcome',
      ),
    ),
  );

  // Background non-blocking tasks that do not delay first frame rendering
  Future.microtask(() {
    CategoryProvider.init();
    NotificationService().init();
    if (currentUser != null) {
      MexcSyncService.syncMexcBalance();
    }
  });
}

class NovaFinanceApp extends ConsumerWidget {
  final String initialScreen;
  const NovaFinanceApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    if ((!kIsWeb && Platform.isWindows) && Firebase.apps.isEmpty) {
      return MaterialApp(
        scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
        title: 'Finogen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                  const SizedBox(height: 24),
                  const Text('Firebase Configuration Required', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('To enable Google Login and Data Sync on Windows Desktop, you must configure Firebase first.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: const Text('1. Open terminal\n2. Run: flutterfire configure\n3. Select your Firebase project\n4. Check the "windows" platform\n5. Restart the app', style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      title: 'Finogen',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: initialScreen,
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/main': (context) => const MainLayout(),
      },
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
