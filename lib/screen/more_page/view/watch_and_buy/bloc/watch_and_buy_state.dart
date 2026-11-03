import 'package:equatable/equatable.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/screen/products_page/product_addons/create_product_addons/models/lookup_models.dart';
import '../model/watch_and_buy_profile_model.dart';
import '../model/watch_and_buy_reel_model.dart';
import '../model/watch_and_buy_story_model.dart';

class WatchAndBuyState extends Equatable {
  // Profile state
  final ApiStatus status;
  final WatchAndBuyProfile? profile;
  final String? errorMessage;

  final ApiStatus createStatus;
  final String? createMessage;

  // Stories state
  final ApiStatus storiesStatus;
  final List<WatchAndBuyStoryModel> stories;
  final String? storiesErrorMessage;

  final ApiStatus deleteStoryStatus;
  final String? deleteStoryMessage;

  // Create Story state
  final ApiStatus createStoryStatus;
  final String? createStoryMessage;

  // Reels state
  final ApiStatus reelsStatus;
  final List<WatchAndBuyReelModel> reels;
  final String? reelsErrorMessage;
  final bool isReelsLoadingMore;
  final int reelsPage;
  final bool reelsHasMore;

  // Create Reel state
  final ApiStatus createReelStatus;
  final String? createReelMessage;

  // Delete Reel state
  final ApiStatus deleteReelStatus;
  final String? deleteReelMessage;

  // Publish Reel state
  final ApiStatus publishReelStatus;
  final String? publishReelMessage;

  // Update Reel state
  final ApiStatus updateReelStatus;
  final String? updateReelMessage;

  // Product Lookup state
  final List<ProductLookup> lookupProducts;
  final bool isLookupProductsLoading;
  final bool isLookupProductsLoadingMore;
  final int lookupProductsPage;
  final bool lookupProductsHasMore;
  final String lookupProductsSearchQuery;

  // Eligible Products state
  final List<ProductLookup> eligibleProducts;
  final bool isEligibleProductsLoading;

  const WatchAndBuyState({
    this.status = ApiStatus.initial,
    this.profile,
    this.errorMessage,
    this.createStatus = ApiStatus.initial,
    this.createMessage,
    this.storiesStatus = ApiStatus.initial,
    this.stories = const [],
    this.storiesErrorMessage,
    this.deleteStoryStatus = ApiStatus.initial,
    this.deleteStoryMessage,
    this.createStoryStatus = ApiStatus.initial,
    this.createStoryMessage,
    this.reelsStatus = ApiStatus.initial,
    this.reels = const [],
    this.reelsErrorMessage,
    this.isReelsLoadingMore = false,
    this.reelsPage = 1,
    this.reelsHasMore = true,
    this.createReelStatus = ApiStatus.initial,
    this.createReelMessage,
    this.deleteReelStatus = ApiStatus.initial,
    this.deleteReelMessage,
    this.publishReelStatus = ApiStatus.initial,
    this.publishReelMessage,
    this.updateReelStatus = ApiStatus.initial,
    this.updateReelMessage,
    this.lookupProducts = const [],
    this.isLookupProductsLoading = false,
    this.isLookupProductsLoadingMore = false,
    this.lookupProductsPage = 1,
    this.lookupProductsHasMore = true,
    this.lookupProductsSearchQuery = '',
    this.eligibleProducts = const [],
    this.isEligibleProductsLoading = false,
  });

