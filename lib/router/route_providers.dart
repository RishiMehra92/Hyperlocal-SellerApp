import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/global_keys.dart';

import 'package:hyper_local_seller/screen/auth/repo/auth_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/bloc/categories_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/my_subscriptions/subscription_history_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_history_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/buy_subscription/buy_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/check_eligibility/check_eligibility_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/current_subscription/current_subscription_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/bloc/subscription_plans_bloc/subscription_plan_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/repo/subscription_plans_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/bloc/system_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/system_users/repo/system_users_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/watch_and_buy/bloc/watch_and_buy_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_ons/addon_groups/cubit/addon_groups_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_ons/addon_groups/repo/addon_groups_repo.dart';
import 'package:hyper_local_seller/screen/products_page/product_addons/product_addons_group/cubit/product_addon_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/product_addons/product_addons_group/repo/product_addon_repo.dart';

import 'package:hyper_local_seller/screen/more_page/view/store_addon_inventory/store_addon_list/cubit/store_addon_inventory_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/store_addon_inventory/store_addon_list/repo/store_addon_inventory_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/repo/attributes_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/bloc/brands_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/brands/repo/brands_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/categories/repo/categories_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attributes_bloc/attributes_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/attributes/bloc/attribute_values_bloc/attribute_values_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/bloc/settled_earnings_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/bloc/unsettled_earnings_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/earning/repo/earning_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/bloc/roles_bloc/roles_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/roles_and_permissions/repo/roles_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/bloc/stores_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/repo/store_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/transactions_bloc/transactions_history_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/wallet_bloc/wallet_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/bloc/withdraw_history_bloc/withdraw_history_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/wallet/repo/wallet_repo.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/add_product_bloc/add_product_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/repo/add_product_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/products_bloc/products_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/products_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/repo/product_faq_repo.dart';
import 'package:hyper_local_seller/screen/products_page/products/bloc/product_faq_bloc/product_faq_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/forget-password/forgot_password_bloc.dart';
import 'package:hyper_local_seller/screen/auth/bloc/verify-user/verify_user_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/bloc/tax_group_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/tax_group/repo/tax_group_repo.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/selected_categories_cubit.dart';
import 'package:hyper_local_seller/screen/products_page/add_products/bloc/selected_categories/category_expansion_cubit.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/bloc/add_store_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/stores/add_store/repo/add_store_repo.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/repo/home_data_repo.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/order_filters_bloc/order_filters_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/order_details_bloc/order_details_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/screen/returns_page/repo/order_returns_repo.dart';
import 'package:hyper_local_seller/screen/returns_page/cubit/returns_cubit.dart';
import 'package:hyper_local_seller/screen/more_page/view/campaigns/bloc/campaign_list_bloc/campaign_list_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/campaigns/bloc/campaign_wallet_bloc/campaign_wallet_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/campaigns/bloc/create_campaign_bloc/create_campaign_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/campaigns/bloc/ad_wallet_transactions_bloc/ad_wallet_transactions_bloc.dart'
    hide LoadTransactionsInitial;
import 'package:hyper_local_seller/screen/more_page/view/campaigns/repo/campaign_repo.dart';
import 'package:hyper_local_seller/screen/more_page/view/profile/bloc/profile_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/bloc/delivery_zone_bloc.dart';
import 'package:hyper_local_seller/screen/more_page/view/delivery_zone/repo/delivery_zone_repo.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/repo/notification_list_repo.dart';

import '../config/global_keys.dart';

class AuthProviders extends StatelessWidget {
  final Widget child;

  const AuthProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => ForgotPasswordBloc(context.read<AuthRepository>())),
        BlocProvider(create: (context) => VerifyUserBloc(authRepository: context.read<AuthRepository>())),
      ],
      child: child,
    );
  }
}

class AuthenticatedProviders extends StatefulWidget {
  final Widget child;

  const AuthenticatedProviders({super.key, required this.child});

  @override
  State<AuthenticatedProviders> createState() => _AuthenticatedProvidersState();
}

