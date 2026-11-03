import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/bloc/onboarding/onboarding_cubit.dart';
import 'package:hyper_local_seller/bloc/onboarding/onboarding_state.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/splash_screen/model/onboarding_model.dart';
import 'package:hyper_local_seller/screen/splash_screen/widgets/onboarding_background_widget.dart';
import 'package:hyper_local_seller/screen/splash_screen/widgets/onboarding_design_helpers.dart';
import 'package:hyper_local_seller/screen/splash_screen/widgets/onboarding_media_widget.dart';
import 'package:hyper_local_seller/utils/image_path.dart';

class IntroSlider extends StatefulWidget {
  const IntroSlider({super.key});

  @override
  State<IntroSlider> createState() => _IntroSliderState();
}

class _IntroSliderState extends State<IntroSlider> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  List<OnboardingScreenItem> _getFallbackPages(BuildContext context) {
    return [
      OnboardingScreenItem(
        id: -1,
        title: context.tr('growYourStoreOnline', fallback: 'Grow Your Store Online'),
        subtitle: '',
        media: ImagesPath.introSlider1,
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -2,
        title: context.tr('manageOrdersSeamlessly', fallback: 'Manage Orders Seamlessly'),
        subtitle: '',
        media: ImagesPath.introSlider2,
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
      OnboardingScreenItem(
        id: -3,
        title: context.tr('trackEarningsGetPaid', fallback: 'Track Earnings & Get Paid'),
        subtitle: '',
        media: ImagesPath.introSlider3,
        mediaType: 'svg',
        mediaMimeType: 'image/svg+xml',
        isFallback: true,
      ),
    ];
  }

