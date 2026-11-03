import 'package:hyper_local_seller/config/constant.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/screen/auth/view/forgot_password_page.dart';
import 'package:hyper_local_seller/screen/auth/view/login_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/subscription_history_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/model/subscription_plans_model.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/subscription_plan_details_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/subscription_payment_webview.dart';
import 'package:hyper_local_seller/screen/auth/view/otp_page.dart';
import 'package:hyper_local_seller/screen/auth/view/sign_up_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/choose_plan_page.dart';
import 'package:hyper_local_seller/screen/more_page/more_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/view/attribute_values_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/view/attributes_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/view/brands_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/view/categories_page.dart';
import 'package:hyper_local_seller/screen/dashboard/dashboard.dart';
import 'package:hyper_local_seller/screen/home_page/view/home_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/view/profile_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/view/permission_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/view/roles_and_permissions_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/settings_content_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/watch_and_buy/view/watch_and_buy_profile_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/watch_and_buy/view/watch_and_buy_stories_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/watch_and_buy/view/watch_and_buy_reels_page.dart';

import 'package:hyper_local_seller/screen/more_page/view/stores/view/stores_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/view/add_store_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/view/map_screen.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/view/subscription_plans_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/view/system_users_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/view/transaction_history_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/view/wallet_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/view/withdraw_history_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/view/withdraw_request_page.dart';
import 'package:hyper_local_seller/screen/order_page/view/order_details_page.dart';
import 'package:hyper_local_seller/screen/order_page/view/order_page.dart';
import 'package:hyper_local_seller/screen/returns_page/view/returns_page.dart';
import 'package:hyper_local_seller/screen/returns_page/view/return_details_page.dart';
import 'package:hyper_local_seller/screen/returns_page/cubit/return_details_cubit.dart';
import 'package:hyper_local_seller/screen/returns_page/repo/order_returns_repo.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/view/add_product_page.dart';
import 'package:hyper_local_seller/screen/products_page/products/view/product_details_page.dart';
import 'package:hyper_local_seller/screen/products_page/products/view/products_page.dart';
import 'package:hyper_local_seller/screen/splash_screen/view/splash_screen.dart';
import 'package:hyper_local_seller/screen/splash_screen/widgets/intro_slider.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/view/tax_groups_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/view/earning_page.dart';
import 'package:hyper_local_seller/screen/products_page/products/view/product_faqs_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/view/delivery_zones_page.dart';
import 'package:hyper_local_seller/screen/home_page/view/notification_list_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/return_reasons/view/return_reasons_page.dart';
import 'package:hyper_local_seller/screen/more_page/view/return_reasons/bloc/return_reasons_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/return_reasons/repo/return_reasons_repo.dart';

import '../screen/products_page/add_ons/addon_groups/model/addon_group_model.dart';
import '../screen/products_page/add_ons/addon_groups/view/addon_groups_page.dart';
import '../screen/products_page/add_ons/create_add_on_group/view/create_addon_group_page.dart';
import '../screen/more_page/view/store_addon_inventory/store_addon_list/views/store_addon_inventory_page.dart';
import '../screen/products_page/product_addons/create_product_addons/cubit/create_product_addons_cubit.dart';
import '../screen/products_page/product_addons/product_addons_group/model/product_addons_model.dart';
import '../screen/products_page/product_addons/create_product_addons/view/create_product_addons_page.dart';
import '../screen/products_page/product_addons/product_addons_group/view/product_addon_page.dart';
import '../screen/more_page/view/store_addon_inventory/store_addon_list/cubit/add_store_addon_inventory_cubit.dart';
import '../screen/more_page/view/store_addon_inventory/store_addon_list/views/add_store_addon_inventory_page.dart';
import '../screen/more_page/view/campaigns/view/campaign_list_page.dart';
import '../screen/more_page/view/campaigns/view/create_campaign_page.dart';
import '../screen/more_page/view/campaigns/view/campaign_detail_page.dart';
import '../screen/more_page/view/campaigns/view/campaign_wallet_page.dart';
import '../screen/more_page/view/campaigns/view/campaign_product_select_page.dart';
import '../screen/more_page/view/campaigns/view/campaign_payment_webview.dart';
import '../screen/more_page/view/campaigns/bloc/campaign_product_select_bloc/campaign_product_select_bloc.dart';
import '../screen/more_page/view/campaigns/repo/campaign_repo.dart';
import 'package:hyper_local_seller/router/route_providers.dart';

