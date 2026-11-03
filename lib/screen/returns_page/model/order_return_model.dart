import 'package:hyper_local_seller/service/json_parser.dart';

Map<String, dynamic> returnJsonMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<String> _strings(dynamic value) => JsonParser.list(
  value,
  (e) => JsonParser.string(e),
).where((e) => e.isNotEmpty).toList();
double? _amount(dynamic value) =>
    value == null ? null : double.tryParse(value.toString());

class ReturnParty {
  final int? id;
  final String name, mobile, email, image;
  ReturnParty.fromJson(Map<String, dynamic> json)
    : id = json['id'] == null ? null : JsonParser.intValue(json['id']),
      name = JsonParser.string(json['name']),
      mobile = JsonParser.string(json['mobile']),
      email = JsonParser.string(json['email']),
      image = JsonParser.string(json['image']);
}

class ReturnAddon {
  final int? id;
  final String title;
  final double? price;
  ReturnAddon.fromJson(Map<String, dynamic> json)
    : id = json['id'] == null ? null : JsonParser.intValue(json['id']),
      title = JsonParser.string(json['title']),
      price = _amount(json['price']);
}

class ReturnProduct {
  final int? id, quantity;
  final String title, variantTitle, image;
  final double? unitPrice;
  final List<ReturnAddon> addons;
  ReturnProduct.fromJson(Map<String, dynamic> json)
    : id = json['id'] == null ? null : JsonParser.intValue(json['id']),
      quantity = json['quantity'] == null
          ? null
          : JsonParser.intValue(json['quantity']),
      title = JsonParser.string(json['title']),
      variantTitle = JsonParser.string(json['variant_title']),
      image = JsonParser.string(json['image']),
      unitPrice = _amount(json['unit_price']),
      addons = JsonParser.list(
        json['addons'],
        (e) => ReturnAddon.fromJson(returnJsonMap(e)),
      );
}

class ReturnCustomerRequest {
  final int? reasonId;
  final String reason, description;
  final List<String> proofImages;
  ReturnCustomerRequest.fromJson(Map<String, dynamic> json)
    : reasonId = json['reason_id'] == null
          ? null
          : JsonParser.intValue(json['reason_id']),
      reason = JsonParser.string(json['reason_name'] ?? json['reason']),
      description = JsonParser.string(
        json['reason_description'] ?? json['description'],
      ),
      proofImages = _strings(json['proof_images']);
}

class ReturnPickup {
  final int? riderId;
  final String riderName, riderMobile, condition, remarks, otp;
  final bool? otpRequired, otpVerified;
  final DateTime? pickedUpAt;
  final List<String> photos;
  ReturnPickup.fromJson(Map<String, dynamic> json)
    : riderId = json['rider_id'] == null
          ? null
          : JsonParser.intValue(json['rider_id']),
      riderName = JsonParser.string(json['rider_name']),
      riderMobile = JsonParser.string(json['rider_mobile']),
      condition = JsonParser.string(json['pickup_condition']),
      remarks = JsonParser.string(json['pickup_remarks']),
      otp = JsonParser.string(json['pickup_otp']),
      otpRequired = json['pickup_otp_required'] == null
          ? null
          : JsonParser.boolValue(json['pickup_otp_required']),
      otpVerified = json['pickup_otp_verified'] == null
          ? null
          : JsonParser.boolValue(json['pickup_otp_verified']),
      pickedUpAt = JsonParser.dateTimeValue(json['picked_up_at']),
      photos = _strings(json['pickup_photos']);
}

class ReturnConfirmation {
  final DateTime? receivedAt, approvedAt, refundProcessedAt;
  final String sellerComment;
  final List<String> photos;
  ReturnConfirmation.fromJson(Map<String, dynamic> json)
    : receivedAt = JsonParser.dateTimeValue(json['received_at']),
      approvedAt = JsonParser.dateTimeValue(json['seller_approved_at']),
      refundProcessedAt = JsonParser.dateTimeValue(json['refund_processed_at']),
      sellerComment = JsonParser.string(json['seller_comment']),
      photos = _strings(json['inspection_photos']);
}

class ReturnRefundItem {
  final String label;
  final double? amount;
  ReturnRefundItem.fromJson(Map<String, dynamic> json)
    : label = JsonParser.string(json['label']),
      amount = _amount(json['amount']);
}

class ReturnTimelineEntry {
  final String key, label;
  final DateTime? at;
  final bool done;
  ReturnTimelineEntry.fromJson(Map<String, dynamic> json)
    : key = JsonParser.string(json['key']),
      label = JsonParser.string(json['label']),
      at = JsonParser.dateTimeValue(json['at']),
      done = JsonParser.boolValue(json['done']);
}

