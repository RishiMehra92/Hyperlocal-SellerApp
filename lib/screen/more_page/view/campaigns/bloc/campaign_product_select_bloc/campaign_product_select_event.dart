part of 'campaign_product_select_bloc.dart';

abstract class CampaignProductSelectEvent {}

class LoadCampaignProductsInitial extends CampaignProductSelectEvent {
  final String? search;
  LoadCampaignProductsInitial({this.search});
}

class LoadMoreCampaignProducts extends CampaignProductSelectEvent {}

class RefreshCampaignProducts extends CampaignProductSelectEvent {}

class SearchCampaignProducts extends CampaignProductSelectEvent {
  final String query;
  SearchCampaignProducts(this.query);
}

class CampaignProductsReset extends CampaignProductSelectEvent {}
