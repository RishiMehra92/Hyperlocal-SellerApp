import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/utils/debouncer.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/card_shimmers.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';

import '../bloc/campaign_product_select_bloc/campaign_product_select_bloc.dart';
import '../model/campaign_product_model.dart';

class CampaignProductSelectPage extends StatefulWidget {
  const CampaignProductSelectPage({super.key});

  @override
  State<CampaignProductSelectPage> createState() =>
      _CampaignProductSelectPageState();
}

class _CampaignProductSelectPageState extends State<CampaignProductSelectPage> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 500);
  final ScrollController _scrollController = ScrollController();

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<CampaignProductSelectBloc>().add(
      LoadCampaignProductsInitial(),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= maxScroll * 0.9) {
      context.read<CampaignProductSelectBloc>().add(LoadMoreCampaignProducts());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final screenType = context.screenType;
    final theme = Theme.of(context);

    return CustomScaffold(
      title: l10n?.tr('selectProduct') ?? 'Select Product',
      showAppbar: true,
      centerTitle: true,
      body: Column(
        children: [
          // Search
          Padding(
            padding: EdgeInsets.all(UIUtils.pagePadding(screenType).left),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n?.tr('searchProducts') ?? 'Search products...',
                prefixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      )
                    : const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _isSearching = false);
                          context.read<CampaignProductSelectBloc>().add(
                            SearchCampaignProducts(''),
                          );
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    UIUtils.radiusMD(screenType),
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() => _isSearching = value.isNotEmpty);
                _debouncer.run(() {
                  if (mounted) {
                    setState(() => _isSearching = false);
                  }
                  context.read<CampaignProductSelectBloc>().add(
                    SearchCampaignProducts(value),
                  );
                });
              },
            ),
          ),

          // Product List
          Expanded(
            child:
                BlocBuilder<
                  CampaignProductSelectBloc,
                  CampaignProductSelectState
                >(
                  builder: (context, state) {
                    if (state.isInitialLoading) {
                      return _buildShimmerList(screenType);
                    }

                    if (state.error != null && state.items.isEmpty) {
                      return _buildErrorState(l10n, screenType);
                    }

                    if (state.items.isEmpty) {
                      return _buildEmptyState(
                        l10n,
                        screenType,
                        hasSearch: _searchController.text.isNotEmpty,
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: UIUtils.pagePadding(screenType).left,
                        vertical: UIUtils.gapSM(screenType),
                      ),
                      itemCount:
                          state.items.length + (state.isPaginating ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          SizedBox(height: UIUtils.gapSM(screenType)),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          );
                        }

                        final product = state.items[index];
                        return _buildProductTile(product, screenType, theme);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(
    CampaignProduct product,
    ScreenType screenType,
    ThemeData theme,
  ) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(UIUtils.radiusSM(screenType)),
          child: Image.network(
            product.mainImage ?? '',
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 48,
              height: 48,
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, color: Colors.grey),
            ),
          ),
        ),
        title: Text(
          product.title ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIUtils.radiusMD(screenType)),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        onTap: () {
          context.pop(product.toJson());
        },
      ),
    );
  }

  Widget _buildShimmerList(ScreenType screenType) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: UIUtils.pagePadding(screenType).left,
        vertical: UIUtils.gapSM(screenType),
      ),
      itemCount: 8,
      separatorBuilder: (_, _) => SizedBox(height: UIUtils.gapSM(screenType)),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(vertical: UIUtils.gapXS(screenType)),
        child: CardShimmer(type: 'productSelect', screenType: screenType),
      ),
    );
  }

  Widget _buildErrorState(BuildContext? l10n, ScreenType screenType) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(UIUtils.gapXL(screenType)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade300,
            ),
            SizedBox(height: UIUtils.gapMD(screenType)),
            Text(
              l10n?.tr('somethingWentWrong') ?? 'Failed to load products',
              style: TextStyle(
                fontSize: UIUtils.tileTitle(screenType),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: UIUtils.gapLG(screenType)),
            OutlinedButton.icon(
              onPressed: () {
                context.read<CampaignProductSelectBloc>().add(
                  LoadCampaignProductsInitial(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.tr('retry') ?? 'Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    UIUtils.radiusMD(screenType),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext? l10n,
    ScreenType screenType, {
    required bool hasSearch,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(UIUtils.gapXL(screenType)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: UIUtils.gapMD(screenType)),
            Text(
              hasSearch
                  ? (l10n?.tr('noResultsFound') ?? 'No results found')
                  : (l10n?.tr('noProductsFound') ?? 'No products found'),
              style: TextStyle(
                fontSize: UIUtils.tileTitle(screenType),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            if (hasSearch) ...[
              SizedBox(height: UIUtils.gapSM(screenType)),
              Text(
                l10n?.tr('tryDifferentSearch') ?? 'Try a different search term.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: UIUtils.body(screenType),
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