class OrderReturn {
  final int id;
  final int? orderId, orderItemId;
  final String orderNumber, status, statusLabel, pickupStatus, disputeReason;
  final bool isDisputed, canDecide, canConfirmReceipt;
  final double? refundAmount, refundTotal;
  final DateTime? createdAt, disputedAt;
  final ReturnParty customer, store;
  final ReturnProduct product;
  final ReturnCustomerRequest? customerRequest;
  final ReturnPickup? pickup;
  final ReturnConfirmation? confirmation;
  final List<ReturnRefundItem> refundItems;
  final List<ReturnTimelineEntry> timeline;

  // The API calls the delivered-to-seller stage received_by_seller.
  bool get canInspectReceivedReturn =>
      canConfirmReceipt && status == 'received_by_seller';

  OrderReturn.fromJson(Map<String, dynamic> json)
    : id = JsonParser.intValue(json['id']),
      orderId = json['order_id'] == null
          ? null
          : JsonParser.intValue(json['order_id']),
      orderItemId = json['order_item_id'] == null
          ? null
          : JsonParser.intValue(json['order_item_id']),
      orderNumber = JsonParser.string(json['order_number']),
      status = JsonParser.string(json['return_status']),
      statusLabel = JsonParser.string(
        json['return_status_label'] ?? json['return_status'],
      ),
      pickupStatus = JsonParser.string(json['pickup_status']),
      disputeReason = JsonParser.string(json['dispute_reason']),
      isDisputed = JsonParser.boolValue(json['is_disputed']),
      canDecide = JsonParser.boolValue(
        returnJsonMap(json['allowed_actions'])['can_decide'],
      ),
      canConfirmReceipt = JsonParser.boolValue(
        returnJsonMap(json['allowed_actions'])['can_confirm_receipt'],
      ),
      refundAmount = _amount(json['refund_amount']),
      refundTotal = _amount(returnJsonMap(json['refund_breakdown'])['total']),
      createdAt = JsonParser.dateTimeValue(json['created_at']),
      disputedAt = JsonParser.dateTimeValue(json['disputed_at']),
      customer = ReturnParty.fromJson(returnJsonMap(json['customer'])),
      store = ReturnParty.fromJson(returnJsonMap(json['store'])),
      product = ReturnProduct.fromJson(returnJsonMap(json['product'])),
      customerRequest = json['customer_request'] is Map
          ? ReturnCustomerRequest.fromJson(
              returnJsonMap(json['customer_request']),
            )
          : null,
      pickup = json['delivery_pickup'] is Map
          ? ReturnPickup.fromJson(returnJsonMap(json['delivery_pickup']))
          : null,
      confirmation = json['store_confirmation'] is Map
          ? ReturnConfirmation.fromJson(
              returnJsonMap(json['store_confirmation']),
            )
          : null,
      refundItems = JsonParser.list(
        returnJsonMap(json['refund_breakdown'])['items'],
        (e) => ReturnRefundItem.fromJson(returnJsonMap(e)),
      ),
      timeline = JsonParser.list(
        json['timeline'],
        (e) => ReturnTimelineEntry.fromJson(returnJsonMap(e)),
      );
}

class ReturnStatusOption {
  final String value, label;
  ReturnStatusOption.fromJson(Map<String, dynamic> json)
    : value = JsonParser.string(json['value']),
      label = JsonParser.string(json['label']);
}

class ReturnEnums {
  final List<ReturnStatusOption> statuses;
  final List<String> disputeReasons, decisionActions, storeConfirmActions;
  const ReturnEnums({
    this.statuses = const [],
    this.disputeReasons = const [],
    this.decisionActions = const [],
    this.storeConfirmActions = const [],
  });
  factory ReturnEnums.fromJson(Map<String, dynamic> json) => ReturnEnums(
    statuses: JsonParser.list(
      json['statuses'],
      (e) => ReturnStatusOption.fromJson(returnJsonMap(e)),
    ),
    disputeReasons: _strings(json['dispute_reasons']),
    decisionActions: _strings(json['decision_actions']),
    storeConfirmActions: _strings(json['store_confirm_actions']),
  );
}

class ReturnListResponse {
  final List<OrderReturn> items;
  final Map<String, int> insights;
  final int currentPage, lastPage, perPage, total;
  ReturnListResponse.fromJson(Map<String, dynamic> json)
    : items = JsonParser.list(
        json['data'],
        (e) => OrderReturn.fromJson(returnJsonMap(e)),
      ),
      insights = returnJsonMap(
        json['insights'],
      ).map((k, v) => MapEntry(k, JsonParser.intValue(v))),
      currentPage = JsonParser.intValue(json['current_page'], fallback: 1),
      lastPage = JsonParser.intValue(json['last_page'], fallback: 1),
      perPage = JsonParser.intValue(json['per_page'], fallback: 15),
      total = JsonParser.intValue(json['total']);
}
