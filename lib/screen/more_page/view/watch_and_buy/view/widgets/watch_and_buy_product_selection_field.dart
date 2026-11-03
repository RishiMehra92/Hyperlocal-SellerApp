import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/screen/products_page/product_addons/create_product_addons/models/lookup_models.dart';
import 'package:hyper_local_seller/widgets/custom/custom_multi_selection_sheet.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'package:hyper_local_seller/widgets/custom/multi_selection_field.dart';
import '../../bloc/watch_and_buy_bloc.dart';
import '../../bloc/watch_and_buy_event.dart';
import '../../bloc/watch_and_buy_state.dart';

class WatchAndBuyProductSelectionField extends StatelessWidget {
  final List<ProductLookup> selectedProducts;
  final ValueChanged<List<ProductLookup>> onChanged;
  final int maxProducts;
  final bool isRequired;
  final bool preloadEligibleProducts;

  const WatchAndBuyProductSelectionField({
    super.key,
    required this.selectedProducts,
    required this.onChanged,
    this.maxProducts = 10,
    this.isRequired = false,
    this.preloadEligibleProducts = true,
  });

  void _showProductSearch(BuildContext context) {
    final bloc = context.read<WatchAndBuyBloc>();

    if (preloadEligibleProducts) {
      bloc.add(FetchEligibleProductsEvent());
    } else {
      bloc.add(const SearchLookupProductsEvent(query: ''));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<WatchAndBuyBloc, WatchAndBuyState>(
          builder: (ctx, state) {
            final bool isSearching = state.lookupProductsSearchQuery.isNotEmpty;
            final baseList = (preloadEligibleProducts && !isSearching)
                ? state.eligibleProducts
                : state.lookupProducts;

            final items = [
              ...selectedProducts,
              ...baseList.where((p) => !selectedProducts.contains(p)),
            ];

            return CustomMultiSelectionSheet<ProductLookup>(
              title:
                  context.tr('selectProducts') ??
                  "Select Products",
              items: items
                  .map((p) => MultiSelectionItem(label: p.title, value: p))
                  .toList(),
              selectedValues: selectedProducts,
              isLoading: (preloadEligibleProducts && !isSearching)
                  ? state.isEligibleProductsLoading
                  : state.isLookupProductsLoading,
              isLoadingMore: state.isLookupProductsLoadingMore,
              maxItems: maxProducts,
              onSearch: (q) {
                if (q.trim().isEmpty) {
                  if (preloadEligibleProducts) {
                    bloc.add(FetchEligibleProductsEvent());
                  } else {
                    bloc.add(const SearchLookupProductsEvent(query: ''));
                  }
                } else {
                  bloc.add(SearchLookupProductsEvent(query: q));
                }
              },
              onLoadMore: () {
                if (isSearching || !preloadEligibleProducts) {
                  bloc.add(LoadMoreLookupProductsEvent());
                }
              },
              onSelected: (selected) {
                if (selected.length > maxProducts) {
                  showCustomSnackbar(
                    context: context,
                    message:
                        context.tr('maxProductsSelectedWarning', positionalArgs: [maxProducts.toString()]) ??
                        'Maximum $maxProducts products can be selected',
                    isWarning: true,
                    showAtTop: true,
                  );
                  onChanged(selected.take(maxProducts).toList());
                } else {
                  onChanged(selected);
                }
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;

    return MultiSelectionField<ProductLookup>(
      isRequired: isRequired,
      label: l10n?.tr('products') ?? 'Products',
      hint: l10n?.tr('searchProductsHint') ?? 'Search Products..',
      selectedItems: selectedProducts,
      itemLabel: (p) => p.title,
      onTap: () => _showProductSearch(context),
      onDeleted: (p) {
        final updated = List<ProductLookup>.from(selectedProducts)..remove(p);
        onChanged(updated);
      },
    );
  }
}
