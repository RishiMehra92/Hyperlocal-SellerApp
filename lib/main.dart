import 'dart:io';
import 'dart:io' as io;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:hyper_local_seller/bloc/settings/settings_cubit.dart';
import 'package:hyper_local_seller/bloc/onboarding/onboarding_cubit.dart';
import 'package:hyper_local_seller/bloc/theme/theme_cubit.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/config/theme.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hyper_local_seller/bloc/language/language_bloc.dart';
import 'package:hyper_local_seller/service/language_repo.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local_seller/screen/auth/repo/auth_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/widgets/subscription_reminder_wrapper.dart';
import 'package:flutter_http_inspector/flutter_http_inspector.dart';

import 'package:hyper_local_seller/service/phone_auth.dart';
import 'package:hyper_local_seller/utils/app_update/bloc/app_update_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hyper_local_seller/service/notification_service.dart';
import 'package:hyper_local_seller/bloc/connectivity/connectivity_cubit.dart';
import 'package:hyper_local_seller/widgets/ui/maintenance_screen.dart';
import 'package:hyper_local_seller/widgets/ui/no_internet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpInspector.setup();

  // Must be registered BEFORE Firebase.initializeApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp();

  await Hive.initFlutter();
  await HiveStorage.initPrefs();
  await LanguageRepo.initCache();
  await NotificationManager().initialize();

  if (kDebugMode) {
    io.HttpClient.enableTimelineLogging = true;
  }

  runApp(
    MultiRepositoryProvider(
      providers: [RepositoryProvider(create: (_) => AuthRepository())],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AppUpdateBloc()),
          BlocProvider(create: (_) => SettingsCubit()),
          BlocProvider(create: (_) => OnboardingCubit()),
          BlocProvider(create: (_) => ConnectivityCubit()),
          BlocProvider(create: (_) => ScreenSizeBloc()),
          BlocProvider(
            create: (_) => LanguageListBloc()
              ..add(FetchLanguageList(locale: HiveStorage.languageCode)),
          ),
          BlocProvider(
            create: (context) => LanguageBloc(
              languageListBloc: context.read<LanguageListBloc>(),
            )..add(const LoadLanguage()),
          ),
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (context) => AuthBloc(context.read<AuthRepository>(), FirebasePhoneAuthService())),
        ],
        child: const AppWrapper(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: SafeArea(
        top: false,
        bottom: Platform.isIOS ? false : true,
        child: BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, langState) {
            final activeLocale = langState is LanguageLoaded
                ? langState.locale
                : Locale(HiveStorage.languageCode);
            final isRtl = langState is LanguageLoaded ? langState.isRtl : false;

            return BlocBuilder<LanguageListBloc, LanguageListState>(
              builder: (context, langListState) {
                return BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    return MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      locale: activeLocale,
                      localizationsDelegates: const [
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                        FlutterQuillLocalizations.delegate,
                      ],
                      supportedLocales: LanguageRepo.supportedLocales,
                      theme: AppTheme.lightTheme,
                      darkTheme: AppTheme.darkTheme,
                      themeMode: themeMode,
                      routerConfig: MyAppRoutes.router,
                      builder: (context, child) {
                        // Initialize/Update screen size in Bloc
                        final size = MediaQuery.of(context).size;
                        context.read<ScreenSizeBloc>().add(ScreenSizeChanged(size));
                        final content = SubscriptionReminderWrapper(child: child!);
                        return Directionality(
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              content,
                              ValueListenableBuilder<bool>(
                                valueListenable: HiveStorage.httpInspectorEnabledNotifier,
                                builder: (context, isEnabled, _) {
                                  if (!isEnabled) return const SizedBox.shrink();
                                  return const HttpInspectorOverlay(enabled: true, child: SizedBox.shrink());
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Wrapper widget that handles connectivity and maintenance mode
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
      builder: (context, connectivityState) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            // Check for maintenance mode
            if (settingsState is SettingsLoaded && settingsState.maintenanceMode) {
              // Show maintenance screen with MaterialApp wrapper for theming
              return _buildMaterialWrapper(context, const MaintenanceScreenWrapper());
            }

            // Check for no internet
            if (connectivityState == ConnectivityStatus.disconnected) {
              return _buildMaterialWrapper(
                context,
                NoInternetScreenWrapper(
                  onRetry: () {
                    context.read<ConnectivityCubit>().checkConnection();
                  },
                ),
              );
            }

            // Normal app
            return const MyApp();
          },
        );
      },
    );
  }

  Widget _buildMaterialWrapper(BuildContext context, Widget child) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, langState) {
        final activeLocale = langState is LanguageLoaded
            ? langState.locale
            : Locale(HiveStorage.languageCode);
        final isRtl = langState is LanguageLoaded ? langState.isRtl : false;

        return BlocBuilder<LanguageListBloc, LanguageListState>(
          builder: (context, langListState) {
            return BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: activeLocale,
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                    FlutterQuillLocalizations.delegate,
                  ],
                  supportedLocales: LanguageRepo.supportedLocales,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  home: Directionality(
                    textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                    child: child,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Wrapper for MaintenanceScreen to access localization
class MaintenanceScreenWrapper extends StatelessWidget {
  const MaintenanceScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final message = settingsState is SettingsLoaded ? settingsState.maintenanceMessage : null;
    return MaintenanceScreen(message: message);
  }
}

/// Wrapper for NoInternetScreen to access localization
class NoInternetScreenWrapper extends StatelessWidget {
  final VoidCallback onRetry;
  const NoInternetScreenWrapper({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return NoInternetScreen(onRetry: onRetry);
  }
}