  WatchAndBuyState copyWith({
    ApiStatus? status,
    WatchAndBuyProfile? profile,
    String? errorMessage,
    bool clearProfile = false,
    ApiStatus? createStatus,
    String? createMessage,
    bool clearCreateState = false,
    ApiStatus? storiesStatus,
    List<WatchAndBuyStoryModel>? stories,
    String? storiesErrorMessage,
    ApiStatus? deleteStoryStatus,
    String? deleteStoryMessage,
    bool clearDeleteStoryState = false,
    ApiStatus? createStoryStatus,
    String? createStoryMessage,
    bool clearCreateStoryState = false,
    ApiStatus? reelsStatus,
    List<WatchAndBuyReelModel>? reels,
    String? reelsErrorMessage,
    bool? isReelsLoadingMore,
    int? reelsPage,
    bool? reelsHasMore,
    ApiStatus? createReelStatus,
    String? createReelMessage,
    bool clearCreateReelState = false,
    ApiStatus? deleteReelStatus,
    String? deleteReelMessage,
    bool clearDeleteReelState = false,
    ApiStatus? publishReelStatus,
    String? publishReelMessage,
    bool clearPublishReelState = false,
    ApiStatus? updateReelStatus,
    String? updateReelMessage,
    bool clearUpdateReelState = false,
    List<ProductLookup>? lookupProducts,
    bool? isLookupProductsLoading,
    bool? isLookupProductsLoadingMore,
    int? lookupProductsPage,
    bool? lookupProductsHasMore,
    String? lookupProductsSearchQuery,
    List<ProductLookup>? eligibleProducts,
    bool? isEligibleProductsLoading,
  }) {
    return WatchAndBuyState(
      status: status ?? this.status,
      profile: clearProfile ? null : (profile ?? this.profile),
      errorMessage: errorMessage ?? this.errorMessage,
      createStatus: clearCreateState
          ? ApiStatus.initial
          : (createStatus ?? this.createStatus),
      createMessage: clearCreateState
          ? null
          : (createMessage ?? this.createMessage),
      storiesStatus: storiesStatus ?? this.storiesStatus,
      stories: stories ?? this.stories,
      storiesErrorMessage: storiesErrorMessage ?? this.storiesErrorMessage,
      deleteStoryStatus: clearDeleteStoryState
          ? ApiStatus.initial
          : (deleteStoryStatus ?? this.deleteStoryStatus),
      deleteStoryMessage: clearDeleteStoryState
          ? null
          : (deleteStoryMessage ?? this.deleteStoryMessage),
      createStoryStatus: clearCreateStoryState
          ? ApiStatus.initial
          : (createStoryStatus ?? this.createStoryStatus),
      createStoryMessage: clearCreateStoryState
          ? null
          : (createStoryMessage ?? this.createStoryMessage),
      reelsStatus: reelsStatus ?? this.reelsStatus,
      reels: reels ?? this.reels,
      reelsErrorMessage: reelsErrorMessage ?? this.reelsErrorMessage,
      isReelsLoadingMore: isReelsLoadingMore ?? this.isReelsLoadingMore,
      reelsPage: reelsPage ?? this.reelsPage,
      reelsHasMore: reelsHasMore ?? this.reelsHasMore,
      createReelStatus: clearCreateReelState
          ? ApiStatus.initial
          : (createReelStatus ?? this.createReelStatus),
      createReelMessage: clearCreateReelState
          ? null
          : (createReelMessage ?? this.createReelMessage),
      deleteReelStatus: clearDeleteReelState
          ? ApiStatus.initial
          : (deleteReelStatus ?? this.deleteReelStatus),
      deleteReelMessage: clearDeleteReelState
          ? null
          : (deleteReelMessage ?? this.deleteReelMessage),
      publishReelStatus: clearPublishReelState
          ? ApiStatus.initial
          : (publishReelStatus ?? this.publishReelStatus),
      publishReelMessage: clearPublishReelState
          ? null
          : (publishReelMessage ?? this.publishReelMessage),
      updateReelStatus: clearUpdateReelState
          ? ApiStatus.initial
          : (updateReelStatus ?? this.updateReelStatus),
      updateReelMessage: clearUpdateReelState
          ? null
          : (updateReelMessage ?? this.updateReelMessage),
      lookupProducts: lookupProducts ?? this.lookupProducts,
      isLookupProductsLoading:
          isLookupProductsLoading ?? this.isLookupProductsLoading,
      isLookupProductsLoadingMore:
          isLookupProductsLoadingMore ?? this.isLookupProductsLoadingMore,
      lookupProductsPage: lookupProductsPage ?? this.lookupProductsPage,
      lookupProductsHasMore:
          lookupProductsHasMore ?? this.lookupProductsHasMore,
      lookupProductsSearchQuery:
          lookupProductsSearchQuery ?? this.lookupProductsSearchQuery,
      eligibleProducts: eligibleProducts ?? this.eligibleProducts,
      isEligibleProductsLoading:
          isEligibleProductsLoading ?? this.isEligibleProductsLoading,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    errorMessage,
    createStatus,
    createMessage,
    storiesStatus,
    stories,
    storiesErrorMessage,
    deleteStoryStatus,
    deleteStoryMessage,
    createStoryStatus,
    createStoryMessage,
    reelsStatus,
    reels,
    reelsErrorMessage,
    isReelsLoadingMore,
    reelsPage,
    reelsHasMore,
    createReelStatus,
    createReelMessage,
    deleteReelStatus,
    deleteReelMessage,
    publishReelStatus,
    publishReelMessage,
    updateReelStatus,
    updateReelMessage,
    lookupProducts,
    isLookupProductsLoading,
    isLookupProductsLoadingMore,
    lookupProductsPage,
    lookupProductsHasMore,
    lookupProductsSearchQuery,
    eligibleProducts,
    isEligibleProductsLoading,
  ];
}
