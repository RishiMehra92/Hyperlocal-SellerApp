part of 'campaign_list_bloc.dart';

abstract class CampaignListEvent extends Equatable {
  const CampaignListEvent();

  @override
  List<Object?> get props => [];
}

class LoadCampaignsInitial extends CampaignListEvent {
  final String? search;
  final String? status;

  const LoadCampaignsInitial({this.search, this.status});

  @override
  List<Object?> get props => [search, status];
}

class SearchCampaigns extends CampaignListEvent {
  final String search;

  const SearchCampaigns(this.search);

  @override
  List<Object?> get props => [search];
}

class FilterCampaignsByStatus extends CampaignListEvent {
  final String? status;

  const FilterCampaignsByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class LoadMoreCampaigns extends CampaignListEvent {}

class RefreshCampaigns extends CampaignListEvent {}

class CampaignListReset extends CampaignListEvent {}

class _UpdateCampaignListState extends CampaignListEvent {
  final CampaignListState state;

  const _UpdateCampaignListState(this.state);

  @override
  List<Object?> get props => [state];
}
