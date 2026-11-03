import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/bloc/screen_size/screen_size_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/order_page/widgets/order_dialogs.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/screen/order_page/repo/order_repo.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';

import '../../../widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _scheduledScrollController = ScrollController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _scrollController.addListener(_onScroll);
    _scheduledScrollController.addListener(_onScheduledScroll);
    WidgetsBinding.instance.addObserver(this);

    // Initial fetch using Hive storage (fastest way to get data on boot)
    final storeId = HiveStorage.selectedStoreId;
    if (storeId != null) {
      context.read<OrdersBloc>()
        ..add(LoadOrdersInitial(storeId: storeId))
        ..add(LoadScheduledOrdersInitial(storeId: storeId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scheduledScrollController.removeListener(_onScheduledScroll);
    _scheduledScrollController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final store = context.read<StoreSwitcherCubit>().state.selectedStore;
      if (store != null) {
        context.read<OrdersBloc>()
          ..add(RefreshOrders())
          ..add(RefreshScheduledOrders());
      }
    }
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      if (_tabController.index == 0) {
        context.read<OrdersBloc>().add(RefreshOrders());
      } else if (_tabController.index == 1) {
        context.read<OrdersBloc>().add(RefreshScheduledOrders());
      }
    }
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<OrdersBloc>().add(LoadMoreOrders());
    }
  }

  void _onScheduledScroll() {
    if (_isScheduledBottom) {
      context.read<OrdersBloc>().add(LoadMoreScheduledOrders());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  bool get _isScheduledBottom {
    if (!_scheduledScrollController.hasClients) return false;
    final maxScroll = _scheduledScrollController.position.maxScrollExtent;
    final currentScroll = _scheduledScrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Widget _buildTab(String title, int count, double minWidth) {
    return Tab(
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  count.toString(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenSizeBloc, ScreenSizeState>(
      builder: (context, screenSizeState) {
        final screenType = screenSizeState.screenType;
        final l10n = context;

        return CustomScaffold(
          title: l10n?.tr('orders') ?? "Orders",
          centerTitle: true,
          showAppbar: true,
          isHaveSearch: true,
          searchHint: l10n?.tr('search') ?? 'Search',
          showFilters: true,
          showStore: true,
          onSearchChanged: (value) {
            _debouncer.run(() {
              context.read<OrdersBloc>().add(SearchOrders(value));
            });
          },
          body: BlocListener<StoreSwitcherCubit, StoreSwitcherState>(
            listenWhen: (previous, current) {
              if (previous.selectedStore?.id == current.selectedStore?.id) {
                return false;
              }
              // Prevent double fetch on cold boot if the API returns the same store we already fetched from Hive
              if (previous.selectedStore == null && current.selectedStore?.id == HiveStorage.selectedStoreId) {
                return false;
              }
              return true;
            },
            listener: (context, state) {
              if (state.selectedStore != null) {
                context.read<OrdersBloc>()
                  ..add(LoadOrdersInitial(storeId: state.selectedStore!.id))
                  ..add(LoadScheduledOrdersInitial(storeId: state.selectedStore!.id));
              }
            },
            child: BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                final total = state.total ?? 0;
                final totalScheduled = state.totalScheduled;

                final tabWidth = screenType == ScreenType.tablet ? 180.0 : 120.0;

                if (!PermissionChecker.hasPermission(AppPermissions.orderView)) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        l10n?.tr('noPermissionError') ?? 'You do not have permission to access this.',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(width: 3.0, color: AppColors.primaryColor),
                        insets: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      labelColor: AppColors.primaryColor,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        _buildTab(context.tr('myOrderTab'), total, tabWidth),
                        _buildTab(context.tr('scheduleOrderTab'), totalScheduled, tabWidth),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: My Order List
                          _OrdersListView(
                            state: state,
                            scrollController: _scrollController,
                            screenType: screenType,
                            isScheduledList: false,
                            onRefresh: () {
                              context.read<OrdersBloc>().add(RefreshOrders());
                            },
                          ),

                          // Tab 2: Schedule Order List
                          _OrdersListView(
                            state: OrdersState(
                              items: state.scheduledItems,
                              hasMore: state.hasMoreScheduled,
                              isInitialLoading: state.isInitialLoadingScheduled,
                              isRefreshing: state.isRefreshingScheduled,
                              isPaginating: state.isPaginatingScheduled,
                              error: state.errorScheduled,
                              currentPage: state.currentPageScheduled,
                              total: state.totalScheduled,
                            ),
                            scrollController: _scheduledScrollController,
                            screenType: screenType,
                            isScheduledList: true,
                            onRefresh: () {
                              context.read<OrdersBloc>().add(RefreshScheduledOrders());
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _OrdersListView extends StatelessWidget {
  final OrdersState state;
  final ScrollController scrollController;
  final ScreenType screenType;
  final VoidCallback onRefresh;
  final bool isScheduledList;

  const _OrdersListView({
    required this.state,
    required this.scrollController,
    required this.screenType,
    required this.onRefresh,
    this.isScheduledList = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = state.items;
    final hasMore = state.hasMore;
    final isPaginating = state.isPaginating;
    final l10n = context;

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      color: AppColors.primaryColor,
      child: (!state.isInitialLoading && !state.isRefreshing && state.items.isEmpty)
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: EmptyStateWidget(
                  svgPath: ImagesPath.noOrderFoundSvg,
                  title: context.tr('noOrdersFound') ?? "No Orders Found",
                  subtitle: context.tr('noOrdersMessage') ?? "You don't have any orders yet.",
                  actionText: context.tr('refresh') ?? "Refresh",
                  onAction: onRefresh,
                ),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: scrollController,
              padding: UIUtils.cardsPadding(screenType),
              itemCount: ((state.isInitialLoading || state.isRefreshing) && state.items.isEmpty)
                  ? 10
                  : items.length + (hasMore ? (isPaginating ? 10 : 1) : 0),
              itemBuilder: (context, index) {
                if ((state.isInitialLoading || state.isRefreshing) && state.items.isEmpty) {
                  return CardShimmer(type: 'order', screenType: screenType);
                }

                if (index >= items.length) {
                  return CardShimmer(type: 'order', screenType: screenType);
                }

                final order = items[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: UIUtils.gapMD(screenType)),
                  child: CustomCard(
                    type: CardType.order,
                    screenType: screenType,
                    data: {
                      'id': order.sellerOrderId,
                      'order_item_id': order.orderItemId,
                      'seller_order_id': order.sellerOrderId,
                      'items': order.items.map((e) => e.toJson()).toList(),
                      'subtotal': order.finalTotal.toString(),
                      'status': order.status,
                      'isRushOrder': order.isRushOrder,
                      'created_at': order.createdAt,
                      'delivery_type': order.deliveryType,
                      'scheduled_date': order.scheduledDate,
                      'delivery_time_slot_id': order.deliveryTimeSlotId,
                      'scheduled_time_slot_label': order.scheduledTimeSlotLabel,
                      'reschedule_status': order.rescheduleStatus,
                      'reschedule_reason': order.rescheduleReason,
                      'reschedule_deadline': order.rescheduleDeadline,
                      'acceptance_timeout': order.acceptanceTimeout,
                      'is_scheduled_list': isScheduledList,
                    },
                    onTap: () {
                      final isPickup = order.deliveryType?.toLowerCase() == 'pickup';
                      final hasPermission = isPickup
                          ? PermissionChecker.hasPermission(AppPermissions.pickupManage)
                          : PermissionChecker.hasPermission(AppPermissions.orderView);

                      if (!hasPermission) {
                        showCustomSnackbar(
                          context: context,
                          message: l10n?.tr('noPermissionError') ?? 'You do not have permission to access this.',
                          isWarning: true,
                        );
                        return;
                      }
                      context.pushNamed(AppRoutes.orderDetails, pathParameters: {'id': order.sellerOrderId.toString()});
                    },
                    onToggleStatus: (status) {
                      if (status == 'view_details') {
                        final isPickup = order.deliveryType?.toLowerCase() == 'pickup';
                        final hasPermission = isPickup
                            ? PermissionChecker.hasPermission(AppPermissions.pickupManage)
                            : PermissionChecker.hasPermission(AppPermissions.orderView);

                        if (!hasPermission) {
                          showCustomSnackbar(
                            context: context,
                            message: l10n?.tr('noPermissionError') ?? 'You do not have permission to access this.',
                            isWarning: true,
                          );
                          return;
                        }
                        context.pushNamed(AppRoutes.orderDetails, pathParameters: {'id': order.sellerOrderId.toString()});
                        return;
                      }
                      final isPickup = order.deliveryType?.toLowerCase() == 'pickup';
                      final hasPermission = isPickup
                          ? PermissionChecker.hasPermission(AppPermissions.pickupManage)
                          : PermissionChecker.hasPermission(AppPermissions.orderUpdateStatus);

                      if (!hasPermission) {
                        showCustomSnackbar(
                          context: context,
                          message: l10n?.tr('noPermissionError') ?? 'You do not have permission to access this.',
                          isWarning: true,
                        );
                        return;
                      }

                      if (status == 'accept') {
                        OrderDialogs.showAcceptDialog(context, () async {
                          context.read<OrdersBloc>().add(
                            BulkUpdateOrderStatus(
                              orderItemIds: order.items.map((i) => i.id).toList(),
                              status: 'accept',
                            ),
                          );
                        });
                      } else if (status == 'reject') {
                        OrderDialogs.showRejectDialog(context, () async {
                          context.read<OrdersBloc>().add(
                            BulkUpdateOrderStatus(
                              orderItemIds: order.items.map((i) => i.id).toList(),
                              status: 'reject',
                            ),
                          );
                        });
                      } else if (status == 'auto_reject') {
                        // Reject locally without API call (backend cron handles actual rejection)
                        context.read<OrdersBloc>().add(
                          LocalUpdateOrderStatus(orderId: order.sellerOrderId, status: 'rejected_by_seller'),
                        );
                      } else {
                        OrderDialogs.showPreparedDialog(context, () async {
                          context.read<OrdersBloc>().add(
                            BulkUpdateOrderStatus(
                              orderItemIds: order.items.map((i) => i.id).toList(),
                              status: 'preparing',
                            ),
                          );
                        });
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
