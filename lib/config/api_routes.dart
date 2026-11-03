import 'package:hyper_local_seller/config/constant.dart';

class ApiRoutes {
  // DON"T CHANGE ANY OF THIS URLs
  static String mainUrl = '${AppConstants.baseUrl}/api';
  static String fullUrl = '$mainUrl/seller';

  // ROUTES

  // AUTH
  static String registerApi = '$fullUrl/register';
  static String loginApi = '$fullUrl/login';
  static String logoutApi = '$fullUrl/logout';
  static String forgetPasswordApi = '$mainUrl/forget-password';
  static String verifyUserApi = '$mainUrl/verify-user';
  static String callbackApi = '$mainUrl/auth/phone/callback';
  static String customSendOtpApi = '$mainUrl/seller/auth/send-otp';
  static String customVerifyOtpApi = '$mainUrl/seller/auth/verify-otp';

  static String languagesApi = '$mainUrl/languages';
  static String languageLabelsApi = '$mainUrl/language-labels';

  static String settingsApi = '$mainUrl/settings';
  static String splashConfigApi = '$mainUrl/splash-config';
  static String onboardingScreensApi = '$mainUrl/onboarding-screens';

  static String categoriesApi = '$mainUrl/categories';
  static String brandsApi = '$fullUrl/brands';
  static String attributesApi = '$fullUrl/attributes';
  static String attributeValueApi = '$fullUrl/attribute-values';
  static String productsApi = '$fullUrl/products';
  static String productFaqsApi = '$fullUrl/product-faqs';
  static String productsEnumsApi = '$productsApi/enums';
  static String generateDescriptionApi = '$productsApi/generate';
  static String translateProductsApi = '$productsApi/translate';
  static String taxGroupsApi = '$fullUrl/tax-classes';
  static String storesApi = '$fullUrl/stores';
  static String storesEnumsApi = '$storesApi/enums';
  static String rolesApi = '$fullUrl/roles';
  static String rolesListApi = '$rolesApi/list';
  static String permissionsApi = '$fullUrl/permissions';
  static String systemUsersApi = '$fullUrl/system-users';
  static String notificationsApi = '$fullUrl/notifications';
  static String returnReasonsApi = '$fullUrl/return-reasons';

  static String dashboardDataApi = '$fullUrl/dashboard';
  static String ordersApi = '$fullUrl/orders';
  static String bulkUpdateStatusApi = '$ordersApi/bulk-update-status';
  static String ordersEnumsApi = '$ordersApi/enums';
  static String orderReturnsApi = '$fullUrl/order-returns';
  static String orderReturnsEnumsApi = '$orderReturnsApi/enums';

  // wallet / transactions
  static String walletApi = '$fullUrl/wallet';
  static String transactionsApi = '$walletApi/transactions';
  static String withdrawalsApi = '$fullUrl/withdrawals';
  static String withdrawalHistoryApi = '$withdrawalsApi/history';

  // commission
  static String unsettledCreditApi = '$fullUrl/commissions';
  static String unsettledDebitApi = '$unsettledCreditApi/debits';
  static String settledEarningsApi = '$unsettledCreditApi/history';

  // profile
  static String updateUserApi = '$mainUrl/user/profile';
  static String changePasswordApi = '$mainUrl/user/change-password';
  static String watchAndBuyProfileApi = '$fullUrl/watch-and-buy/profile';
  static String watchAndBuyStoriesApi = '$fullUrl/watch-and-buy/stories';
  static String watchAndBuyReelsApi = '$fullUrl/watch-and-buy/reels';
  static String watchAndBuyEligibleProductsApi =
      '$fullUrl/watch-and-buy/eligible-products';

  // delivery zone
  static String deliveryZonesApi = '$mainUrl/delivery-zone';

  // subscription plans
  static String subscriptionPlansApi = '$mainUrl/subscription/plans';
  static String checkEligibilityApi = '$fullUrl/subscription/check-eligibility';
  static String buySubscriptionPlanApi = '$fullUrl/subscription/buy';
  static String currentSubscriptionPlanApi = '$fullUrl/subscription/current';
  static String subscriptionPlanHistoryApi = '$fullUrl/subscription/history';
  static String deleteProfileApi = '$fullUrl/delete-account';
  static String addOnGroupListApi = "$fullUrl/addon-groups";
  static String productAddOneListApi = "$fullUrl/product-addons";
  static String deleteProductAddOnApi = "$fullUrl/product-addons";
  static String lookupProductsApi = '$fullUrl/product-addons/lookup/products';
  static String lookupVariantsBulkApi =
      '$fullUrl/product-addons/lookup/variants-bulk';
  static String lookupAddonGroupsApi =
      '$fullUrl/product-addons/lookup/addon-groups';
  static String showProductAddonApi = '$fullUrl/product-addons/show';
  static String updateProductAddonApi(int variantId, int groupId) =>
      '$fullUrl/product-addons/$variantId/$groupId';
  static String versionCheckApi = '$mainUrl/settings/check-version';
  static String stockInventoryListApi = "$fullUrl/store-addon-items";
  static String lookupStoresForInventoryApi =
      "$stockInventoryListApi/lookup/stores";
  static String lookupAddonGroupsForInventoryApi =
      "$stockInventoryListApi/lookup/addon-groups";
  static String lookupGroupItemsApi(int groupId) =>
      "$stockInventoryListApi/lookup/groups/$groupId/items";
  static String lookupInventoryStateApi(int storeId, int itemId) =>
      "$stockInventoryListApi/lookup/state?store_id=$storeId&addon_item_id=$itemId";
  static String bulkCreateInventoryApi = "$stockInventoryListApi/bulk";
  static String updateInventoryApi(int id) => "$stockInventoryListApi/$id";

  // ad wallet
  static String adWalletApi = '$fullUrl/ad-wallet';
  static String adWalletTransactionsApi = '$adWalletApi/transactions';
  static String adWalletTopupGatewayApi = '$adWalletApi/topup/gateway';
  static String adWalletTopupEarningsApi = '$adWalletApi/topup/earnings';

  // ad campaigns
  static String adCampaignsApi = '$fullUrl/ad-campaigns';
  static String adCampaignConfigApi = '$adCampaignsApi/config';
  static String adCampaignDetailApi(int id) => '$adCampaignsApi/$id';
  static String adCampaignPauseApi(int id) => '$adCampaignsApi/$id/pause';
  static String adCampaignResumeApi(int id) => '$adCampaignsApi/$id/resume';
}
