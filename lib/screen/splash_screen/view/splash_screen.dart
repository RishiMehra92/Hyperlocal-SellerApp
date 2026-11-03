import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:hyper_local_seller/bloc/settings/settings_cubit.dart';
import 'package:hyper_local_seller/bloc/onboarding/onboarding_cubit.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/widgets/custom/custom_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/service/notification_service.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_limit_service.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/model/splash_model/splash_config_model.dart';
import 'package:hyper_local_seller/service/splash/splash_cache_service.dart';
import 'package:hyper_local_seller/service/splash/splash_repository.dart';

import '../../../utils/app_update/bloc/app_update_bloc.dart';
import '../../../utils/app_update/bloc/app_update_event.dart';
import '../../../utils/app_update/bloc/app_update_state.dart';
import '../../../utils/app_update/model/update_config.dart';
import '../../../utils/app_update/widgets/app_update_dialog.dart';

Color? _getColorFromHex(String? hexString) {
  if (hexString == null || hexString.trim().isEmpty) return null;
  final buffer = StringBuffer();
  String cleanHex = hexString.trim().replaceAll('#', '');
  if (cleanHex.length == 6) buffer.write('ff');
  buffer.write(cleanHex);
  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (_) {
    return null;
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _updateDialogShowing = false;
  SplashItemModel? _activeSplash;
  VideoPlayerController? _bgVideoController;

  @override
  void initState() {
    super.initState();
    _activeSplash = SplashCacheService().getActiveSplash();
    if (_activeSplash != null) {
      debugPrint('[SplashScreen] 🎨 Loaded active splash from cache (Seller): ${_activeSplash!.cacheKey}');
      debugPrint('[SplashScreen]    👉 Background : ${_activeSplash!.background.type} (image: ${_activeSplash!.background.imageUrl}, color: ${_activeSplash!.background.color})');
      debugPrint('[SplashScreen]    👉 Overlay    : enabled=${_activeSplash!.overlay.enabled}, type=${_activeSplash!.overlay.type}, url=${_activeSplash!.overlay.url}');
      debugPrint('[SplashScreen]    👉 Local Paths: bg=${_activeSplash!.localBgPath}, overlay=${_activeSplash!.localOverlayPath}');
    } else {
      debugPrint('[SplashScreen] 🎨 No cached active splash found (Seller). Showing fallback while fetching remote...');
    }
    _initVideoIfApplicable();
    if (!AppConstants.hasValidBaseUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showCustomSnackbar(context: context, message: 'user not found');
        }
      });
      return;
    }
    context.read<AppUpdateBloc>().add(CheckAppUpdate());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 0-1 Mechanism: Fetch and sync assets purely in the background for NEXT launch.
        // Whatever splash screen started on Frame 0 remains locked for this entire session.
        SplashRepository().fetchAndSync();
      }
    });
  }

  void _initVideoIfApplicable() {
    final bg = _activeSplash?.background;
    if (bg != null && bg.isVideo) {
      // 1. Priority A: Local file on disk (Instant Frame-0 initialization, zero network lag)
      final localPath = _activeSplash?.localBgPath;
      if (localPath != null && File(localPath).existsSync()) {
        debugPrint('⚡ [SplashScreen] Initializing video controller from local file: $localPath');
        _bgVideoController = VideoPlayerController.file(File(localPath))
          ..initialize().then((_) {
            if (mounted) {
              _bgVideoController?.setLooping(true);
              _bgVideoController?.setVolume(0);
              _bgVideoController?.play();
              setState(() {});
            }
          }).catchError((e) {
            log('[SplashScreen] Local video init error: $e');
          });
        return;
      }

      // 2. Priority B: Network URL fallback
      if (bg.videoUrl != null && bg.videoUrl!.isNotEmpty) {
        final uri = Uri.tryParse(bg.videoUrl!);
        if (uri != null) {
          debugPrint('🌐 [SplashScreen] Initializing video controller from network: ${bg.videoUrl}');
          _bgVideoController = VideoPlayerController.networkUrl(uri)
            ..initialize().then((_) {
              if (mounted) {
                _bgVideoController?.setLooping(true);
                _bgVideoController?.setVolume(0);
                _bgVideoController?.play();
                setState(() {});
              }
            }).catchError((e) {
              log('[SplashScreen] Video background init error: $e');
            });
        }
      }
    }
  }

  @override
  void dispose() {
    _bgVideoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeAndNavigate() async {
    if (!AppConstants.hasValidBaseUrl) return;
    // Respect minDisplaySeconds from splash config
    final minDisplaySecs = _activeSplash?.minDisplaySeconds ?? 2;
    final splashMinDuration = Future.delayed(
      Duration(seconds: minDisplaySecs),
    );

    // ── Parallel operations ───────────────────────────────────────
    final futures = <Future>[
      // 1. Load & fetch settings (cached + fresh from server)
      _initSettings(),

      // 2. Preload dynamic onboarding config & media
      _initOnboarding(),

      // 3. Just ensure Hive is ready (already opened in main.dart)
      Future.value(),
    ];

    // Wait for minimum splash time + initialization
    await Future.wait([splashMinDuration, ...futures]);

    if (!mounted) return;

    // ── Navigation decision ───────────────────────────────────────
    const bool isDemoMode = AppConstants.isDemoMode;
    final isFirstTime = isDemoMode || HiveStorage.isFirstTime;

    if (isFirstTime) {
      final onboardingCubit = context.read<OnboardingCubit>();
      if (onboardingCubit.shouldShowOnboarding) {
        log('[Onboarding] Showing onboarding screens (isDemoMode: $isDemoMode, isFirstTime: ${HiveStorage.isFirstTime})');
        context.go(AppRoutes.introSlider);
        if (!isDemoMode) {
          await HiveStorage.setIsFirstTime(false);
        }
      } else {
        log('[Onboarding] Onboarding disabled (is_enabled: false) - skipping to login');
        context.go(AppRoutes.login);
        if (!isDemoMode) {
          await HiveStorage.setIsFirstTime(false);
        }
      }
    } else {
      final token = HiveStorage.userToken;
      if (token != null && token.trim().isNotEmpty) {
        // Fetch user profile and store in UserHelper before navigating
        await ProfileBloc.fetchAndStoreProfile();

        // Sync subscription limits
        await SubscriptionLimitService().syncSubscription();

        // Check for pending notifications
        final notificationManager = NotificationManager();
        if (notificationManager.hasPendingNotification) {
          debugPrint('Splash: Handling pending notification');
          // ignore: use_build_context_synchronously
          notificationManager.handlePendingNotification(context);

          // Fallback timer: if the app is still on splash screen after 3 seconds,
          // something likely went wrong with the notification navigation.
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted &&
                GoRouterState.of(context).uri.toString() ==
                    AppRoutes.splashScreen) {
              debugPrint('Splash: Fallback navigation triggered');
              context.go(AppRoutes.home);
            }
          });
        } else {
          if ((HiveStorage.isFirstTimeSubscriptionVisit || kDebugMode) &&
              HiveStorage.isSubscriptionAvailable &&
              (HiveStorage.activePlanId == null ||
                  HiveStorage.activePlanId == 0) &&
              HiveStorage.pendingSubscriptionId == null) {
            debugPrint("Splash: Navigating to subscription choose plan");
            // ignore: use_build_context_synchronously
            context.go(AppRoutes.subscriptionChoosePlan);
          } else {
            // ignore: use_build_context_synchronously
            context.go(AppRoutes.home);
          }
        }
      } else {
        context.go(AppRoutes.login);
      }
    }
  }

  Future<void> _initSettings() async {
    final settingsCubit = context.read<SettingsCubit>();

    // First: immediately use cached values (if exist)
    await settingsCubit.loadCachedSettings();

    // If settings are not in cache (first time or cleared), we must wait for them
    // to ensure the app has critical config like currency/maintenance status.
    final needsFetch = HiveStorage.systemSettings == null;

    try {
      if (needsFetch) {
        debugPrint(
          'First-run or empty cache: fetching settings synchronously...',
        );
        await settingsCubit.fetchAndSaveSettings();
      } else {
        // Non-blocking refresh if we already have cache
        settingsCubit.fetchAndSaveSettings().catchError((e) {
          debugPrint('Settings background refresh failed: $e');
        });
      }
    } catch (e) {
      debugPrint('Settings fetch failed: $e');
      // On first run, a failure here might be problematic, but we continue
      // to avoid blocking the user indefinitely if the server is down.
    }
  }

  Future<void> _initOnboarding() async {
    try {
      await context.read<OnboardingCubit>().preloadOnboarding();
    } catch (e) {
      log('[Onboarding] Preload failed on splash: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _activeSplash != null && _activeSplash!.isValid
          ? Colors.black
          : Theme.of(context).colorScheme.tertiary,
      body: BlocListener<AppUpdateBloc, AppUpdateState>(
        listener: (context, state) {
          log(
            '🔍 SPLASH SCREEN: AppUpdateState listener -> status: ${state.status}',
          );
          if (state.status == AppUpdateStatus.success) {
            if (!state.isUpdateAvailable) {
              log('🔍 SPLASH SCREEN: No update available, navigating...');
              _initializeAndNavigate();
            } else {
              log(
                '🔍 SPLASH SCREEN: Update available (forced: ${state.isForced})',
              );
              final isForced = state.isForced;
              _showUpdateDialog(state.config!, isForced: isForced);
            }
          }

          if (state.status == AppUpdateStatus.failure) {
            log('🔍 SPLASH SCREEN: Update check failed, failing open...');
            _initializeAndNavigate();
          }
        },
        child: _activeSplash != null && _activeSplash!.isValid
            ? _buildDynamicSplash(context, _activeSplash!)
            : _buildFallbackSplash(context),
      ),
    );
  }

  Widget _buildDynamicSplash(BuildContext context, SplashItemModel splash) {
    final bg = splash.background;
    final overlay = splash.overlay;
    final bgColor = _getColorFromHex(bg.color) ?? AppColors.primaryColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── LAYER 1: BASE BACKGROUND ──────────────────────────────────
        Positioned.fill(
          child: _buildBackgroundWidget(context, splash, bgColor),
        ),

        // ── LAYER 2: OVERLAY (Image or Lottie) ────────────────────────
        if (overlay.enabled && overlay.url != null && overlay.url!.trim().isNotEmpty)
          _buildOverlayWidget(context, overlay, splash.localOverlayPath),
      ],
    );
  }

  Widget _buildBackgroundWidget(
    BuildContext context,
    SplashItemModel splash,
    Color bgColor,
  ) {
    final bg = splash.background;

    // 1. Image Background
    if (bg.isImage) {
      // Priority A: Direct local file on disk (Instant Frame 0 render, 0ms latency, zero flash)
      if (splash.localBgPath != null && File(splash.localBgPath!).existsSync()) {
        debugPrint('⚡ [SplashScreen] Rendering background image directly from local disk: ${splash.localBgPath}');
        return Image.file(
          File(splash.localBgPath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Error loading local background image: $error');
            return const SizedBox.expand();
          },
        );
      }

      // Priority B: CachedNetworkImage (Zero fade transition duration, neutral placeholder)
      if (bg.imageUrl != null && bg.imageUrl!.trim().isNotEmpty) {
        final cleanUrl = bg.imageUrl!.trim();
        return CachedNetworkImage(
          imageUrl: cleanUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) {
            debugPrint('⏳ [SplashScreen] Loading background image from cache/network: $url');
            return const SizedBox.expand();
          },
          imageBuilder: (context, imageProvider) {
            debugPrint('✅ [SplashScreen] Background image rendered successfully!');
            return Image(
              image: imageProvider,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
            );
          },
          errorWidget: (context, url, error) {
            debugPrint('❌ [SplashScreen] Background image failed to load: $url | Error: $error');
            return const SizedBox.expand();
          },
        );
      }
      return const SizedBox.expand();
    }

    // 2. Video Background
    if (bg.isVideo) {
      if (_bgVideoController != null && _bgVideoController!.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _bgVideoController!.value.size.width,
            height: _bgVideoController!.value.size.height,
            child: VideoPlayer(_bgVideoController!),
          ),
        );
      }
      // While video is initializing, show neutral widget — NEVER color!
      return const SizedBox.expand();
    }

    // 3. Solid Color Background - EXCLUSIVELY rendered when backend explicitly says type is 'color'
    if (bg.isColor) {
      return Container(color: bgColor);
    }

    return const SizedBox.expand();
  }

  Widget _buildOverlayWidget(
    BuildContext context,
    SplashOverlayModel overlay,
    String? localOverlayPath,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rawWidth = screenWidth * (overlay.position.widthPercent / 100.0);
    final clampedWidth = rawWidth.clamp(80.0, 400.0);
    final cleanUrl = overlay.url!.trim();

    debugPrint('🖼️ [SplashScreen] Rendering overlay ${overlay.type} (url: $cleanUrl, width: $clampedWidth, x: ${overlay.position.xPercent}%, y: ${overlay.position.yPercent}%)');

    Widget overlayContent;

    if (overlay.isLottie) {
      if (localOverlayPath != null && File(localOverlayPath).existsSync()) {
        debugPrint('⚡ [SplashScreen] Rendering overlay Lottie directly from local disk: $localOverlayPath');
        overlayContent = Lottie.file(
          File(localOverlayPath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Overlay Local Lottie failed: $error');
            return const SizedBox();
          },
        );
      } else {
        overlayContent = Lottie.network(
          cleanUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Overlay Lottie failed to load: $cleanUrl | Error: $error');
            return const SizedBox();
          },
        );
      }
    } else {
      if (localOverlayPath != null && File(localOverlayPath).existsSync()) {
        debugPrint('⚡ [SplashScreen] Rendering overlay image directly from local disk: $localOverlayPath');
        overlayContent = Image.file(
          File(localOverlayPath),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ [SplashScreen] Overlay Local Image failed: $error');
            return const SizedBox();
          },
        );
      } else {
        overlayContent = CachedNetworkImage(
          imageUrl: cleanUrl,
          fit: BoxFit.contain,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) {
            debugPrint('⏳ [SplashScreen] Overlay image loading from cache/network: $url');
            return const SizedBox();
          },
          imageBuilder: (context, imageProvider) {
            debugPrint('✅ [SplashScreen] Overlay image rendered successfully: $cleanUrl');
            return Image(image: imageProvider, fit: BoxFit.contain, gaplessPlayback: true);
          },
          errorWidget: (context, url, error) {
            debugPrint('❌ [SplashScreen] Overlay Image failed to load: $url | Error: $error');
            return const SizedBox();
          },
        );
      }
    }

    return Align(
      alignment: FractionalOffset(
        (overlay.position.xPercent / 100.0).clamp(0.0, 1.0),
        (overlay.position.yPercent / 100.0).clamp(0.0, 1.0),
      ),
      child: SizedBox(
        width: clampedWidth,
        child: overlayContent,
      ),
    );
  }

  Widget _buildFallbackSplash(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomSvg(
          svgPath: ImagesPath.doodle,
          fit: BoxFit.cover,
          color: AppColors.primaryColor.withValues(alpha: 0.75),
          blendMode: BlendMode.srcATop,
        ),
        Center(
          child: Image.asset(
            ImagesPath.darkLogo,
            width: 300,
            height: 300,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  void _onForceUpdatePressed() {
    // Dialog stays open; url_launcher opens the store.
    // Nothing to resolve here — navigation stays blocked.
  }
  void _onSoftUpdateLater() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _updateDialogShowing = false;
    _initializeAndNavigate();
  }

  void _showUpdateDialog(UpdateConfig config, {required bool isForced}) {
    if (_updateDialogShowing || !mounted) return;
    _updateDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(
        config: config,
        isForced: isForced,
        onLater: isForced ? _onForceUpdatePressed : _onSoftUpdateLater,
      ),
    );
  }
}
