import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_card.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/ui/empty_state_widget.dart';
import '../cubit/returns_cubit.dart';
import '../cubit/returns_state.dart';
import '../model/return_filters.dart';
import '../widgets/return_filter_sheet.dart';

class ReturnsPage extends StatefulWidget {
  const ReturnsPage({super.key});
  @override
  State<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends State<ReturnsPage> with WidgetsBindingObserver {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _debouncer = Debouncer(milliseconds: 500);
  bool get _canView =>
      PermissionChecker.hasPermission(AppPermissions.returnView);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_onScroll);
    if (_canView) context.read<ReturnsCubit>().initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    _search.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && _canView) {
      context.read<ReturnsCubit>().refresh();
    }
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 200 && _canView) {
      context.read<ReturnsCubit>().loadMore();
    }
  }

  Future<void> _filters(ReturnsState state) async {
    _debouncer.dispose();
    final result = await showModalBottomSheet<ReturnFilters>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReturnFilterSheet(
        filters: state.filters.withSearch(_search.text),
        enums: state.enums,
      ),
    );
    if (result != null && mounted) {
      await context.read<ReturnsCubit>().load(filters: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final screenType = context.screenType;
    return BlocBuilder<ReturnsCubit, ReturnsState>(
      builder: (context, state) {
        final cubit = context.read<ReturnsCubit>();
        return CustomScaffold(
          title: l10n.tr('returnsLabel'),
          showAppbar: true,
          centerTitle: true,
          isHaveSearch: _canView,
          searchController: _search,
          searchHint: l10n.tr('search'),
          onSearchChanged: (value) => _debouncer.run(() {
            if (mounted) cubit.search(value);
          }),
          appBarActions: _canView
              ? [
                  IconButton(
                    tooltip: l10n.tr('filters'),
                    onPressed: () => _filters(state),
                    icon: Badge(
                      isLabelVisible: state.filters.advancedCount > 0,
                      label: Text('${state.filters.advancedCount}'),
                      child: const Icon(Icons.filter_list),
                    ),
                  ),
                ]
              : null,
          body: !_canView
              ? Center(child: Text(l10n.tr('noPermissionViewReturns')))
              : Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          for (final group in <String?, String>{
                            null: l10n.tr('all'),
                            'under_review': l10n.tr('returnsUnderReview'),
                            'approved': l10n.tr('approved'),
                            'refund_processed': l10n.tr('returnsRefundProcessed'),
                            'disputed': l10n.tr('returnsDisputed'),
                          }.entries)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: ChoiceChip(
                                label: Text(
                                  '${group.value}${state.insights.containsKey(group.key ?? 'total') ? ' (${state.insights[group.key ?? 'total']})' : ''}',
                                ),
                                selected:
                                    state.filters.status == null &&
                                    state.filters.statusGroup == group.key,
                                onSelected: (_) {
                                  _debouncer.dispose();
                                  cubit.load(
                                    filters: state.filters
                                        .withSearch(_search.text)
                                        .withGroup(group.key),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (state.enumsError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(child: Text(state.enumsError!)),
                            TextButton(
                              onPressed: cubit.loadEnums,
                              child: Text(l10n.tr('retry')),
                            ),
                          ],
                        ),
                      ),
                    if (state.isRefreshing) const LinearProgressIndicator(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: cubit.refresh,
                        child: _list(context, state, screenType),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _list(
    BuildContext context,
    ReturnsState state,
    ScreenType screenType,
  ) {
    final l10n = context;
    final cubit = context.read<ReturnsCubit>();
    if (state.isInitialLoading) {
      return ListView.separated(
        padding: UIUtils.pagePadding(screenType),
        itemCount: 4,
        separatorBuilder: (_, _) => SizedBox(height: UIUtils.gapMD(screenType)),
        itemBuilder: (_, _) =>
            CardShimmer(type: 'order', screenType: screenType),
      );
    }
    if (state.items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: EmptyStateWidget(
                svgPath: ImagesPath.noOrderFoundSvg,
                title: state.error == null
                    ? l10n.tr('returnsNoReturns')
                    : l10n.tr('returnsLabel'),
                subtitle: state.error ?? l10n.tr('tryDifferentFilter'),
                actionText: state.error == null ? null : l10n.tr('retry'),
                onAction: state.error == null ? null : cubit.refresh,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: UIUtils.pagePadding(screenType),
      itemCount: state.items.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: UIUtils.gapMD(screenType)),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          if (state.isPaginating) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (state.error != null) {
            return Column(
              children: [
                Text(state.error!),
                TextButton(onPressed: cubit.refresh, child: Text(l10n.tr('retry'))),
              ],
            );
          }
          return state.hasMore
              ? TextButton(
                  onPressed: cubit.loadMore,
                  child: Text(l10n.tr('returnsLoadMore')),
                )
              : const SizedBox.shrink();
        }
        final item = state.items[index];
        return CustomCard(
          type: CardType.orderReturn,
          data: {'id': item.id, 'return': item},
          screenType: screenType,
          onTap: () => context.push('${AppRoutes.returnDetails}/${item.id}'),
        );
      },
    );
  }
}