  Future<void> _completeOnboarding() async {
    const bool isDemoMode = AppConstants.isDemoMode;
    if (!isDemoMode) {
      await HiveStorage.setIsFirstTime(false);
    }
    if (mounted) {
      if (!AppConstants.hasValidBaseUrl) {
        showCustomSnackbar(context: context, message: 'user not found');
        context.go(AppRoutes.splashScreen);
        return;
      }
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        List<OnboardingScreenItem> onboardingPages;

        if (state is OnboardingLoaded && state.screens.isNotEmpty) {
          onboardingPages = state.screens;
        } else {
          final cubitScreens = context.read<OnboardingCubit>().currentScreens;
          onboardingPages = cubitScreens.isNotEmpty
              ? cubitScreens
              : _getFallbackPages(context);
        }

        final totalCount = onboardingPages.length;
        final currentScreen = (currentPage < totalCount)
            ? onboardingPages[currentPage]
            : (onboardingPages.isNotEmpty ? onboardingPages.first : null);
        final currentDesign = currentScreen?.design ?? OnboardingDesign.defaultDesign();

        return Scaffold(
          backgroundColor: HexColorHelper.parse(
            currentDesign.background.color,
            fallback: Colors.white,
          ),
          body: Stack(
            children: [
              // 1. Full-screen PageView: each slide renders background + overlay + content
              PageView.builder(
                controller: _pageController,
                itemCount: totalCount,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPageContainer(onboardingPages[index], index);
                },
              ),

              // 2. Top bar (Skip button) floating with dynamic contrast color
              SafeArea(
                child: _buildTopBar(totalCount, currentDesign),
              ),

              // 3. Floating bottom controls: Indicators + Dynamic Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: _buildBottomControls(totalCount, currentDesign),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageContainer(OnboardingScreenItem data, int index) {
    final overlay = data.design.overlay;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base background layer: Video, GIF, Image, Gradient, or Solid + Backdrop Scrim
        OnboardingBackgroundWidget(
          design: data.design,
          isActive: currentPage == index,
        ),

        // 2. Foreground content with SafeArea (Title & Subtitle anchored at bottom)
        SafeArea(
          child: _buildPage(data, index),
        ),

        // 3. Overlay Image placed on TOP OF STACK (True Overlay)
        if (overlay != null &&
            overlay.enabled &&
            (overlay.isImage || overlay.image.trim().isNotEmpty))
          OnboardingOverlayImageWidget(overlay: overlay),
      ],
    );
  }

  Widget _buildTopBar(int totalCount, OnboardingDesign design) {
    final bgLuminance = HexColorHelper.estimateBackgroundLuminance(design.background, design.overlay);
    Color skipColor = HexColorHelper.parse(design.button.backgroundColor, fallback: AppColors.primaryColor);

    if (bgLuminance < 0.4 && skipColor.computeLuminance() < 0.35) {
      skipColor = Colors.white;
    } else if (bgLuminance > 0.65 && skipColor.computeLuminance() > 0.65) {
      skipColor = const Color(0xFF1F2937);
    }

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, right: 16),
        child: Visibility(
          visible: currentPage < totalCount - 1,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: TextButton(
            onPressed: _completeOnboarding,
            child: Text(
              context.tr('skip'),
              style: TextStyle(
                color: skipColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(int totalCount, OnboardingDesign design) {
    final buttonBg = HexColorHelper.parse(
      design.button.backgroundColor,
      fallback: AppColors.primaryColor,
    );
    final buttonFg = HexColorHelper.parse(
      design.button.foregroundColor,
      fallback: Colors.white,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots indicator
          if (totalCount > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalCount,
                (index) => _buildIndicator(index, design),
              ),
            ),

          const SizedBox(height: 22),

          // Next / Get Started dynamic button
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            width: double.infinity,
            height: 54,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: buttonBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: buttonBg.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (currentPage >= totalCount - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Center(
                    child: Text(
                      currentPage >= totalCount - 1
                          ? context.tr('getStarted')
                          : context.tr('next'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: buttonFg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index, OnboardingDesign design) {
    final activeColor = HexColorHelper.parse(
      design.indicator.activeColor,
      fallback: AppColors.primaryColor,
    );
    final inactiveColor = HexColorHelper.parse(
      design.indicator.inactiveColor,
      fallback: const Color(0xFFDBE2EA),
    );
    final bool isActive = currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage(OnboardingScreenItem page, int index) {
    final hasMedia = page.media.trim().isNotEmpty;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final titleColor = HexColorHelper.parse(
      page.design.text.titleColor,
      fallback: isDark ? Colors.white : const Color(0xFF111827),
    );
    final subtitleColor = HexColorHelper.parse(
      page.design.text.subtitleColor,
      fallback: isDark ? Colors.white70 : const Color(0xFF6B7280),
    );
    final textAlign = DesignMapper.mapTextAlign(page.design.text.alignment);
    final crossAxisAlignment = DesignMapper.mapCrossAxisAlignment(page.design.text.alignment);

    return Column(
      children: [
        // Top clearance for skip button
        const SizedBox(height: 54),

        // Upper media stage: takes all space above the text
        Expanded(
          child: hasMedia
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final maxAvail = constraints.maxHeight;
                    final mediaHeight = (maxAvail * 0.88).clamp(80.0, 340.0).clamp(0.0, maxAvail);

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: OnboardingMediaWidget(
                          screen: page,
                          isActive: currentPage == index,
                          height: mediaHeight,
                        ),
                      ),
                    );
                  },
                )
              : const SizedBox.expand(),
        ),

        // Content zone: Anchored firmly at the bottom, directly above the dot indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _buildTextContent(
            page,
            textAlign,
            crossAxisAlignment,
            titleColor,
            subtitleColor,
          ),
        ),

        // Exact clearance directly above the floating bottom controls (Indicators + Button)
        const SizedBox(height: 124),
      ],
    );
  }

  Widget _buildTextContent(
    OnboardingScreenItem page,
    TextAlign textAlign,
    CrossAxisAlignment crossAxisAlignment,
    Color titleColor,
    Color subtitleColor,
  ) {
    final hasTitle = page.title.trim().isNotEmpty;
    final hasSubtitle = page.subtitle.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (hasTitle)
            SizedBox(
              width: double.infinity,
              child: Text(
                page.title,
                textAlign: textAlign,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  height: 1.25,
                ),
              ),
            ),
          if (hasSubtitle) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Text(
                page.subtitle,
                textAlign: textAlign,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
