import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/api_routes.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/screen/products_page/product_addons/create_product_addons/models/lookup_models.dart';
import '../model/watch_and_buy_profile_model.dart';
import '../model/watch_and_buy_reel_model.dart';
import '../model/watch_and_buy_story_model.dart';
import 'watch_and_buy_event.dart';
import 'watch_and_buy_state.dart';

class WatchAndBuyBloc extends Bloc<WatchAndBuyEvent, WatchAndBuyState> {
  final ApiBaseHelper _helper = ApiBaseHelper();

  WatchAndBuyBloc() : super(const WatchAndBuyState()) {
    on<FetchWatchAndBuyProfileEvent>(_onFetchProfile);
    on<CreateWatchAndBuyProfileEvent>(_onCreateProfile);
    on<FetchWatchAndBuyStoriesEvent>(_onFetchStories);
    on<DeleteWatchAndBuyStoryEvent>(_onDeleteStory);
    on<CreateWatchAndBuyStoryEvent>(_onCreateStory);
    on<SearchLookupProductsEvent>(_onSearchLookupProducts);
    on<LoadMoreLookupProductsEvent>(_onLoadMoreLookupProducts);
    on<FetchWatchAndBuyReelsEvent>(_onFetchReels);
    on<LoadMoreWatchAndBuyReelsEvent>(_onLoadMoreReels);
    on<FetchEligibleProductsEvent>(_onFetchEligibleProducts);
    on<CreateWatchAndBuyReelEvent>(_onCreateReel);
    on<DeleteWatchAndBuyReelEvent>(_onDeleteReel);
    on<PublishWatchAndBuyReelEvent>(_onPublishReel);
    on<UpdateWatchAndBuyReelEvent>(_onUpdateReel);
  }

