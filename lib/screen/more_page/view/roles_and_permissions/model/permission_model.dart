import 'package:hyper_local_seller/service/json_parser.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';

const String modelName = 'seller_permissions_model';

class SellerPermissionsResponse {
  bool? success;
  String? message;
  SellerPermissionsData? data;

  SellerPermissionsResponse({this.success, this.message, this.data});

  factory SellerPermissionsResponse.fromJson(Map<String, dynamic> json) {
    return SellerPermissionsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? SellerPermissionsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class SellerPermissionsData {
  RoleBasic? role;
  GroupedPermissions? groupedPermissions;
  List<String> assigned;

  SellerPermissionsData({
    this.role,
    this.groupedPermissions,
    this.assigned = const [],
  });

  factory SellerPermissionsData.fromJson(Map<String, dynamic> json) {
    return SellerPermissionsData(
      role: json['role'] != null
          ? RoleBasic.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      groupedPermissions: json['grouped_permissions'] != null
          ? GroupedPermissions.fromJson(
              json['grouped_permissions'] as Map<String, dynamic>,
            )
          : null,
      assigned: JsonParser.list<String>(
        json['assigned'],
        (v) => JsonParser.string(v),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (role != null) data['role'] = role!.toJson();
    if (groupedPermissions != null) {
      data['grouped_permissions'] = groupedPermissions!.toJson();
    }
    data['assigned'] = assigned;
    return data;
  }
}

class RoleBasic {
  int id;
  String name;

  RoleBasic({required this.id, required this.name});

  factory RoleBasic.fromJson(Map<String, dynamic> json) {
    return RoleBasic(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'role.id'),
      name: JsonParser.requireString(
        json['name'],
        model: modelName,
        field: 'role.name',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

class GroupedPermissions {
  /// Dynamic list of permission groups — automatically picks up
  /// every key the API returns under `grouped_permissions`.
  /// Return Orders is also available when omitted from an older API catalog.
  final List<PermissionGroup> groups;

  GroupedPermissions({this.groups = const []});

  factory GroupedPermissions.fromJson(Map<String, dynamic> json) {
    final List<PermissionGroup> parsedGroups = [];
    for (final entry in json.entries) {
      if (entry.value is Map<String, dynamic>) {
        parsedGroups.add(
          PermissionGroup.fromJson(
            entry.value as Map<String, dynamic>,
            key: entry.key,
          ),
        );
      }
    }
    final returnPermissions = [
      AppPermissions.returnView,
      AppPermissions.returnDecide,
    ];
    final returnGroupIndex = parsedGroups.indexWhere(
      (group) =>
          group.key == 'return' ||
          group.permissions.any(returnPermissions.contains),
    );
    if (returnGroupIndex == -1) {
      parsedGroups.add(
        PermissionGroup(
          key: 'return',
          name: 'Return Orders',
          permissions: returnPermissions,
        ),
      );
    } else {
      final group = parsedGroups[returnGroupIndex];
      parsedGroups[returnGroupIndex] = PermissionGroup(
        key: group.key,
        name: group.name.isEmpty ? 'Return Orders' : group.name,
        permissions: {...group.permissions, ...returnPermissions}.toList(),
      );
    }
    return GroupedPermissions(groups: parsedGroups);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    for (final group in groups) {
      data[group.key] = group.toJson();
    }
    return data;
  }
}

class PermissionGroup {
  /// The original JSON key (e.g. 'ad_wallet', 'store', 'pos').
  String key;
  String name;
  List<String> permissions;

  PermissionGroup({
    required this.key,
    required this.name,
    this.permissions = const [],
  });

  factory PermissionGroup.fromJson(
    Map<String, dynamic> json, {
    String key = '',
  }) {
    return PermissionGroup(
      key: key,
      name: JsonParser.string(json['name'] ?? ''),
      permissions: JsonParser.list<String>(
        json['permissions'],
        (v) => JsonParser.string(v),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['permissions'] = permissions;
    return data;
  }
}