Page platformPage(GoRouterState state, Widget child) {
  if (Platform.isIOS) {
    return CupertinoPage(key: state.pageKey, child: child);
  } else {
    return MaterialPage(key: state.pageKey, child: child);
  }
}

class AppRoutes {
  static const String splashScreen = '/';
  static const String introSlider = '/intro-slider';
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';
  static const String register = '/register';
  static const String home = '/home';
  static const String orders = '/orders';
  static const String returns = '/returns';
  static const String returnDetails = '/return-details';
  static const String products = '/products';
  static const String productDetails = '/product-details';
  static const String addProduct = '/add-products';
  static const String more = '/more';
  static const String ordersFull = '/orders-full';
  static const String productsFull = '/products-full';
  static const String categories = '/categories';
  static const String brands = '/brands';
  static const String taxGroup = '/tax-group';
  static const String stores = '/stores';
  static const String addStore = '/add-store';
  static const String mapScreen = '/map-screen';
  static const String attributes = '/attributes';
  static const String attributeValues = '/attribute-values';
  static const String orderDetails = '/order-details';
  static const String wallet = '/wallet';
  static const String withdrawRequest = '/withdraw-request';
  static const String withdrawHistory = '/withdraw-history';
  static const String transactionHistory = '/transaction-history';
  static const String earnings = '/earnings';
  static const String productFaqs = '/product-faqs';
  static const String storeConfiguration = '/store-configuration';
  static const String profilePage = '/profile';
  static const String watchAndBuyProfile = '/watch-and-buy-profile';
  static const String watchAndBuyStories = '/watch-and-buy-stories';
  static const String watchAndBuyReels = '/watch-and-buy-reels';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsCondition = '/terms-condition';
  static const String rolesAndPermission = '/roles-permission';
  static const String permissions = '/permissions';
  static const String deliveryZones = '/delivery-zones';
  static const String systemUsers = '/system-users';
  static const String notifications = '/notifications';
  static const String subscriptionPlans = '/subscription-plans';
  static const String subscriptionPlanDetails = '/subscription-plan-details';
  static const String subscriptionPaymentWebView =
      '/subscription-payment-webview';
  static const String subscriptionPlanHistory = '/subscription-plan-history';
  static const String subscriptionChoosePlan = '/subscription-choose-plan';
  static const String addOnGroup = '/add-on-group';
  static const String createAddOnGroup = '/create_add-on-group';
  static const String productAddOn = '/product-add-on';
  static const String createProductAddOn = '/create-product-add-on';
  static const String storeAddonInventory = '/store-addon-inventory';
  static const String createStoreAddonInventory =
      '/create-store-addon-inventory';
  static const String returnReasons = '/return-reasons';

  // campaigns
  static const String campaigns = '/campaigns';
  static const String createCampaign = '/create-campaign';
  static const String campaignDetail = '/campaign-detail';
  static const String campaignWallet = '/campaign-wallet';
  static const String campaignProductSelect = '/campaign-product-select';
  static const String campaignPaymentWebView = '/campaign-payment-webview';
  static const String campaignTopupGateway = '/campaign-topup-gateway';
}

class MyAppRoutes {
  static GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.splashScreen,
    navigatorKey: GlobalKeys.navigatorKey,

    onException: (context, state, router) {
      // Ignore Firebase Auth redirects (reCAPTCHA flow) so we stay on the current page
      if (state.uri.toString().contains('firebaseauth/link')) {
        return;
      }
      // For any other routing errors, go to home or show a simple error
      debugPrint('Routing error: ${state.error}');
      router.go(AppRoutes.splashScreen);
    },
    redirect: (context, state) {
      if (!AppConstants.hasValidBaseUrl) {
        final loc = state.matchedLocation;
        if (loc != AppRoutes.splashScreen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = GlobalKeys.navigatorKey.currentContext;
            if (ctx != null) {
              showCustomSnackbar(context: ctx, message: 'user not found');
            }
          });
          return AppRoutes.splashScreen;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splashScreen,
        name: '/',
        pageBuilder: (context, state) =>
            platformPage(state, const SplashScreen()),
      ),

