import 'package:flutter/widgets.dart';
import '../../../../../../service/language_repo.dart';
import '../../../../../../l10n/default_en_labels.dart';
import '../../../../../../extensions/translation_extension.dart';

class LimitCounterService {
  String _tr(dynamic context, String key, {List<dynamic>? positionalArgs, String? fallback}) {
    if (context is BuildContext) {
      return context.tr(key, positionalArgs: positionalArgs, fallback: fallback);
    }
    String? text = LanguageRepo.activeLabels[key]?.toString() ?? defaultEnglishLabels[key] ?? fallback ?? key;
    if (positionalArgs != null) {
      for (var i = 0; i < positionalArgs.length; i++) {
        text = text!.replaceAll('{$i}', positionalArgs[i].toString());
      }
    }
    return text ?? key;
  }

  String formatDuration(
    dynamic context,
    String durationType,
    int? durationDays,
  ) {
    if (durationType == 'unlimited') {
      return _tr(context, 'durationUnlimited', fallback: 'Unlimited');
    }
    if (durationDays != null) {
      return _tr(context, 'durationPerXDays', positionalArgs: [durationDays], fallback: '/ $durationDays days');
    }
    return durationType;
  }

  String getStoresFeatureText(int? rawLimit, [dynamic context]) {
    final limit = rawLimit ?? -1;

    if (limit < 0) {
      return _tr(context, 'featureStoresUnlimited', fallback: 'Unlimited Stores');
    }

    return _tr(context, 'featureStores', positionalArgs: [limit], fallback: 'Up to $limit ${limit > 1 ? "Stores" : "Store"}');
  }

  String getProductFeatureText(int? rawLimit, [dynamic context]) {
    final limit = rawLimit ?? -1;

    if (limit < 0) {
      return _tr(context, 'featureProductsUnlimited', fallback: 'Unlimited Products');
    }

    return _tr(context, 'featureProducts', positionalArgs: [limit], fallback: 'Up to $limit ${limit > 1 ? "Products" : "Product"}');
  }

  String getRolesFeatureText(int? rawLimit, [dynamic context]) {
    final limit = rawLimit ?? -1;

    if (limit < 0) {
      return _tr(context, 'featureRolesUnlimited', fallback: 'Unlimited Roles');
    }

    return _tr(context, 'featureRoles', positionalArgs: [limit], fallback: 'Up to $limit ${limit > 1 ? "Roles" : "Role"}');
  }

  String getSystemUserFeatureText(int? rawLimit, [dynamic context]) {
    final limit = rawLimit ?? -1;

    if (limit < 0) {
      return _tr(context, 'featureUsersUnlimited', fallback: 'Unlimited System Users');
    }

    return _tr(context, 'featureUsers', positionalArgs: [limit], fallback: 'Up to $limit ${limit > 1 ? "System Users" : "System User"}');
  }
}
