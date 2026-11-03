import 'dart:developer';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/splash_screen/model/onboarding_model.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/utils/image_path.dart';

class OnboardingRepository {
  final ApiBaseHelper _apiBaseHelper;
  final BaseCacheManager _cacheManager;

  OnboardingRepository({
    ApiBaseHelper? apiBaseHelper,
    BaseCacheManager? cacheManager,
  })  : _apiBaseHelper = apiBaseHelper ?? ApiBaseHelper(),
        _cacheManager = cacheManager ?? DefaultCacheManager();

  /// Default fallback screens matching existing hardcoded onboarding
  static List<OnboardingScreenItem> getDefaultScreens() {
    return [
      OnboardingScreenItem(
        id: -1,
        title: 'Grow Your Store Online',
        subtitle: '',
        media: ImagesPath.introSlider1,
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -2,
        title: 'Manage Orders Seamlessly',
        subtitle: '',
        media: ImagesPath.introSlider2,
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -3,
        title: 'Track Earnings & Get Paid',
        subtitle: '',
        media: ImagesPath.introSlider3,
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
    ];
  }

  /// Get cached configuration from Hive
  OnboardingConfig? getCachedConfig() {
    try {
      final cachedJson = HiveStorage.cachedOnboardingConfig;
      if (cachedJson != null) {
        return OnboardingConfig.fromJson(cachedJson);
      }
    } catch (e) {
      log('[Onboarding] Error reading cached onboarding config: $e');
    }
    return null;
  }

  /// Fetch onboarding configuration from remote API
  Future<OnboardingConfig?> fetchFromApi() async {
    log('[Onboarding] API request started for app=seller');
    try {
      final response = await _apiBaseHelper.get(
        ApiRoutes.onboardingScreensApi,
        queryParameters: {'app': 'seller'},
      );

      if (response is Map<String, dynamic>) {
        final onboardingResponse = OnboardingResponse.fromJson(response);
        if (onboardingResponse.data != null) {
          log('[Onboarding] API succeeded. is_enabled: ${onboardingResponse.data!.isEnabled}, screens count: ${onboardingResponse.data!.screens.length}');
          return onboardingResponse.data;
        }
      }
      log('[Onboarding] API response did not contain expected data structure');
      return null;
    } catch (e) {
      log('[Onboarding] API request failed with error: $e');
      rethrow;
    }
  }

  /// Compare incoming API config with cached config and perform smart cache invalidation & persistence
  Future<void> syncCache(OnboardingConfig newConfig) async {
    try {
      final oldConfig = getCachedConfig();
      if (oldConfig != null) {
        // Find screens removed or modified
        final newScreenMap = {for (var s in newConfig.screens) s.id: s};
        for (final oldScreen in oldConfig.screens) {
          final newScreen = newScreenMap[oldScreen.id];
          if (newScreen == null) {
            // Screen was removed -> remove cached file if present
            if (oldScreen.isNetworkMedia) {
              await _cacheManager.removeFile(oldScreen.media);
              log('[Onboarding] Evicted cached media for removed screen id ${oldScreen.id}');
            }
          } else if (newScreen.media != oldScreen.media) {
            // Media URL changed -> remove old cached file
            if (oldScreen.isNetworkMedia) {
              await _cacheManager.removeFile(oldScreen.media);
              log('[Onboarding] Evicted old cached media for modified screen id ${oldScreen.id}');
            }
          }
        }
      }

      // Persist the new configuration to Hive
      await HiveStorage.saveCachedOnboardingConfig(newConfig.toJson());
      log('[Onboarding] Cached configuration updated successfully.');

      // Warm up cache for non-video network media in background
      _warmupCache(newConfig.screens);
    } catch (e) {
      log('[Onboarding] Error during syncCache: $e');
    }
  }

  void _warmupCache(List<OnboardingScreenItem> screens) {
    for (final screen in screens) {
      if (screen.isNetworkMedia && !screen.isVideo && !screen.isTxt) {
        _cacheManager.downloadFile(screen.media).catchError((err) {
          log('[Onboarding] Pre-cache failed for ${screen.media}: $err');
          return null as dynamic;
        });
      }
    }
  }
}
