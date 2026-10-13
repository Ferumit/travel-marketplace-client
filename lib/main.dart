import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'navigation/app_router.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/local_profile_service.dart';
import 'services/push_notification_service.dart';
import 'services/sos_service.dart';
import 'services/theme_service.dart';
import 'services/locale_service.dart';
import 'theme/theme.dart';
import 'widgets/global_sos_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: GoogleFonts.config.allowRuntimeFetching is intentionally NOT set to
  // false. The package downloads Manrope on first launch with internet and
  // caches it permanently in the app's support directory. Setting it to false
  // caused an Unhandled Exception crash when the TTF wasn't pre-bundled.

  await dotenv.load(fileName: ".env");

  // Инициализация Firebase (перед любым обращением к Firebase SDK)
  debugPrint('--- [MAIN] Firebase Initializing ---');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('--- [MAIN] Firebase Initialized ---');

  // ── Crashlytics ────────────────────────────────────────────────────────────
  // Отключаем в debug-режиме чтобы краши не засоряли дашборд во время разработки.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

  // 1. Перехват ошибок Flutter-фреймворка (рендеринг, виджеты, жесты)
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // 2. Перехват необработанных async Dart ошибок вне Flutter zone
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // ──────────────────────────────────────────────────────────────────────────

  try {
    debugPrint('--- [MAIN] AppCheck Activating ---');
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    ).timeout(const Duration(seconds: 3));
    debugPrint('--- [MAIN] AppCheck Activated ---');
  } catch (e, stack) {
    debugPrint('--- [MAIN] AppCheck Activation Failed/Timeout: $e ---');
    FirebaseCrashlytics.instance.recordError(e, stack, reason: 'AppCheck activation', fatal: false);
  }

  // Инициализация сервисов
  debugPrint('--- [MAIN] Initializing Services ---');
  await ThemeService.instance.init();
  await LocaleService.instance.init();
  await AuthService.instance.init();
  await LocalProfileService.instance.init(); // cache username before ConnectivityService

  // Инициализация Push-уведомлений
  debugPrint('--- [MAIN] Initializing Push Notifications ---');
  await PushNotificationService.instance.init();

  debugPrint('--- [MAIN] Calling runApp() ---');
  runApp(const ExploraApp());

  // Init connectivity AFTER runApp so the router context is available
  debugPrint('--- [MAIN] Initializing Connectivity ---');
  ConnectivityService.instance.init();

  // Init SosService AFTER connectivity (uses ConnectivityService ChangeNotifier)
  debugPrint('--- [MAIN] Initializing SosService ---');
  SosService.instance.init();
}


class ExploraApp extends StatelessWidget {
  const ExploraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeService.instance, LocaleService.instance]),
      builder: (context, _) {
        return MaterialApp.router(
          title: 'explora',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeService.instance.themeMode,
          locale: LocaleService.instance.locale,
          routerConfig: appRouter,
          builder: (context, child) {
            return GlobalSosListener(child: child!);
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleService.supportedLocales,
        );
      },
    );
  }
}

