import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class WatchAndBuyEvent extends Equatable {
  const WatchAndBuyEvent();

  @override
  List<Object?> get props => [];
}

class FetchWatchAndBuyProfileEvent extends WatchAndBuyEvent {}

class CreateWatchAndBuyProfileEvent extends WatchAndBuyEvent {
  final String username;
  final String bio;
  final File? photo;

  const CreateWatchAndBuyProfileEvent({
    required this.username,
    required this.bio,
    this.photo,
  });

  @override
  List<Object?> get props => [username, bio, photo];
}

class FetchWatchAndBuyStoriesEvent extends WatchAndBuyEvent {}

class DeleteWatchAndBuyStoryEvent extends WatchAndBuyEvent {
  final int id;

  const DeleteWatchAndBuyStoryEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class CreateWatchAndBuyStoryEvent extends WatchAndBuyEvent {
  final File media;
  final String? text;
  final List<int>? attachmentIds;

  const CreateWatchAndBuyStoryEvent({
    required this.media,
    this.text,
    this.attachmentIds,
  });

  @override
  List<Object?> get props => [media, text, attachmentIds];
}

class SearchLookupProductsEvent extends WatchAndBuyEvent {
  final String query;

  const SearchLookupProductsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class LoadMoreLookupProductsEvent extends WatchAndBuyEvent {}

class FetchWatchAndBuyReelsEvent extends WatchAndBuyEvent {}

class LoadMoreWatchAndBuyReelsEvent extends WatchAndBuyEvent {}

class FetchEligibleProductsEvent extends WatchAndBuyEvent {}

class CreateWatchAndBuyReelEvent extends WatchAndBuyEvent {
  final File video;
  final File? cover;
  final String? caption;
  final String source;
  final int? profileId;
  final List<int> attachmentIds;
  final int primaryAttachmentId;

  const CreateWatchAndBuyReelEvent({
    required this.video,
    this.cover,
    this.caption,
    this.source = 'seller',
    this.profileId,
    required this.attachmentIds,
    required this.primaryAttachmentId,
  });

  @override
  List<Object?> get props => [
    video,
    cover,
    caption,
    source,
    profileId,
    attachmentIds,
    primaryAttachmentId,
  ];
}

class DeleteWatchAndBuyReelEvent extends WatchAndBuyEvent {
  final int id;

  const DeleteWatchAndBuyReelEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class PublishWatchAndBuyReelEvent extends WatchAndBuyEvent {
  final int id;
  final bool published;

  const PublishWatchAndBuyReelEvent({
    required this.id,
    required this.published,
  });

  @override
  List<Object?> get props => [id, published];
}

class UpdateWatchAndBuyReelEvent extends WatchAndBuyEvent {
  final int id;
  final File? video;
  final File? cover;
  final String? caption;
  final String source;
  final int? profileId;
  final List<int> attachmentIds;
  final int primaryAttachmentId;

  const UpdateWatchAndBuyReelEvent({
    required this.id,
    this.video,
    this.cover,
    this.caption,
    this.source = 'seller',
    this.profileId,
    required this.attachmentIds,
    required this.primaryAttachmentId,
  });

  @override
  List<Object?> get props => [
    id,
    video,
    cover,
    caption,
    source,
    profileId,
    attachmentIds,
    primaryAttachmentId,
  ];
}