  Future<void> _onFetchProfile(
    FetchWatchAndBuyProfileEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading, errorMessage: null));
    try {
      final response = await _helper.get(ApiRoutes.watchAndBuyProfileApi);
      final success = response['success'] as bool? ?? false;
      if (success) {
        final rawData = response['data'] as Map<String, dynamic>?;
        if (rawData != null) {
          final profile = WatchAndBuyProfile.fromJson(rawData);
          emit(state.copyWith(status: ApiStatus.success, profile: profile));
        } else {
          // data is null (meaning profile does not exist yet)
          emit(state.copyWith(status: ApiStatus.success, clearProfile: true));
        }
      } else {
        emit(
          state.copyWith(
            status: ApiStatus.failure,
            errorMessage:
                response['message'] as String? ?? 'Failed to retrieve profile',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(status: ApiStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onCreateProfile(
    CreateWatchAndBuyProfileEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(state.copyWith(createStatus: ApiStatus.loading, createMessage: null));
    try {
      final Map<String, dynamic> fields = {
        'username': event.username,
        'bio': event.bio,
      };

      if (event.photo != null) {
        fields['photo'] = await MultipartFile.fromFile(event.photo!.path);
      }

      final formData = FormData.fromMap(fields);
      final response = await _helper.postMultipart(
        ApiRoutes.watchAndBuyProfileApi,
        formData,
      );

      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ?? 'Profile updated successfully';

      if (success) {
        emit(
          state.copyWith(
            createStatus: ApiStatus.success,
            createMessage: message,
          ),
        );
        // Fetch profile again on success to populate it
        add(FetchWatchAndBuyProfileEvent());
      } else {
        emit(
          state.copyWith(
            createStatus: ApiStatus.failure,
            createMessage: message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          createStatus: ApiStatus.failure,
          createMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFetchStories(
    FetchWatchAndBuyStoriesEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(
        storiesStatus: ApiStatus.loading,
        storiesErrorMessage: null,
      ),
    );
    try {
      final response = await _helper.get(ApiRoutes.watchAndBuyStoriesApi);
      final success = response['success'] as bool? ?? false;
      if (success) {
        final rawList = response['data'] as List<dynamic>? ?? [];
        final stories = rawList
            .map(
              (e) => WatchAndBuyStoryModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        emit(
          state.copyWith(storiesStatus: ApiStatus.success, stories: stories),
        );
      } else {
        emit(
          state.copyWith(
            storiesStatus: ApiStatus.failure,
            storiesErrorMessage:
                response['message'] as String? ?? 'Failed to retrieve stories',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          storiesStatus: ApiStatus.failure,
          storiesErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteStory(
    DeleteWatchAndBuyStoryEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(
        deleteStoryStatus: ApiStatus.loading,
        deleteStoryMessage: null,
      ),
    );
    try {
      final url = '${ApiRoutes.watchAndBuyStoriesApi}/${event.id}';
      final response = await _helper.delete(url);
      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ?? 'Story deleted successfully';

      if (success) {
        emit(
          state.copyWith(
            deleteStoryStatus: ApiStatus.success,
            deleteStoryMessage: message,
          ),
        );
        add(FetchWatchAndBuyStoriesEvent());
      } else {
        emit(
          state.copyWith(
            deleteStoryStatus: ApiStatus.failure,
            deleteStoryMessage: message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          deleteStoryStatus: ApiStatus.failure,
          deleteStoryMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateStory(
    CreateWatchAndBuyStoryEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(
        createStoryStatus: ApiStatus.loading,
        createStoryMessage: null,
      ),
    );
    try {
      final Map<String, dynamic> fields = {'source': 'seller'};

      if (state.profile?.id != null) {
        fields['profile_id'] = state.profile!.id;
      }

      if (event.text != null && event.text!.trim().isNotEmpty) {
        fields['text'] = event.text!.trim();
      }

      if (event.attachmentIds != null) {
        for (int i = 0; i < event.attachmentIds!.length; i++) {
          fields["attachment_ids[$i]"] = event.attachmentIds![i].toString();
        }
      }

      fields['media'] = await MultipartFile.fromFile(event.media.path);

      final formData = FormData.fromMap(fields);
      final response = await _helper.postMultipart(
        ApiRoutes.watchAndBuyStoriesApi,
        formData,
      );

      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ?? 'Story created successfully';

      if (success) {
        emit(
          state.copyWith(
            createStoryStatus: ApiStatus.success,
            createStoryMessage: message,
          ),
        );
        add(FetchWatchAndBuyStoriesEvent());
      } else {
        emit(
          state.copyWith(
            createStoryStatus: ApiStatus.failure,
            createStoryMessage: message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          createStoryStatus: ApiStatus.failure,
          createStoryMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSearchLookupProducts(
    SearchLookupProductsEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(
        isLookupProductsLoading: true,
        lookupProductsPage: 1,
        lookupProductsHasMore: true,
        lookupProductsSearchQuery: event.query,
      ),
    );
    try {
      final response = await _helper.get(
        ApiRoutes.lookupProductsApi,
        queryParameters: {'search': event.query, 'page': 1, 'limit': 15},
      );
      final List<dynamic> data = response['data'] is Map
          ? (response['data']['items'] ?? [])
          : (response['data'] ?? []);
      final products = data.map((e) => ProductLookup.fromJson(e)).toList();
      emit(
        state.copyWith(
          lookupProducts: products,
          isLookupProductsLoading: false,
          lookupProductsHasMore: products.length == 15,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLookupProductsLoading: false));
    }
  }

  Future<void> _onLoadMoreLookupProducts(
    LoadMoreLookupProductsEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    if (state.isLookupProductsLoadingMore || !state.lookupProductsHasMore) {
      return;
    }
    emit(state.copyWith(isLookupProductsLoadingMore: true));
    try {
      final nextPage = state.lookupProductsPage + 1;
      final response = await _helper.get(
        ApiRoutes.lookupProductsApi,
        queryParameters: {
          'search': state.lookupProductsSearchQuery,
          'page': nextPage,
          'limit': 15,
        },
      );
      final List<dynamic> data = response['data'] is Map
          ? (response['data']['items'] ?? [])
          : (response['data'] ?? []);
      final newProducts = data.map((e) => ProductLookup.fromJson(e)).toList();
      emit(
        state.copyWith(
          lookupProducts: [...state.lookupProducts, ...newProducts],
          lookupProductsPage: nextPage,
          isLookupProductsLoadingMore: false,
          lookupProductsHasMore: newProducts.length == 15,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLookupProductsLoadingMore: false));
    }
  }

  Future<void> _onFetchReels(
    FetchWatchAndBuyReelsEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(
        reelsStatus: ApiStatus.loading,
        reelsPage: 1,
        reelsHasMore: true,
        reelsErrorMessage: null,
      ),
    );
    try {
      final response = await _helper.get(
        ApiRoutes.watchAndBuyReelsApi,
        queryParameters: {'page': 1},
      );
      final success = response['success'] as bool? ?? false;
      if (success) {
        final List<dynamic> data = response['data'] is Map
            ? (response['data']['items'] ?? [])
            : (response['data'] ?? []);
        final reels = data
            .map((e) => WatchAndBuyReelModel.fromJson(e))
            .toList();

        final pagination = response['data'] is Map
            ? response['data']['pagination']
            : null;
        bool hasMore = reels.isNotEmpty;
        if (pagination != null) {
          final currentPage = pagination['current_page'] as int? ?? 1;
          final lastPage = pagination['last_page'] as int? ?? 1;
          hasMore = currentPage < lastPage;
        }

        emit(
          state.copyWith(
            reelsStatus: ApiStatus.success,
            reels: reels,
            reelsHasMore: hasMore,
          ),
        );
      } else {
        emit(
          state.copyWith(
            reelsStatus: ApiStatus.failure,
            reelsErrorMessage:
                response['message'] as String? ?? 'Failed to retrieve reels',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          reelsStatus: ApiStatus.failure,
          reelsErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMoreReels(
    LoadMoreWatchAndBuyReelsEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    if (state.isReelsLoadingMore || !state.reelsHasMore) return;
    emit(state.copyWith(isReelsLoadingMore: true));
    try {
      final nextPage = state.reelsPage + 1;
      final response = await _helper.get(
        ApiRoutes.watchAndBuyReelsApi,
        queryParameters: {'page': nextPage},
      );
      final success = response['success'] as bool? ?? false;
      if (success) {
        final List<dynamic> data = response['data'] is Map
            ? (response['data']['items'] ?? [])
            : (response['data'] ?? []);
        final newReels = data
            .map((e) => WatchAndBuyReelModel.fromJson(e))
            .toList();

        final pagination = response['data'] is Map
            ? response['data']['pagination']
            : null;
        bool hasMore = newReels.isNotEmpty;
        if (pagination != null) {
          final currentPage = pagination['current_page'] as int? ?? 1;
          final lastPage = pagination['last_page'] as int? ?? 1;
          hasMore = currentPage < lastPage;
        }

        emit(
          state.copyWith(
            reels: [...state.reels, ...newReels],
            reelsPage: nextPage,
            isReelsLoadingMore: false,
            reelsHasMore: hasMore,
          ),
        );
      } else {
        emit(state.copyWith(isReelsLoadingMore: false));
      }
    } catch (e) {
      emit(state.copyWith(isReelsLoadingMore: false));
    }
  }

  Future<void> _onFetchEligibleProducts(
    FetchEligibleProductsEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(
        isEligibleProductsLoading: true,
        lookupProductsSearchQuery: '',
      ),
    );
    try {
      final response = await _helper.get(
        ApiRoutes.watchAndBuyEligibleProductsApi,
      );
      final List<dynamic> data = response['data'] is List
          ? response['data']
          : [];
      final products = data.map((e) => ProductLookup.fromJson(e)).toList();
      emit(
        state.copyWith(
          eligibleProducts: products,
          isEligibleProductsLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isEligibleProductsLoading: false));
    }
  }

  Future<void> _onCreateReel(
    CreateWatchAndBuyReelEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(clearCreateReelState: true, clearUpdateReelState: true),
    );
    emit(state.copyWith(createReelStatus: ApiStatus.loading));
    try {
      final Map<String, dynamic> fields = {
        'source': event.source,
        'primary_attachment_id': event.primaryAttachmentId,
      };

      if (event.caption != null && event.caption!.isNotEmpty) {
        fields['caption'] = event.caption;
      }

      if (event.profileId != null) {
        fields['profile_id'] = event.profileId;
      } else if (state.profile?.id != null) {
        fields['profile_id'] = state.profile!.id;
      }

      for (int i = 0; i < event.attachmentIds.length; i++) {
        fields['attachment_ids[$i]'] = event.attachmentIds[i];
      }

      fields['video'] = await MultipartFile.fromFile(event.video.path);

      if (event.cover != null) {
        fields['cover'] = await MultipartFile.fromFile(event.cover!.path);
      }

      final formData = FormData.fromMap(fields);
      final response = await _helper.postMultipart(
        ApiRoutes.watchAndBuyReelsApi,
        formData,
      );

      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ?? 'Reel created successfully';

      if (success) {
        emit(
          state.copyWith(
            createReelStatus: ApiStatus.success,
            createReelMessage: message,
          ),
        );
        add(FetchWatchAndBuyReelsEvent());
      } else {
        emit(
          state.copyWith(
            createReelStatus: ApiStatus.failure,
            createReelMessage:
                response['message']?.toString() ?? 'Failed to upload reel',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          createReelStatus: ApiStatus.failure,
          createReelMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteReel(
    DeleteWatchAndBuyReelEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(
        deleteReelStatus: ApiStatus.loading,
        deleteReelMessage: null,
      ),
    );
    try {
      final url = '${ApiRoutes.watchAndBuyReelsApi}/${event.id}';
      final response = await _helper.delete(url);
      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ?? 'Reel deleted successfully';

      if (success) {
        emit(
          state.copyWith(
            deleteReelStatus: ApiStatus.success,
            deleteReelMessage: message,
          ),
        );
        add(FetchWatchAndBuyReelsEvent());
      } else {
        emit(
          state.copyWith(
            deleteReelStatus: ApiStatus.failure,
            deleteReelMessage: message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          deleteReelStatus: ApiStatus.failure,
          deleteReelMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPublishReel(
    PublishWatchAndBuyReelEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(
        publishReelStatus: ApiStatus.loading,
        publishReelMessage: null,
      ),
    );
    try {
      final url = '${ApiRoutes.watchAndBuyReelsApi}/${event.id}/publish';
      final response = await _helper.put(url, {'published': event.published});
      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ?? 'Reel updated successfully';

      if (success) {
        emit(
          state.copyWith(
            publishReelStatus: ApiStatus.success,
            publishReelMessage: message,
          ),
        );

        // Optimistically update the reel list if we don't want to re-fetch all
        final updatedReels = state.reels.map((reel) {
          if (reel.id == event.id) {
            return reel.copyWith(
              status: event.published ? 'published' : 'unpublished',
            );
          }
          return reel;
        }).toList();

        emit(state.copyWith(reels: updatedReels));
      } else {
        emit(
          state.copyWith(
            publishReelStatus: ApiStatus.failure,
            publishReelMessage: message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          publishReelStatus: ApiStatus.failure,
          publishReelMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateReel(
    UpdateWatchAndBuyReelEvent event,
    Emitter<WatchAndBuyState> emit,
  ) async {
    emit(
      state.copyWith(clearCreateReelState: true, clearUpdateReelState: true),
    );
    emit(state.copyWith(updateReelStatus: ApiStatus.loading));
    try {
      final Map<String, dynamic> fields = {
        'source': event.source,
        'primary_attachment_id': event.primaryAttachmentId,
      };

      if (event.caption != null && event.caption!.isNotEmpty) {
        fields['caption'] = event.caption;
      }

      if (event.profileId != null) {
        fields['profile_id'] = event.profileId;
      } else if (state.profile?.id != null) {
        fields['profile_id'] = state.profile!.id;
      }

      for (int i = 0; i < event.attachmentIds.length; i++) {
        fields['attachment_ids[$i]'] = event.attachmentIds[i];
      }

      if (event.video != null) {
        fields['video'] = await MultipartFile.fromFile(event.video!.path);
      }

      if (event.cover != null) {
        fields['cover'] = await MultipartFile.fromFile(event.cover!.path);
      }

      final formData = FormData.fromMap(fields);

      final url = '${ApiRoutes.watchAndBuyReelsApi}/${event.id}';
      final response = await _helper.postMultipart(url, formData);
      final success = response['success'] as bool? ?? false;
      final message =
          response['message'] as String? ?? 'Reel updated successfully';

      if (success) {
        emit(
          state.copyWith(
            updateReelStatus: ApiStatus.success,
            updateReelMessage: message,
          ),
        );
        add(FetchWatchAndBuyReelsEvent());
      } else {
        emit(
          state.copyWith(
            updateReelStatus: ApiStatus.failure,
            updateReelMessage:
                response['message']?.toString() ?? 'Failed to update reel',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          updateReelStatus: ApiStatus.failure,
          updateReelMessage: e.toString(),
        ),
      );
    }
  }
}