      GoRoute(
        path: AppRoutes.introSlider,
        name: '/intro-slider',
        pageBuilder: (context, state) =>
            platformPage(state, const IntroSlider()),
      ),
      ShellRoute(
        builder: (context, state, child) => AuthProviders(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.login,
            name: '/login',
            pageBuilder: (context, state) =>
                platformPage(state, const LoginPage()),
          ),
          GoRoute(
            path: AppRoutes.signUp,
            name: '/signup',
            pageBuilder: (context, state) =>
                platformPage(state, const SignUpPage()),
          ),
          GoRoute(
            path: AppRoutes.forgotPassword,
            name: '/forgot-password',
            pageBuilder: (context, state) =>
                platformPage(state, const ForgotPasswordPage()),
          ),
          GoRoute(
            path: AppRoutes.otp,
            name: '/otp',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return platformPage(
                state,
                OtpPage(
                  verificationId: extra?['verificationId'] as String?,
                  phoneNumber: extra?['phoneNumber'] as String?,
                  isSignUp: extra?['isSignUp'] as bool? ?? false,
                  signUpData: extra?['signUpData'] as Map<String, dynamic>?,
                ),
              );
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AuthenticatedProviders(child: child),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return Dashboard(
                index: navigationShell.currentIndex,
                navigationShell: navigationShell,
              );
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.home,
                    name: '/home',
                    pageBuilder: (context, state) =>
                        platformPage(state, const HomePage()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.orders,
                    name: '/order',
                    pageBuilder: (context, state) => platformPage(
                      state,
                      const BackToHomeWrapper(child: OrderPage()),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.products,
                    name: '/products',
                    pageBuilder: (context, state) => platformPage(
                      state,
                      const BackToHomeWrapper(child: ProductsPage()),
                    ),
                  ),
                ],
              ),

              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.returns,
                    name: '/returns',
                    pageBuilder: (context, state) => platformPage(
                      state,
                      const BackToHomeWrapper(child: ReturnsPage()),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.more,
                    name: '/more',
                    pageBuilder: (context, state) => platformPage(
                      state,
                      const BackToHomeWrapper(child: MorePage()),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.addProduct,
            name: '/add-products',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final isEdit = extra?['is_edit'] as bool? ?? false;
              return platformPage(state, AddProductPage(isEdit: isEdit));
            },
          ),
          GoRoute(
            path: AppRoutes.categories,
            name: '/categories',
            pageBuilder: (context, state) {
              final slug = state.uri.queryParameters['slug'];
              return platformPage(state, CategoriesPage(categorySlug: slug));
            },
          ),
          GoRoute(
            path: AppRoutes.brands,
            name: '/brands',
            pageBuilder: (context, state) =>
                platformPage(state, const BrandsPage()),
          ),
          GoRoute(
            path: AppRoutes.taxGroup,
            name: '/tax-group',
            pageBuilder: (context, state) =>
                platformPage(state, const TaxGroupsPage()),
          ),
          GoRoute(
            path: AppRoutes.stores,
            name: '/stores',
            pageBuilder: (context, state) =>
                platformPage(state, const StoresPage()),
          ),
          GoRoute(
            path: AppRoutes.addStore,
            name: '/add-store',
            pageBuilder: (context, state) =>
                platformPage(state, const AddStorePage()),
          ),
          GoRoute(
            path: AppRoutes.mapScreen,
            name: '/map-screen',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return platformPage(
                state,
                MapScreen(
                  initialLatitude: extra?['latitude'],
                  initialLongitude: extra?['longitude'],
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.attributes,
            name: '/attributes',
            pageBuilder: (context, state) =>
                platformPage(state, const AttributesPage()),
          ),
          GoRoute(
            path: AppRoutes.returnReasons,
            name: '/return-reasons',
            pageBuilder: (context, state) => platformPage(
              state,
              BlocProvider(
                create: (context) => ReturnReasonsBloc(ReturnReasonsRepo()),
                child: const ReturnReasonsPage(),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.attributeValues,
            name: '/attribute-values',
            pageBuilder: (context, state) {
              final attribute = state.extra as dynamic;
              return platformPage(
                state,
                AttributeValuesPage(attribute: attribute),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.productDetails,
            name: '/product-details',
            pageBuilder: (context, state) {
              final product = state.extra as dynamic;
              return platformPage(state, ProductDetailsPage(product: product));
            },
          ),
          GoRoute(
            path: '${AppRoutes.returnDetails}/:id',
            name: '/return-details',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return platformPage(state, BlocProvider(
                create: (context) => ReturnDetailsCubit(context.read<OrderReturnsRepo>(), id),
                child: const ReturnDetailsPage(),
              ));
            },
          ),
          GoRoute(
            path: '${AppRoutes.orderDetails}/:id',
            name: '/order-details',
            pageBuilder: (context, state) {
              final idString = state.pathParameters['id'];
              final id = int.tryParse(idString ?? '') ?? 0;
              return platformPage(state, OrderDetailsPage(orderId: id));
            },
          ),
          GoRoute(
            path: AppRoutes.wallet,
            name: '/wallet',
            pageBuilder: (context, state) =>
                platformPage(state, const WalletPage()),
          ),
          GoRoute(
            path: AppRoutes.withdrawRequest,
            name: '/withdraw-request',
            pageBuilder: (context, state) =>
                platformPage(state, const WithdrawRequestPage()),
          ),
          GoRoute(
            path: AppRoutes.withdrawHistory,
            name: '/withdraw-history',
            pageBuilder: (context, state) =>
                platformPage(state, const WithdrawHistoryPage()),
          ),
          GoRoute(
            path: AppRoutes.transactionHistory,
            name: '/transaction-history',
            pageBuilder: (context, state) =>
                platformPage(state, const TransactionHistoryPage()),
          ),
          GoRoute(
            path: AppRoutes.earnings,
            name: '/earnings',
            pageBuilder: (context, state) =>
                platformPage(state, const EarningPage()),
          ),
          GoRoute(
            path: AppRoutes.productFaqs,
            name: '/product-faqs',
            pageBuilder: (context, state) {
              final productIdStr = state.uri.queryParameters['productId'];
              final productId = int.tryParse(productIdStr ?? '');
              return platformPage(state, ProductFaqsPage(productId: productId));
            },
          ),
          GoRoute(
            path: AppRoutes.profilePage,
            name: '/profile',
            pageBuilder: (context, state) =>
                platformPage(state, const ProfilePage()),
          ),
          GoRoute(
            path: AppRoutes.watchAndBuyProfile,
            name: '/watch-and-buy-profile',
            pageBuilder: (context, state) =>
                platformPage(state, const WatchAndBuyProfilePage()),
          ),
          GoRoute(
            path: AppRoutes.watchAndBuyStories,
            name: '/watch-and-buy-stories',
            pageBuilder: (context, state) =>
                platformPage(state, const WatchAndBuyStoriesPage()),
          ),
          GoRoute(
            path: AppRoutes.watchAndBuyReels,
            name: '/watch-and-buy-reels',
            pageBuilder: (context, state) =>
                platformPage(state, const WatchAndBuyReelsPage()),
          ),
          GoRoute(
            path: AppRoutes.ordersFull,
            name: '/orders-full',
            pageBuilder: (context, state) =>
                platformPage(state, const OrderPage()),
          ),
          GoRoute(
            path: AppRoutes.productsFull,
            name: '/products-full',
            pageBuilder: (context, state) =>
                platformPage(state, const ProductsPage()),
          ),

          GoRoute(
            path: AppRoutes.addOnGroup,
            name: '/add-on-group',
            pageBuilder: (context, state) =>
                platformPage(state, const AddonGroupsPage()),
          ),

          GoRoute(
            path: AppRoutes.productAddOn,
            name: '/product-add-on',
            pageBuilder: (context, state) =>
                platformPage(state, const ProductAddonPage()),
          ),
          GoRoute(
            path: AppRoutes.createProductAddOn,
            name: '/create-product-add-on',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final model = extra?['model'] as ProductAddon?;
              return platformPage(
                state,
                BlocProvider(
                  create: (context) => CreateProductAddonsCubit(),
                  child: CreateProductAddonsPage(editModel: model),
                ),
              );
            },
          ),

          GoRoute(
            path: AppRoutes.storeAddonInventory,
            name: '/store-addon-inventory',
            pageBuilder: (context, state) =>
                platformPage(state, const StoreAddonInventoryPage()),
          ),
          GoRoute(
            path: AppRoutes.createStoreAddonInventory,
            name: '/create-store-addon-inventory',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final inventoryId = extra?['id'] as int?;
              return platformPage(
                state,
                BlocProvider(
                  create: (context) =>
                      AddStoreAddonInventoryCubit()..init(editId: inventoryId),
                  child: AddStoreAddonInventoryPage(inventoryId: inventoryId),
                ),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.createAddOnGroup,
            name: '/create_add-on-group',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final model = extra?['model'] as AddonGroup?;
              return platformPage(
                state,
                CreateAddonGroupPage(addonGroup: model),
              );
            },
          ),

          GoRoute(
            path: AppRoutes.rolesAndPermission,
            name: '/roles-permission',
            pageBuilder: (context, state) =>
                platformPage(state, const RolesAndPermissionPage()),
          ),
          GoRoute(
            path: AppRoutes.permissions,
            name: '/permissions',
            pageBuilder: (context, state) {
              final role = state.uri.queryParameters['role'] ?? '';
              final roleIdStr = state.uri.queryParameters['roleId'] ?? '0';
              final roleId = int.tryParse(roleIdStr) ?? 0;
              return platformPage(
                state,
                PermissionPage(role: role, roleId: roleId),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.deliveryZones,
            name: '/delivery-zones',
            pageBuilder: (context, state) =>
                platformPage(state, const DeliveryZonesPage()),
          ),
          GoRoute(
            path: AppRoutes.systemUsers,
            name: '/system-users',
            pageBuilder: (context, state) =>
                platformPage(state, const SystemUsersPage()),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: '/notifications',
            pageBuilder: (context, state) =>
                platformPage(state, const NotificationListPage()),
          ),
          GoRoute(
            path: AppRoutes.privacyPolicy,
            name: '/privacy-policy',
            pageBuilder: (context, state) => platformPage(
              state,
              SettingsContentPage(
                title: context.tr('privacyPolicy'),
                htmlContent: HiveStorage.privacyPolicy,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.termsCondition,
            name: '/terms-condition',
            pageBuilder: (context, state) => platformPage(
              state,
              SettingsContentPage(
                title: context.tr('termsAndConditions'),
                htmlContent: HiveStorage.termsCondition,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.subscriptionPlans,
            name: '/subscription-plans',
            pageBuilder: (context, state) =>
                platformPage(state, const SubscriptionPlansPage()),
          ),
          GoRoute(
            path: AppRoutes.subscriptionPlanDetails,
            name: '/subscription-plan-details',
            pageBuilder: (context, state) {
              final plan = state.extra as SubscriptionPlan;
              return platformPage(
                state,
                SubscriptionPlanDetailsPage(plan: plan),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.subscriptionPaymentWebView,
            name: '/subscription-payment-webview',
            pageBuilder: (context, state) {
              final url = state.extra as String;
              return platformPage(state, SubscriptionPaymentWebView(url: url));
            },
          ),
          GoRoute(
            path: AppRoutes.subscriptionPlanHistory,
            name: '/subscription-plan-history',
            pageBuilder: (context, state) =>
                platformPage(state, const SubscriptionHistoryPage()),
          ),
          GoRoute(
            path: AppRoutes.subscriptionChoosePlan,
            name: '/subscription-choose-plan',
            pageBuilder: (context, state) =>
                platformPage(state, const ChoosePlanPage()),
          ),

          // Campaign routes
          GoRoute(
            path: AppRoutes.campaigns,
            name: '/campaigns',
            pageBuilder: (context, state) =>
                platformPage(state, const CampaignListPage()),
          ),
          GoRoute(
            path: AppRoutes.createCampaign,
            name: '/create-campaign',
            pageBuilder: (context, state) =>
                platformPage(state, const CreateCampaignPage()),
          ),
          GoRoute(
            path: '${AppRoutes.campaignDetail}/:id',
            name: '/campaign-detail',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return platformPage(state, CampaignDetailPage(campaignId: id));
            },
          ),
          GoRoute(
            path: AppRoutes.campaignWallet,
            name: '/campaign-wallet',
            pageBuilder: (context, state) =>
                platformPage(state, const CampaignWalletPage()),
          ),
          GoRoute(
            path: AppRoutes.campaignProductSelect,
            name: '/campaign-product-select',
            pageBuilder: (context, state) => platformPage(
              state,
              BlocProvider(
                create: (_) => CampaignProductSelectBloc(CampaignRepository()),
                child: const CampaignProductSelectPage(),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.campaignPaymentWebView,
            name: '/campaign-payment-webview',
            pageBuilder: (context, state) {
              final url = state.extra as String;
              return platformPage(state, CampaignPaymentWebView(url: url));
            },
          ),
        ],
      ),
    ],
  );
}

class BackToHomeWrapper extends StatelessWidget {
  const BackToHomeWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        context.go(AppRoutes.home);
      },
      child: child,
    );
  }
}
