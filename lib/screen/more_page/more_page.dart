// ignore_for_file: deprecated_member_use

import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_event.dart';
import 'package:hyper_local_seller/screen/auth/bloc/auth/auth_state.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/widgets/custom_section.dart';
import 'package:hyper_local_seller/service/external_link.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/utils/user_helper.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/bloc/language/language_bloc.dart';
import 'package:hyper_local_seller/bloc/theme/theme_cubit.dart';
import 'package:hyper_local_seller/widgets/custom/custom_selection_sheet.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/service/master_api_service.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileFetchEvent());
  }

  List<SettingsSectionData> _getSections(BuildContext context) {
    final l10n = context;
    final themeCubit = context.read<ThemeCubit>();
    final screenType = context.screenType;

    return [
      SettingsSectionData(
        title: l10n?.tr('userPreference') ?? 'User Preference',
        tiles: [
          SettingsTileData(
            img: ImagesPath.productSvg,
            title: l10n?.tr('theme') ?? 'Theme',
            subtitle: l10n?.tr('selectTheme') ?? 'Select your preferred theme',
            onTap: () {
              CustomSelectionSheet.show<ThemeMode>(
                context: context,
                title: l10n?.tr('selectTheme') ?? 'Select Theme',
                selectedValue: themeCubit.state,
                items: [
                  SelectionItem(
                    label: l10n?.tr('systemDefault') ?? 'System Default',
                    sublabel: l10n?.tr('systemMessage') ?? 'Matches your device settings',
                    value: ThemeMode.system,
                    icon: Icons.brightness_auto,
                  ),
                  SelectionItem(
                    label: l10n?.tr('light') ?? 'Light',
                    sublabel: l10n?.tr('lightMessage') ?? 'Classic bright theme',
                    value: ThemeMode.light,
                    icon: Icons.light_mode,
                  ),
                  SelectionItem(
                    label: l10n?.tr('dark') ?? 'Dark',
                    sublabel: l10n?.tr('darkMessage') ?? 'Gentle on eyes in low light',
                    value: ThemeMode.dark,
                    icon: Icons.dark_mode,
                  ),
                ],
                onSelected: (mode) => themeCubit.updateTheme(mode),
              );
            },
          ),
          SettingsTileData(
            img: ImagesPath.languageSvg,
            title: l10n.tr('language', fallback: 'Language'),
            subtitle: l10n.tr('selectYourPreferredLanguage', fallback: "Select your preferred language"),
            onTap: () {
              final langState = context.read<LanguageBloc>().state;
              final currentCode = langState is LanguageLoaded ? langState.currentLanguage : HiveStorage.languageCode;
              final dynamicLanguages = langState is LanguageLoaded ? (langState.languageModel.data?.languages ?? []) : [];

              final List<SelectionItem<String>> items = dynamicLanguages.isNotEmpty
                  ? dynamicLanguages.map((l) {
                      final code = l.code ?? '';
                      final name = (l.nativeName != null && l.nativeName!.isNotEmpty) ? l.nativeName! : (l.name ?? code);
                      final sub = l.name ?? '';
                      return SelectionItem<String>(
                        label: name,
                        sublabel: sub != name ? sub : null,
                        value: code,
                        leadingText: code.toUpperCase(),
                      );
                    }).toList()
                  : [
                      SelectionItem(label: context.tr('english', fallback: 'English'), sublabel: 'English', value: 'en', leadingText: 'EN'),
                      SelectionItem(label: context.tr('hindi', fallback: 'Hindi'), sublabel: 'हिंदी', value: 'hi', leadingText: 'HI'),
                      SelectionItem(label: context.tr('arabic', fallback: 'Arabic'), sublabel: 'العربية', value: 'ar', leadingText: 'AR'),
                    ];

              CustomSelectionSheet.show<String>(
                context: context,
                title: l10n.tr('selectLanguage', fallback: 'Select Language'),
                selectedValue: currentCode,
                items: items,
                onSelected: (code) {
                  context.read<LanguageBloc>().add(ChangeLanguage(code));
                  context.read<LanguageListBloc>().add(FetchLanguageList(locale: code));
                },
              );
            },
            onLongPress: () async {
              HapticFeedback.heavyImpact(); // Gives a strong vibration
              final isEnabled = await HiveStorage.toggleHttpInspector(); // Toggles the state in Hive

              // Shows a toast confirming the action
              if (context.mounted) {
                showCustomSnackbar(
                  context: context,
                  message: isEnabled ? "Secret HTTP Inspector Enabled" : "Secret HTTP Inspector Disabled",
                );
              }
            },
          ),
          if (HiveStorage.isWatchAndBuyEnabled)
            SettingsTileData(
              img: ImagesPath.watchAndBuySvg,
              title: HiveStorage.watchAndBuyTitle.isNotEmpty
                  ? HiveStorage.watchAndBuyTitle
                  : (l10n?.tr('watchAndBuyProfile') ?? 'Watch & Buy Profile'),
              subtitle: HiveStorage.watchAndBuySubtitle.isNotEmpty
                  ? HiveStorage.watchAndBuySubtitle
                  : (l10n?.tr('watchAndBuyProfileSubtitle') ?? 'Manage your Watch & Buy profile'),
              onTap: () {
                final hasProfileView = PermissionChecker.hasPermission(AppPermissions.watchBuyProfileView);

                if (!hasProfileView) {
                  showCustomSnackbar(
                    context: context,
                    message:
                        l10n?.tr('noPermissionViewWatchBuyProfile') ??
                        'You do not have permission to view Watch & Buy profile.',
                    isWarning: true,
                  );
                  return;
                }
                context.pushNamed(AppRoutes.watchAndBuyProfile);
              },
            ),
        ],
      ),
      SettingsSectionData(
        title: l10n?.tr('storeManagement') ?? "Store Management",
        tiles: [
          SettingsTileData(
            icon: Icons.more_vert,
            img: ImagesPath.productSvg,
            title: l10n?.tr('manageProduct') ?? "Manage Product",
            subtitle: l10n?.tr('manageProductSubtitle') ?? "Add, edit, and organize products",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.productView) &&
                  !PermissionChecker.hasPermission(AppPermissions.productAddonView) &&
                  !PermissionChecker.hasPermission(AppPermissions.storeAddonItemView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewProducts') ?? 'You do not have permission to view products.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('Manage Product button pressed');

              _showBrandSelection(context, screenType);
              // context.pushNamed(AppRoutes.productsFull);
            },
          ),

          SettingsTileData(
            img: ImagesPath.inventory,
            title: l10n?.tr('storeAddonInventory') ?? "Store Add on Inventory",
            subtitle: l10n?.tr('storeAddonInventorySubtitle') ?? "Add, edit, and organize Store Add on inventory",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.storeAddonItemView)) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.tr('noPermissionViewStoreAddonItem') ??
                      'You do not have permission to view store addon inventory.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('Manage Product button pressed');

              context.pushNamed(AppRoutes.storeAddonInventory);
            },
          ),

          SettingsTileData(
            img: ImagesPath.ordersSvg,
            title: l10n?.tr('orders') ?? "Orders",
            subtitle: l10n?.tr('ordersSubtitle') ?? "Manage and track customer orders",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.orderView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewOrders') ?? 'You do not have permission to view orders.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('Manage Product button pressed');
              context.pushNamed(AppRoutes.ordersFull);
            },
          ),
          SettingsTileData(
            img: ImagesPath.storeSvg,
            title: l10n?.tr('stores') ?? "Stores",
            subtitle: l10n?.tr('storesSubtitle') ?? "Manage multiple stores",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.storeView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewStores') ?? 'You do not have permission to view stores.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('stores button pressed');
              context.pushNamed(AppRoutes.stores);
            },
          ),
          SettingsTileData(
            img: ImagesPath.storeSvg,
            title: l10n?.tr('usePOS') ?? "Use POS",
            subtitle: l10n?.tr('usePOSSubtitle') ?? "Use POS for local store",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.posView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewPOS') ?? 'You do not have permission to access POS.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('POS button pressed');
              ExternalLink.toPosDashboard(context);
            },
          ),
          SettingsTileData(
            img: ImagesPath.categoriesSvg,
            title: l10n?.tr('categories') ?? "Categories",
            subtitle: l10n?.tr('categoriesSubtitle') ?? "Manage product categories",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.categoryView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewCategories') ?? 'You do not have permission to view categories.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('categories button pressed');
              context.pushNamed(AppRoutes.categories);
            },
          ),
          SettingsTileData(
            img: ImagesPath.brandSvg,
            title: l10n?.tr('brands') ?? "Brands",
            subtitle: l10n?.tr('brandsSubtitle') ?? "Add and manage brands",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.brandView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewBrands') ?? 'You do not have permission to view brands.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('brands button pressed');
              context.pushNamed(AppRoutes.brands);
            },
          ),

          SettingsTileData(
            img: ImagesPath.attributesSvg,
            title: l10n?.tr('attributes') ?? "Attributes",
            subtitle: l10n?.tr('attributesSubtitle') ?? "Product attributes",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.attributeView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewAttributes') ?? 'You do not have permission to view attributes.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('attributes button pressed');
              context.pushNamed(AppRoutes.attributes);
            },
          ),
          SettingsTileData(
            img: ImagesPath.faqSvg,
            title: l10n?.tr('productFaqs') ?? "Product FAQs",
            subtitle: l10n?.tr('productFaqSubtitle') ?? 'Manage your product questions & answers',
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.productFaqView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewProductFAQs') ?? 'You do not have permission to view product FAQs.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('Product FAQs button pressed');
              context.pushNamed(AppRoutes.productFaqs);
            },
          ),
          SettingsTileData(
            img: ImagesPath.returnReasonsSvg,
            title: l10n?.tr('returnReasons') ?? "Return Reasons",
            subtitle: l10n?.tr('returnReasonsSubtitle') ?? "Manage your return reasons",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.returnView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewReturns') ?? 'You do not have permission to view return reasons.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('Return Reasons button pressed');
              context.pushNamed(AppRoutes.returnReasons);
            },
          ),
        ],
      ),
      SettingsSectionData(
        title: l10n?.tr('finance') ?? "Finance",
        tiles: [
          SettingsTileData(
            img: ImagesPath.walletSvg,
            title: l10n?.tr('wallet') ?? "Wallet",
            subtitle: l10n?.tr('walletSubtitle') ?? "Seller's wallet balance & transactions",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.walletView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewWallet') ?? 'You do not have permission to view your wallet.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('wallet button pressed');
              context.pushNamed(AppRoutes.wallet);
            },
          ),
          SettingsTileData(
            img: ImagesPath.earningsSvg,
            title: l10n?.tr('earnings') ?? 'Earnings',
            subtitle: l10n?.tr('earningsSubtitle') ?? "View commissions & settlements",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.earningView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewEarnings') ?? 'You do not have permission to view earnings.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('earnings button pressed');
              context.pushNamed(AppRoutes.earnings);
            },
          ),
          SettingsTileData(
            img: ImagesPath.earningsSvg,
            title: l10n?.tr('myCampaigns') ?? 'My Campaigns',
            subtitle: l10n?.tr('myCampaignsSubtitle') ?? "Manage sponsored product campaigns",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.adCampaignView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewAdCampaigns') ?? 'You do not have permission to view ad campaigns.',
                  isWarning: true,
                );
                return;
              }
              context.pushNamed(AppRoutes.campaigns);
            },
          ),
          SettingsTileData(
            img: ImagesPath.taxGroupSvg,
            title: l10n?.tr('taxGroup') ?? "Tax Group",
            subtitle: l10n?.tr('taxGroupSubtitle') ?? "View tax groups",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.taxRateView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewTaxRates') ?? 'You do not have permission to view tax rates.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('tax_group button pressed');
              context.pushNamed(AppRoutes.taxGroup);
            },
          ),
          if (HiveStorage.isSubscriptionAvailable) ...[
            SettingsTileData(
              img: ImagesPath.subscriptionSvg,
              title: l10n?.tr('subscriptionPlansTitle') ?? "Subscription Plans",
              subtitle: l10n?.tr('subscriptionSubtitle') ?? "View subscription plans",
              onTap: () {
                if (!PermissionChecker.hasPermission(AppPermissions.subscriptionView)) {
                  showCustomSnackbar(
                    context: context,
                    message:
                        l10n?.tr('noPermissionViewSubscriptionPlans') ??
                        context.tr('noPermissionViewSubscriptionPlans'),
                    isWarning: true,
                  );
                  return;
                }
                debugPrint('subscription_plans button pressed');
                context.pushNamed(AppRoutes.subscriptionPlans);
              },
            ),
            SettingsTileData(
              img: ImagesPath.mySubscriptionSvg,
              title: context.tr('mySubscription'),
              subtitle: context.tr('viewYourPurchasedSubscriptionPlans'),
              onTap: () {
                if (!PermissionChecker.hasPermission(AppPermissions.subscriptionView)) {
                  showCustomSnackbar(
                    context: context,
                    message:
                        l10n?.tr('noPermissionViewSubscriptionPlans') ??
                        context.tr('noPermissionViewSubscriptionPlans'),
                    isWarning: true,
                  );
                  return;
                }
                debugPrint('my_subscription_plans button pressed');
                context.pushNamed(AppRoutes.subscriptionPlanHistory);
              },
            ),
          ],
        ],
      ),
      SettingsSectionData(
        title: l10n?.tr('legal') ?? 'Legal',
        tiles: [
          SettingsTileData(
            img: ImagesPath.privacyPolicySvg,
            title: l10n?.tr('privacyPolicy') ?? 'Privacy Policy',
            subtitle: l10n?.tr('readPrivacyPolicy') ?? 'Read our privacy policy',
            onTap: () {
              debugPrint('privacy_policy button pressed');
              context.pushNamed(AppRoutes.privacyPolicy);
            },
          ),
          SettingsTileData(
            img: ImagesPath.termsAndConditionsSvg,
            title: l10n?.tr('termsAndConditions') ?? 'Terms & Condition',
            subtitle: l10n?.tr('readTermsAndConditions') ?? 'Read our terms and conditions',
            onTap: () {
              debugPrint('terms_condition button pressed');
              context.pushNamed(AppRoutes.termsCondition);
            },
          ),
        ],
      ),
      SettingsSectionData(
        title: l10n?.tr('accountAndUsers') ?? 'Account & Users',
        tiles: [
          SettingsTileData(
            img: ImagesPath.rolesAndPermissionSvg,
            title: l10n?.tr('rolesAndPermissions') ?? 'Roles & Permissions',
            subtitle: l10n?.tr('rolesAndPermissionsSubtitle') ?? "User access control",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.roleView)) {
                showCustomSnackbar(
                  context: context,
                  message:
                      l10n?.tr('noPermissionViewRolesAndPermissions') ??
                      'You do not have permission to view roles and permissions.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('roles_permission button pressed');
              context.pushNamed(AppRoutes.rolesAndPermission);
            },
          ),
          SettingsTileData(
            img: ImagesPath.systemUsersSvg,
            title: l10n?.tr('systemUsers') ?? "System Users",
            subtitle: l10n?.tr('systemUsersSubtitle') ?? "Team members",
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.systemUserView)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionViewSystemUsers') ?? 'You do not have permission to view system users.',
                  isWarning: true,
                );
                return;
              }
              debugPrint('system_users button pressed');
              context.pushNamed(AppRoutes.systemUsers);
            },
          ),
          SettingsTileData(
            img: ImagesPath.logoutSvg,
            title: l10n?.tr('logout') ?? "Logout",
            color: AppColors.errorColor,
            onTap: () {
              showAppAlertDialog(
                context: context,
                title: l10n?.tr('logoutConfirmationTitle') ?? "Logout",
                message: l10n?.tr('logoutConfirmationMessage') ?? "Are you sure you want to log out from your account?",
                confirmText: l10n?.tr('logoutConfirmButton') ?? "Yes, Logout",
                cancelText: l10n?.tr('logoutCancelButton') ?? "Cancel",
                isDestructive: true,
                onConfirm: () {
                  // Clear ALL BLoC data FIRST while context is still valid
                  MasterApiService.clearAllApisData(context);
                  // Then trigger the actual logout (clears token & Hive)
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                onCancel: () {
                  debugPrint("Logout cancelled");
                },
              );
            },
          ),

          SettingsTileData(
            img: ImagesPath.deleteAccountSvg,
            title: l10n?.tr('deleteAccount') ?? "Delete Account",
            color: AppColors.errorColor,
            onTap: () {
              if (!PermissionChecker.hasPermission(AppPermissions.sellerDelete)) {
                showCustomSnackbar(
                  context: context,
                  message: l10n?.tr('noPermissionError') ?? 'You do not have permission to perform this action',

                  isWarning: true,
                );
                return;
              }

              showAppAlertDialog(
                context: context,
                title: l10n?.tr('deleteAccount') ?? "Delete Account",
                message:
                    l10n?.tr('deleteAccountDesc') ??
                    "Are you sure you want to permanently delete your account? This action is irreversible",
                customActions: BlocConsumer<AuthBloc, AuthState>(
                  listener: (dialogContext, state) {
                    if (state is ProfileDeleteSuccess) {
                      Navigator.pop(dialogContext); // close dialog
                      showCustomSnackbar(context: context, message: context.tr('deleteMessage'));
                      context.go('/login');
                    } else if (state is AuthFailure) {
                      Navigator.pop(dialogContext); // close dialog
                      showCustomSnackbar(context: context, message: state.error, isError: true);
                    }
                  },
                  builder: (dialogContext, state) {
                    final isLoading = state is AuthLoading;
                    return Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            text: l10n?.tr('logoutCancelButton') ?? "Cancel",
                            onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                          ),
                        ),
                        SizedBox(width: UIUtils.gapMD(context.screenType)),
                        Expanded(
                          child: PrimaryButton(
                            text: l10n?.tr('deleteConfirmation') ?? "Yes, Delete",
                            backgroundColor: AppColors.errorColor,
                            foregroundColor: Colors.white,
                            isLoading: isLoading,
                            onPressed: isLoading
                                ? null
                                : () {
                                    MasterApiService.clearAllApisData(context);
                                    context.read<AuthBloc>().add(AuthDeletedRequested());
                                  },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final screenType = context.screenType;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainer;

    return CustomScaffold(
      backgroundColor: bgColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial) {
            showCustomSnackbar(context: context, message: l10n?.tr('logoutMessage') ?? 'Logout successful');
            context.go('/login');
          } else if (state is AuthFailure) {
            showCustomSnackbar(context: context, message: state.error, isError: true);
          }
        },
        child: Column(
          children: [
            // This stays at the top (Sticky) and sizes itself dynamically!
            _buildProfileAppBar(context, screenType),

            // The rest of the content scrolls below it
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._getSections(context).map((section) {
                      if (section.tiles.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return SettingsSection(sectionTitle: section.title, tiles: section.tiles);
                    }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAppBar(BuildContext context, ScreenType screenType) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.primaryColor),
      child: SafeArea(
        bottom: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              // Determine the display data
              String name = UserHelper.name;
              String email = UserHelper.email;
              String mobile = UserHelper.mobile;
              String profileImage = UserHelper.profileImage;

              if (state is ProfileLoaded && state.profile.data != null) {
                name = state.profile.data!.name ?? name;
                email = state.profile.data!.email ?? email;
                mobile = state.profile.data!.mobile ?? mobile;
                profileImage = state.profile.data!.profileImage ?? profileImage;
              } else if (state is ProfileUpdateSuccess && state.updatedProfile.data != null) {
                name = state.updatedProfile.data!.name ?? name;
                email = state.updatedProfile.data!.email ?? email;
                mobile = state.updatedProfile.data!.mobile ?? mobile;
                profileImage = state.updatedProfile.data!.profileImage ?? profileImage;
              } else if (state is ProfileUpdating && state.currentProfile?.data != null) {
                // While upgrading, keep showing old data if available in state
                name = state.currentProfile!.data!.name ?? name;
                email = state.currentProfile!.data!.email ?? email;
                mobile = state.currentProfile!.data!.mobile ?? mobile;
                profileImage = state.currentProfile!.data!.profileImage ?? profileImage;
              }

              return Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pushNamed(AppRoutes.profilePage),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CustomNetworkImage(
                        imageUrl: profileImage,
                        width: UIUtils.profileAvatarRadius(screenType) * 1.75,
                        height: UIUtils.profileAvatarRadius(screenType) * 2,
                        isCircle: true,
                        fit: BoxFit.cover,
                        errorWidget: Icon(Icons.person, size: UIUtils.profileIconSize(screenType), color: Colors.grey),
                      ),
                    ),
                  ),
                  SizedBox(width: UIUtils.gapMD(screenType)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: UIUtils.appTitle(screenType),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: UIUtils.body(screenType),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mobile,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: UIUtils.body(screenType),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      debugPrint('Edit Profile button pressed');
                      context.pushNamed(AppRoutes.profilePage);
                    },
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      TablerIcons.edit,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: UIUtils.appBarIcon(screenType),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBrandSelection(BuildContext context, screenType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildManageProductBottomSheet(context, screenType),
    );
  }

  List<SettingsTileData> _getManageProductList(BuildContext context) {
    final l10n = context;

    return [
      SettingsTileData(
        isMoreMenuItemColor: true,
        img: ImagesPath.addIconSvg,
        title: l10n?.tr('manageProduct') ?? "Manage Product",
        // subtitle: l10n?.tr('manageProductSubtitle') ?? "Add, edit, and organize products",
        onTap: () {
          if (!PermissionChecker.hasPermission(AppPermissions.productView)) {
            showCustomSnackbar(
              context: context,
              message: l10n?.tr('noPermissionViewProducts') ?? 'You do not have permission to view products.',
              isWarning: true,
            );
            return;
          }
          context.pushNamed(AppRoutes.productsFull);
        },
      ),
      SettingsTileData(
        isMoreMenuItemColor: true,
        img: ImagesPath.addIconSvg,
        title: l10n?.tr('addOnGroup') ?? "Add-on Groups",
        // subtitle: l10n?.tr('manageProductSubtitle') ?? "Add, edit, and organize products",
        onTap: () {
          if (!PermissionChecker.hasPermission(AppPermissions.addonGroupView)) {
            showCustomSnackbar(
              context: context,
              message: l10n?.tr('noPermissionError') ?? 'You do not have permission to access this.',
              isWarning: true,
            );
            return;
          }
          context.pushNamed(AppRoutes.addOnGroup);
        },
      ),
      SettingsTileData(
        isMoreMenuItemColor: true,
        img: ImagesPath.addIconSvg,
        title: l10n?.tr('productAdsON') ?? "Products Add-ons",
        // subtitle: l10n?.tr('manageProductSubtitle') ?? "Add, edit, and organize products",
        onTap: () {
          if (!PermissionChecker.hasPermission(AppPermissions.productAddonView)) {
            showCustomSnackbar(
              context: context,
              message: l10n?.tr('noPermissionError') ?? 'You do not have permission to access this.',
              isWarning: true,
            );
            return;
          }
          context.pushNamed(AppRoutes.productAddOn);
        },
      ),
    ];
  }

  Widget _buildManageProductBottomSheet(BuildContext context, screenType) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(UIUtils.radiusLG(screenType))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._getManageProductList(context).map((section) {
            return SettingsTile(
              isMoreMenuItemColor: section.isMoreMenuItemColor,
              color: section.color,
              img: section.img,
              title: section.title,
              subtitle: section.subtitle,
              onTap: section.onTap,
            );
          }),
        ],
      ),
    );
  }
}