class _AuthenticatedProvidersState extends State<AuthenticatedProviders> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => CategoriesRepo()),
        RepositoryProvider(create: (_) => BrandsRepo()),
        RepositoryProvider(create: (_) => AttributesRepo()),
        RepositoryProvider(create: (_) => ProductsRepo()),
        RepositoryProvider(create: (_) => TaxGroupsRepo()),
        RepositoryProvider(create: (_) => StoresRepo()),
        RepositoryProvider(create: (_) => AddProductRepo()),
        RepositoryProvider(create: (_) => AddStoreRepository()),
        RepositoryProvider(create: (_) => HomeDataRepo()),
        RepositoryProvider(create: (_) => OrdersRepo()),
        RepositoryProvider(create: (_) => OrderReturnsRepo()),
        RepositoryProvider(create: (_) => ProductFaqRepo()),
        RepositoryProvider(create: (_) => DeliveryZoneRepo()),
        RepositoryProvider(create: (_) => NotificationListRepo()),
        RepositoryProvider(create: (_) => SubscriptionPlansRepo()),
        RepositoryProvider(create: (_) => AddonGroupsRepo()),
        RepositoryProvider(create: (_) => ProductAddonRepo()),
        RepositoryProvider(create: (_) => StoreAddonInventoryRepo()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => BrandsBloc(context.read<BrandsRepo>())..add(LoadBrandsInitial())),
          BlocProvider(
            create: (context) => CategoriesBloc(context.read<CategoriesRepo>())..add(LoadCategoriesInitial()),
          ),
          BlocProvider(
            create: (context) => AttributesBloc(context.read<AttributesRepo>())..add(LoadAttributesInitial()),
          ),
          BlocProvider(create: (context) => AttributeValuesBloc(context.read<AttributesRepo>())),
          BlocProvider(create: (context) => ProductsBloc(context.read<ProductsRepo>())),
          BlocProvider(create: (context) => TaxGroupsBloc(context.read<TaxGroupsRepo>())..add(LoadTaxGroupsInitial())),
          BlocProvider(create: (context) => StoresBloc(context.read<StoresRepo>())..add(LoadStoresInitial())),
          BlocProvider(create: (context) => StoreSwitcherCubit(context.read<StoresRepo>())..loadStores()),
          BlocProvider(create: (_) => SelectedCategoriesCubit()),
          BlocProvider(create: (_) => CategoryExpansionCubit()),
          BlocProvider(
            create: (context) => AddProductBloc(
              context.read<AddProductRepo>(),
              context.read<ProductsRepo>(),
              context.read<CategoriesRepo>(),
              context.read<AttributesRepo>(),
            ),
          ),
          BlocProvider(create: (context) => AddStoreBloc(context.read<AddStoreRepository>())),
          BlocProvider(create: (context) => HomePageBloc(repo: context.read<HomeDataRepo>())),
          BlocProvider(create: (context) => OrdersBloc(context.read<OrdersRepo>())),
          BlocProvider(create: (context) => ReturnsCubit(context.read<OrderReturnsRepo>())),
          BlocProvider(create: (context) => OrderFiltersBloc(context.read<OrdersRepo>())..add(FetchOrderFilters())),
          BlocProvider(create: (context) => OrderDetailsBloc(context.read<OrdersRepo>())),
          BlocProvider(create: (context) => ProfileBloc()..add(const ProfileFetchEvent(forceRefresh: true))),
          BlocProvider(create: (context) => WalletBloc()..add(FetchWallet())),
          BlocProvider(create: (context) => WithdrawHistoryBloc(WalletRepository())..add(LoadHistoryInitial())),
          BlocProvider(
            create: (context) => TransactionsHistoryBloc(WalletRepository())..add(LoadTransactionsInitial()),
          ),
          BlocProvider(
            create: (context) => SettledEarningsBloc(EarningRepository())..add(const LoadSettledEarningsInitial()),
          ),
          BlocProvider(
            create: (context) => UnsettledEarningsBloc(EarningRepository())..add(const LoadUnsettledEarningsInitial()),
          ),
          BlocProvider(create: (context) => ProductFaqBloc(context.read<ProductFaqRepo>())),
          BlocProvider(create: (context) => RolesBloc(RolesRepo())..add(const LoadRolesInitial())),
          BlocProvider(
            create: (context) => DeliveryZoneBloc(context.read<DeliveryZoneRepo>())..add(LoadDeliveryZonesInitial()),
          ),
          BlocProvider(create: (context) => SystemUserBloc(repo: SystemUsersRepo())..add(FetchSystemUsersEvent())),
          BlocProvider(
            create: (context) => NotificationListBloc(context.read<NotificationListRepo>())
              ..add(FetchUnreadCount())
              ..add(LoadNotificationsInitial()),
          ),
          BlocProvider(create: (context) => SubscriptionPlanBloc(context.read<SubscriptionPlansRepo>())),
          BlocProvider(create: (context) => CheckEligibilityBloc(context.read<SubscriptionPlansRepo>())),
          BlocProvider(
            create: (context) =>
                CurrentSubscriptionBloc(context.read<SubscriptionPlansRepo>())..add(FetchCurrentSubscription()),
          ),
          BlocProvider(create: (context) => BuySubscriptionBloc(context.read<SubscriptionPlansRepo>())),
          BlocProvider(
            create: (_) => SubscriptionHistoryBloc(SubscriptionHistoryRepo())..add(LoadSubscriptionHistoryInitial()),
          ),
          BlocProvider(create: (context) => AddonGroupsCubit(context.read<AddonGroupsRepo>())..fetchAddonGroups()),
          BlocProvider(create: (context) => ProductAddonCubit(context.read<ProductAddonRepo>())..fetchProductAddon()),
          BlocProvider(create: (context) => StoreAddonInventoryCubit()..fetchInventory()),
          BlocProvider(create: (_) => CampaignListBloc(CampaignRepository())),
          BlocProvider(create: (_) => CampaignWalletBloc(CampaignRepository())),
          BlocProvider(create: (_) => CreateCampaignBloc(CampaignRepository())),
          BlocProvider(create: (_) => AdWalletTransactionsBloc(CampaignRepository())),
          BlocProvider(create: (_) => WatchAndBuyBloc()),
        ],
        child: KeyedSubtree(key: GlobalKeys.authenticatedProvidersKey, child: widget.child),
      ),
    );
  }
}
