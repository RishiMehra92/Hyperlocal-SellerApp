import 'package:hyper_local_seller/service/json_parser.dart';

const String modelName = 'order_model';

class OrdersResponse {
  bool? success;
  String? message;
  OrdersPageData? data;

  OrdersResponse({this.success, this.message, this.data});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) {
    return OrdersResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? OrdersPageData.fromJson(json['data'] as Map<String, dynamic>)
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

class OrdersPageData {
  int? currentPage;
  int? lastPage;
  int? perPage;
  int? total;
  List<SellerOrderItem>? items;

  OrdersPageData({
    this.currentPage,
    this.lastPage,
    this.perPage,
    this.total,
    this.items,
  });

  factory OrdersPageData.fromJson(Map<String, dynamic> json) {
    return OrdersPageData(
      currentPage: JsonParser.intValue(json['current_page'] ?? 1),
      lastPage: JsonParser.intValue(json['last_page'] ?? 1),
      perPage: JsonParser.intValue(json['per_page'] ?? 15),
      total: JsonParser.intValue(json['total'] ?? 0),

      items: JsonParser.list<SellerOrderItem>(
        json['data'],
        (v) => SellerOrderItem.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['current_page'] = currentPage;
    data['last_page'] = lastPage;
    data['per_page'] = perPage;
    data['total'] = total;
    if (items != null) {
      data['data'] = items!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class SellerOrderItem {
  int orderItemId;
  int sellerOrderId;
  String createdAt;
  bool isRushOrder;
  String? deliveryType;
  String? scheduledDate;
  int? deliveryTimeSlotId;
  String? scheduledTimeSlotLabel;
  String? rescheduleStatus;
  String? rescheduleReason;
  String? rescheduleDeadline;
  String status;
  AcceptanceTimeout? acceptanceTimeout;
  num finalTotal;
  List<OrderItemData> items;

  SellerOrderItem({
    required this.orderItemId,
    required this.sellerOrderId,
    required this.createdAt,
    required this.isRushOrder,
    this.deliveryType,
    this.scheduledDate,
    this.deliveryTimeSlotId,
    this.scheduledTimeSlotLabel,
    this.rescheduleStatus,
    this.rescheduleReason,
    this.rescheduleDeadline,
    required this.status,
    this.acceptanceTimeout,
    required this.finalTotal,
    required this.items,
  });

  factory SellerOrderItem.fromJson(Map<String, dynamic> json) {
    return SellerOrderItem(
      orderItemId: JsonParser.intValue(json["id"]),
      sellerOrderId: JsonParser.intValue(json["order_id"]),
      createdAt: JsonParser.string(json["created_at"] ?? ""),
      isRushOrder: JsonParser.intValue(json["is_rush_order"]) == 1 || JsonParser.boolValue(json["is_rush_order"]),
      deliveryType: JsonParser.string(json["delivery_type"]),
      scheduledDate: json["scheduled_date"] != null ? JsonParser.string(json["scheduled_date"]) : null,
      deliveryTimeSlotId: json["delivery_time_slot_id"] != null ? JsonParser.intValue(json["delivery_time_slot_id"]) : null,
      scheduledTimeSlotLabel: json["scheduled_time_slot_label"] != null ? JsonParser.string(json["scheduled_time_slot_label"]) : null,
      rescheduleStatus: json["reschedule_status"] != null ? JsonParser.string(json["reschedule_status"]) : null,
      rescheduleReason: json["reschedule_reason"] != null ? JsonParser.string(json["reschedule_reason"]) : null,
      rescheduleDeadline: json["reschedule_deadline"] != null ? JsonParser.string(json["reschedule_deadline"]) : null,
      status: JsonParser.string(json["status"] ?? "pending"),
      acceptanceTimeout: json["acceptance_timeout"] != null
          ? AcceptanceTimeout.fromJson(
              json["acceptance_timeout"] as Map<String, dynamic>,
            )
          : null,
      finalTotal: JsonParser.doubleValue(json["final_total"] ?? json["total_price"] ?? 0),
      items: JsonParser.list<OrderItemData>(
        json["items"],
        (v) => OrderItemData.fromJson(v as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["order_item_id"] = orderItemId;
    data["seller_order_id"] = sellerOrderId;
    data["created_at"] = createdAt;
    data["is_rush_order"] = isRushOrder;
    data["delivery_type"] = deliveryType;
    data["scheduled_date"] = scheduledDate;
    data["delivery_time_slot_id"] = deliveryTimeSlotId;
    data["scheduled_time_slot_label"] = scheduledTimeSlotLabel;
    data["reschedule_status"] = rescheduleStatus;
    data["reschedule_reason"] = rescheduleReason;
    data["reschedule_deadline"] = rescheduleDeadline;
    data["status"] = status;
    data["final_total"] = finalTotal;
    data["items"] = items.map((e) => e.toJson()).toList();
    if (acceptanceTimeout != null) {
      data["acceptance_timeout"] = acceptanceTimeout!.toJson();
    }
    return data;
  }

  SellerOrderItem copyWith({
    String? status,
  }) {
    return SellerOrderItem(
      orderItemId: orderItemId,
      sellerOrderId: sellerOrderId,
      createdAt: createdAt,
      isRushOrder: isRushOrder,
      deliveryType: deliveryType,
      scheduledDate: scheduledDate,
      deliveryTimeSlotId: deliveryTimeSlotId,
      scheduledTimeSlotLabel: scheduledTimeSlotLabel,
      rescheduleStatus: rescheduleStatus,
      rescheduleReason: rescheduleReason,
      rescheduleDeadline: rescheduleDeadline,
      status: status ?? this.status,
      acceptanceTimeout: acceptanceTimeout,
      finalTotal: finalTotal,
      items: items,
    );
  }
}

class OrderItemData {
  final int id;
  final String title;
  final num price;
  final int quantity;
  final List<String> images;

  OrderItemData({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.images,
  });

  factory OrderItemData.fromJson(Map<String, dynamic> json) {
    String title = "";
    if (json["product"] != null) {
      title = JsonParser.string(json["product"]["title"] ?? "");
    }
    
    List<String> imgs = [];
    if (json["image"] != null) {
      imgs.add(JsonParser.string(json["image"]));
    } else if (json["product"] != null && json["product"]["main_image"] != null) {
      imgs.add(JsonParser.string(json["product"]["main_image"]));
    } else if (json["product"] != null && json["product"]["image"] != null) {
      imgs.add(JsonParser.string(json["product"]["image"]));
    }
    if (json["attachments"] != null && json["attachments"] is List) {
       for (var att in (json["attachments"] as List)) {
           if (att is Map && att["url"] != null) {
               imgs.add(att["url"].toString());
           } else if (att is String) {
               imgs.add(att);
           }
       }
    }

    return OrderItemData(
      id: json["orderItem"] != null 
          ? JsonParser.intValue(json["orderItem"]["id"] ?? json["id"] ?? 0)
          : JsonParser.intValue(json["id"] ?? 0),
      title: title,
      price: JsonParser.doubleValue(json["price"] ?? json["sub_total"] ?? 0),
      quantity: JsonParser.intValue(json["quantity"] ?? 1),
      images: imgs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "price": price,
      "quantity": quantity,
      "images": images,
    };
  }
}

class OrderInfo {
  int id;
  String uuid;
  String buyerName;
  String paymentMethod;
  bool isRushOrder;
  String status;
  String image;
  String? deliveryType;
  String? scheduledDate;
  int? deliveryTimeSlotId;
  String? scheduledTimeSlotLabel;
  String? rescheduleStatus;
  String? rescheduleReason;
  String? rescheduleDeadline;
  String? scheduledSlotStartTime;
  String? scheduledSlotEndTime;
  AcceptanceTimeout? acceptanceTimeout;

  OrderInfo({
    this.id = 0,
    this.uuid = '',
    this.buyerName = '',
    this.paymentMethod = '',
    this.isRushOrder = false,
    this.status = '',
    this.image = '',
    this.deliveryType,
    this.scheduledDate,
    this.deliveryTimeSlotId,
    this.scheduledTimeSlotLabel,
    this.rescheduleStatus,
    this.rescheduleReason,
    this.rescheduleDeadline,
    this.scheduledSlotStartTime,
    this.scheduledSlotEndTime,
    this.acceptanceTimeout,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      id: JsonParser.intValue(json['id'] ?? 0),
      uuid: JsonParser.string(json['uuid'] ?? ''),
      buyerName: JsonParser.string(json['buyer_name'] ?? 'Guest'),
      paymentMethod: JsonParser.string(json['payment_method'] ?? 'cod'),
      isRushOrder: JsonParser.boolValue(json['is_rush_order'] ?? false),
      status: JsonParser.string(json['status'] ?? ''),
      image: JsonParser.string(json['image'] ?? ''),
      deliveryType: JsonParser.string(json['delivery_type']),
      scheduledDate: json['scheduled_date'] == null
          ? null
          : JsonParser.string(json['scheduled_date']),
      deliveryTimeSlotId: json['delivery_time_slot_id'] == null
          ? null
          : JsonParser.intValue(json['delivery_time_slot_id']),
      scheduledTimeSlotLabel: JsonParser.string(
        json['scheduled_time_slot_label'],
      ),
      rescheduleStatus: json['reschedule_status'] == null
          ? null
          : JsonParser.string(json['reschedule_status']),
      rescheduleReason: json['reschedule_reason'] == null
          ? null
          : JsonParser.string(json['reschedule_reason']),
      rescheduleDeadline: json['reschedule_deadline'] == null
          ? null
          : JsonParser.string(json['reschedule_deadline']),
      scheduledSlotStartTime: json['scheduled_slot_start_time'] == null
          ? null
          : JsonParser.string(json['scheduled_slot_start_time']),
      scheduledSlotEndTime: json['scheduled_slot_end_time'] == null
          ? null
          : JsonParser.string(json['scheduled_slot_end_time']),
      acceptanceTimeout: json['acceptance_timeout'] != null
          ? AcceptanceTimeout.fromJson(
              json['acceptance_timeout'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['buyer_name'] = buyerName;
    data['payment_method'] = paymentMethod;
    data['is_rush_order'] = isRushOrder;
    data['status'] = status;
    data['image'] = image;
    data['delivery_type'] = deliveryType;
    data['scheduled_date'] = scheduledDate;
    data['delivery_time_slot_id'] = deliveryTimeSlotId;
    data['scheduled_time_slot_label'] = scheduledTimeSlotLabel;
    data['reschedule_status'] = rescheduleStatus;
    data['reschedule_reason'] = rescheduleReason;
    data['reschedule_deadline'] = rescheduleDeadline;
    data['scheduled_slot_start_time'] = scheduledSlotStartTime;
    data['scheduled_slot_end_time'] = scheduledSlotEndTime;
    return data;
  }
}

class ProductInfo {
  int id;
  String title;
  String variant;

  ProductInfo({this.id = 0, this.title = '', this.variant = ''});

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: JsonParser.intValue(json['id'] ?? 0),
      title: JsonParser.string(json['title'] ?? ''),
      variant: JsonParser.string(json['variant'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['variant'] = variant;
    return data;
  }
}

class StoreInfo {
  String name;

  StoreInfo({this.name = ''});

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(name: JsonParser.string(json['name'] ?? ''));
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    return data;
  }
}

class SubtotalInfo {
  int raw;
  String formatted;

  SubtotalInfo({this.raw = 0, this.formatted = '\$0.00'});

  factory SubtotalInfo.fromJson(Map<String, dynamic> json) {
    return SubtotalInfo(
      raw: JsonParser.intValue(json['raw'] ?? 0),
      formatted: JsonParser.string(json['formatted'] ?? '\$0.00'),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['raw'] = raw;
    data['formatted'] = formatted;
    return data;
  }
}

class AcceptanceTimeout {
  bool enabled;
  int minutes;
  String type;
  String? deadline;

  AcceptanceTimeout({
    this.enabled = false,
    this.minutes = 0,
    this.type = '',
    this.deadline,
  });

  factory AcceptanceTimeout.fromJson(Map<String, dynamic> json) {
    return AcceptanceTimeout(
      enabled: JsonParser.boolValue(json['enabled'] ?? false),
      minutes: JsonParser.intValue(json['minutes'] ?? 0),
      type: JsonParser.string(json['type'] ?? ''),
      deadline: json['deadline'] == null
          ? null
          : JsonParser.string(json['deadline']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['enabled'] = enabled;
    data['minutes'] = minutes;
    data['type'] = type;
    data['deadline'] = deadline;
    return data;
  }
}
