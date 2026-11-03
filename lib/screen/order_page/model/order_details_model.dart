import 'package:hyper_local_seller/service/json_parser.dart';
import 'package:hyper_local_seller/screen/order_page/model/order_model.dart';

const String modelName = 'order_details_model';

class OrderDetailsResponse {
  bool? success;
  String? message;
  OrderDetailsData? data;

  OrderDetailsResponse({this.success, this.message, this.data});

  factory OrderDetailsResponse.fromJson(Map<String, dynamic> json) {
    return OrderDetailsResponse(
      success: JsonParser.boolValue(json['success'] ?? false),
      message: JsonParser.string(json['message'] ?? ''),
      data: json['data'] != null
          ? OrderDetailsData.fromJson(json['data'] as Map<String, dynamic>)
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

class OrderDetailsData {
  int id;
  int orderId;
  String uuid;
  String email;
  String status;
  String paymentMethod;
  String paymentStatus;
  String totalPrice;
  String billingName;
  String billingPhone;
  String shippingName;
  String shippingAddress1;
  String? shippingAddress2;
  String? shippingLandmark;
  String shippingCity;
  String shippingState;
  String shippingZip;
  String shippingCountry;
  String shippingPhone;
  String? orderNote;
  List<OrderItemDetail>? items;
  String createdAt;
  int isRushedOrder;
  String? deliveryType;
  String? readyForPickupAt;
  String? pickedUpAt;
  bool isScheduledDelivery;
  String? scheduledDate;
  int? deliveryTimeSlotId;
  String? scheduledTimeSlotLabel;
  String? rescheduleStatus;
  String? rescheduleReason;
  String? rescheduleDeadline;
  String? scheduledSlotStartTime;
  String? scheduledSlotEndTime;
  DeliveryBoy? deliveryBoy;
  AcceptanceTimeout? acceptanceTimeout;

  OrderDetailsData({
    required this.id,
    required this.orderId,
    required this.uuid,
    required this.email,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalPrice,
    required this.billingName,
    required this.billingPhone,
    required this.shippingName,
    required this.shippingAddress1,
    this.shippingAddress2,
    this.shippingLandmark,
    required this.shippingCity,
    required this.shippingState,
    required this.shippingZip,
    required this.shippingCountry,
    required this.shippingPhone,
    this.orderNote,
    this.items,
    required this.createdAt,
    required this.isRushedOrder,
    this.deliveryType,
    this.readyForPickupAt,
    this.pickedUpAt,
    this.isScheduledDelivery = false,
    this.scheduledDate,
    this.deliveryTimeSlotId,
    this.scheduledTimeSlotLabel,
    this.rescheduleStatus,
    this.rescheduleReason,
    this.rescheduleDeadline,
    this.scheduledSlotStartTime,
    this.scheduledSlotEndTime,
    this.deliveryBoy,
    this.acceptanceTimeout,
  });

  factory OrderDetailsData.fromJson(Map<String, dynamic> json) {
    return OrderDetailsData(
      id: JsonParser.requireInt(json['id'], model: modelName, field: 'id'),
      orderId: JsonParser.intValue(json['order_id'] ?? 0),
      uuid: JsonParser.requireString(
        json['uuid'],
        model: modelName,
        field: 'uuid',
      ),
      email: JsonParser.string(json['email'] ?? ''),
      status: JsonParser.string(json['status'] ?? 'pending'),
      paymentMethod: JsonParser.string(json['payment_method'] ?? 'cod'),
      paymentStatus: JsonParser.string(json['payment_status'] ?? 'pending'),
      totalPrice: JsonParser.string(json['total_price'] ?? '0.00'),
      billingName: JsonParser.string(json['billing_name'] ?? ''),
      billingPhone: JsonParser.string(json['billing_phone'] ?? ''),
      shippingName: JsonParser.string(json['shipping_name'] ?? ''),
      shippingAddress1: JsonParser.string(json['shipping_address_1'] ?? ''),
      shippingAddress2: JsonParser.string(json['shipping_address_2']),
      shippingLandmark: JsonParser.string(json['shipping_landmark']),
      shippingCity: JsonParser.string(json['shipping_city'] ?? ''),
      shippingState: JsonParser.string(json['shipping_state'] ?? ''),
      shippingZip: JsonParser.string(json['shipping_zip'] ?? ''),
      shippingCountry: JsonParser.string(json['shipping_country'] ?? 'India'),
      shippingPhone: JsonParser.string(json['shipping_phone'] ?? ''),
      orderNote: JsonParser.string(json['order_note']),
      items: JsonParser.list<OrderItemDetail>(
        json['items'],
        (v) => OrderItemDetail.fromJson(v as Map<String, dynamic>),
      ),
      createdAt: JsonParser.string(json['created_at'] ?? ''),
      isRushedOrder: JsonParser.requireInt(
        json['is_rush_order'],
        model: modelName,
        field: 'isRushOrder',
      ),
      deliveryType: JsonParser.string(json['delivery_type']),
      readyForPickupAt: JsonParser.string(json['ready_for_pickup_at']),
      pickedUpAt: JsonParser.string(json['picked_up_at']),
      isScheduledDelivery: JsonParser.boolValue(
        json['is_scheduled_delivery'] ?? false,
      ),
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
      deliveryBoy: json['delivery_boy'] != null
          ? DeliveryBoy.fromJson(json['delivery_boy'] as Map<String, dynamic>)
          : null,
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
    data['order_id'] = orderId;
    data['uuid'] = uuid;
    data['email'] = email;
    data['status'] = status;
    data['payment_method'] = paymentMethod;
    data['payment_status'] = paymentStatus;
    data['total_price'] = totalPrice;
    data['billing_name'] = billingName;
    data['billing_phone'] = billingPhone;
    data['shipping_name'] = shippingName;
    data['shipping_address_1'] = shippingAddress1;
    data['shipping_address_2'] = shippingAddress2;
    data['shipping_landmark'] = shippingLandmark;
    data['shipping_city'] = shippingCity;
    data['shipping_state'] = shippingState;
    data['shipping_zip'] = shippingZip;
    data['shipping_country'] = shippingCountry;
    data['shipping_phone'] = shippingPhone;
    data['order_note'] = orderNote;
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['is_rush_order'] = isRushedOrder;
    data['delivery_type'] = deliveryType;
    data['ready_for_pickup_at'] = readyForPickupAt;
    data['is_scheduled_delivery'] = isScheduledDelivery;
    data['scheduled_date'] = scheduledDate;
    data['delivery_time_slot_id'] = deliveryTimeSlotId;
    data['scheduled_time_slot_label'] = scheduledTimeSlotLabel;
    data['picked_up_at'] = pickedUpAt;
    data['reschedule_status'] = rescheduleStatus;
    data['reschedule_reason'] = rescheduleReason;
    data['reschedule_deadline'] = rescheduleDeadline;
    data['scheduled_slot_start_time'] = scheduledSlotStartTime;
    data['scheduled_slot_end_time'] = scheduledSlotEndTime;
    if (deliveryBoy != null) {
      data['delivery_boy'] = deliveryBoy!.toJson();
    }
    return data;
  }

  OrderDetailsData copyWith({
    int? id,
    int? orderId,
    String? uuid,
    String? email,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    String? totalPrice,
    String? billingName,
    String? billingPhone,
    String? shippingName,
    String? shippingAddress1,
    String? shippingAddress2,
    String? shippingLandmark,
    String? shippingCity,
    String? shippingState,
    String? shippingZip,
    String? shippingCountry,
    String? shippingPhone,
    String? orderNote,
    List<OrderItemDetail>? items,
    String? createdAt,
    int? isRushedOrder,
    String? deliveryType,
    String? readyForPickupAt,
    String? pickedUpAt,
    bool? isScheduledDelivery,
    String? scheduledDate,
    int? deliveryTimeSlotId,
    String? scheduledTimeSlotLabel,
    String? rescheduleStatus,
    String? rescheduleReason,
    String? rescheduleDeadline,
    String? scheduledSlotStartTime,
    String? scheduledSlotEndTime,
    DeliveryBoy? deliveryBoy,
  }) {
    return OrderDetailsData(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalPrice: totalPrice ?? this.totalPrice,
      billingName: billingName ?? this.billingName,
      billingPhone: billingPhone ?? this.billingPhone,
      shippingName: shippingName ?? this.shippingName,
      shippingAddress1: shippingAddress1 ?? this.shippingAddress1,
      shippingAddress2: shippingAddress2 ?? this.shippingAddress2,
      shippingLandmark: shippingLandmark ?? this.shippingLandmark,
      shippingCity: shippingCity ?? this.shippingCity,
      shippingState: shippingState ?? this.shippingState,
      shippingZip: shippingZip ?? this.shippingZip,
      shippingCountry: shippingCountry ?? this.shippingCountry,
      shippingPhone: shippingPhone ?? this.shippingPhone,
      orderNote: orderNote ?? this.orderNote,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      isRushedOrder: isRushedOrder ?? this.isRushedOrder,
      deliveryType: deliveryType ?? this.deliveryType,
      readyForPickupAt: readyForPickupAt ?? this.readyForPickupAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      isScheduledDelivery: isScheduledDelivery ?? this.isScheduledDelivery,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      deliveryTimeSlotId: deliveryTimeSlotId ?? this.deliveryTimeSlotId,
      scheduledTimeSlotLabel: scheduledTimeSlotLabel ?? this.scheduledTimeSlotLabel,
      rescheduleStatus: rescheduleStatus ?? this.rescheduleStatus,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
      rescheduleDeadline: rescheduleDeadline ?? this.rescheduleDeadline,
      scheduledSlotStartTime: scheduledSlotStartTime ?? this.scheduledSlotStartTime,
      scheduledSlotEndTime: scheduledSlotEndTime ?? this.scheduledSlotEndTime,
      deliveryBoy: deliveryBoy ?? this.deliveryBoy,
    );
  }
}

class OrderItemDetail {
  int id;
  List<dynamic>? attachments;
  OrderItemStatus? orderItem;
  ProductDetail? product;
  VariantDetail? variant;
  dynamic store;
  String price;
  String taxAmount;
  String subTotal;
  int quantity;
  int subtotal;
  List<OrderAddon>? addons;
  double addonsTotal;
  String image;

  OrderItemDetail({
    required this.id,
    this.attachments,
    this.orderItem,
    this.product,
    this.variant,
    this.store,
    required this.price,
    required this.taxAmount,
    required this.subTotal,
    required this.quantity,
    required this.subtotal,
    this.addons,
    required this.addonsTotal,
    required this.image,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      id: JsonParser.requireInt(
        json['id'],
        model: modelName,
        field: 'items[].id',
      ),
      attachments: JsonParser.list<dynamic>(json['attachments'], (v) => v),
      orderItem: json['orderItem'] != null
          ? OrderItemStatus.fromJson(json['orderItem'] as Map<String, dynamic>)
          : null,
      product: json['product'] != null
          ? ProductDetail.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      variant: json['variant'] != null
          ? VariantDetail.fromJson(json['variant'] as Map<String, dynamic>)
          : null,
      store: json['store'],
      price: JsonParser.string(json['price'] ?? '0.00'),
      taxAmount: JsonParser.string(json['tax_amount'] ?? '0.00'),
      subTotal: JsonParser.string(json['sub_total'] ?? '0.00'),
      quantity: JsonParser.intValue(json['quantity'] ?? 1),
      subtotal: JsonParser.intValue(json['subtotal'] ?? 0),
      addons: JsonParser.list<OrderAddon>(
        json['addons'],
        (v) => OrderAddon.fromJson(v as Map<String, dynamic>),
      ),
      addonsTotal: JsonParser.doubleValue(json['addons_total'] ?? 0.0),
      image: JsonParser.string(
        json['image'] ??
            (json['product'] != null ? json['product']['main_image'] : null) ??
            (json['product'] != null ? json['product']['image'] : null) ??
            '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['attachments'] = attachments;
    if (orderItem != null) data['orderItem'] = orderItem!.toJson();
    if (product != null) data['product'] = product!.toJson();
    if (variant != null) data['variant'] = variant!.toJson();
    data['store'] = store;
    data['price'] = price;
    data['tax_amount'] = taxAmount;
    data['sub_total'] = subTotal;
    data['quantity'] = quantity;
    data['subtotal'] = subtotal;
    if (addons != null) {
      data['addons'] = addons!.map((v) => v.toJson()).toList();
    }
    data['addons_total'] = addonsTotal;
    return data;
  }
}

class OrderItemStatus {
  int id;
  String status;
  String statusFormatted;

  OrderItemStatus({
    required this.id,
    required this.status,
    required this.statusFormatted,
  });

  factory OrderItemStatus.fromJson(Map<String, dynamic> json) {
    return OrderItemStatus(
      id: JsonParser.intValue(json['id'] ?? 0),
      status: JsonParser.string(json['status'] ?? ''),
      statusFormatted: JsonParser.string(json['status_formatted'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['status'] = status;
    data['status_formatted'] = statusFormatted;
    return data;
  }
}

class ProductDetail {
  int id;
  String title;

  ProductDetail({required this.id, required this.title});

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: JsonParser.intValue(json['id'] ?? 0),
      title: JsonParser.string(json['title'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    return data;
  }
}

class VariantDetail {
  int id;
  String title;

  VariantDetail({required this.id, required this.title});

  factory VariantDetail.fromJson(Map<String, dynamic> json) {
    return VariantDetail(
      id: JsonParser.intValue(json['id'] ?? 0),
      title: JsonParser.string(json['title'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    return data;
  }
}

class OrderAddon {
  int id;
  String uuid;
  int addonGroupId;
  int addonItemId;
  double price;
  AddonGroup? group;
  AddonItem? item;

  OrderAddon({
    required this.id,
    required this.uuid,
    required this.addonGroupId,
    required this.addonItemId,
    required this.price,
    this.group,
    this.item,
  });

  factory OrderAddon.fromJson(Map<String, dynamic> json) {
    return OrderAddon(
      id: JsonParser.requireInt(
        json['id'],
        model: modelName,
        field: 'addon.id',
      ),
      uuid: JsonParser.requireString(
        json['uuid'],
        model: modelName,
        field: 'addon.uuid',
      ),
      addonGroupId: JsonParser.intValue(json['addon_group_id'] ?? 0),
      addonItemId: JsonParser.intValue(json['addon_item_id'] ?? 0),
      price: JsonParser.doubleValue(json['price'] ?? 0.0),
      group: json['group'] != null
          ? AddonGroup.fromJson(json['group'] as Map<String, dynamic>)
          : null,
      item: json['item'] != null
          ? AddonItem.fromJson(json['item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['uuid'] = uuid;
    data['addon_group_id'] = addonGroupId;
    data['addon_item_id'] = addonItemId;
    data['price'] = price;
    if (group != null) data['group'] = group!.toJson();
    if (item != null) data['item'] = item!.toJson();
    return data;
  }
}

class AddonGroup {
  int id;
  String title;
  String selectionType;
  bool isRequired;

  AddonGroup({
    required this.id,
    required this.title,
    required this.selectionType,
    required this.isRequired,
  });

  factory AddonGroup.fromJson(Map<String, dynamic> json) {
    return AddonGroup(
      id: JsonParser.intValue(json['id'] ?? 0),
      title: JsonParser.string(json['title'] ?? ''),
      selectionType: JsonParser.string(json['selection_type'] ?? 'multiple'),
      isRequired: JsonParser.boolValue(json['is_required'] ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['selection_type'] = selectionType;
    data['is_required'] = isRequired;
    return data;
  }
}

class AddonItem {
  int id;
  String title;
  String? indicator;

  AddonItem({required this.id, required this.title, this.indicator});

  factory AddonItem.fromJson(Map<String, dynamic> json) {
    return AddonItem(
      id: JsonParser.intValue(json['id'] ?? 0),
      title: JsonParser.string(json['title'] ?? ''),
      indicator: JsonParser.string(json['indicator'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['indicator'] = indicator;
    return data;
  }
}

class DeliveryBoy {
  int id;
  String fullName;
  String email;
  String mobile;
  String status;
  String statusLabel;
  bool isBlocked;

  DeliveryBoy({
    required this.id,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.status,
    required this.statusLabel,
    required this.isBlocked,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) {
    return DeliveryBoy(
      id: JsonParser.intValue(json['id'] ?? 0),
      fullName: JsonParser.string(json['full_name'] ?? ''),
      email: JsonParser.string(json['email'] ?? ''),
      mobile: JsonParser.string(json['mobile'] ?? ''),
      status: JsonParser.string(json['status'] ?? ''),
      statusLabel: JsonParser.string(json['status_label'] ?? ''),
      isBlocked: JsonParser.boolValue(json['is_blocked'] ?? false),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['full_name'] = fullName;
    data['email'] = email;
    data['mobile'] = mobile;
    data['status'] = status;
    data['status_label'] = statusLabel;
    data['is_blocked'] = isBlocked;
    return data;
  }
}
