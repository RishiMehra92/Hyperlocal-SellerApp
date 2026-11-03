import 'package:hyper_local_seller/screen/products_page/products/model/product_model.dart';

class ReturnReason {
  final int? id;
  final String titleReason;
  final bool riderOtpRequired;
  final bool riderCustomerImageProof;
  final String status; // 'active' or 'inactive'
  final List<Product> selectedProducts;

  ReturnReason({
    this.id,
    required this.titleReason,
    required this.riderOtpRequired,
    required this.riderCustomerImageProof,
    required this.status,
    required this.selectedProducts,
  });

  factory ReturnReason.fromJson(Map<String, dynamic> json) {
    return ReturnReason(
      id: json['id'] as int?,
      titleReason:
          json['title'] as String? ?? json['title_reason'] as String? ?? '',
      riderOtpRequired:
          json['otp_required'] as bool? ??
          json['rider_otp_required'] as bool? ??
          false,
      riderCustomerImageProof:
          json['proof_required'] as bool? ??
          json['rider_customer_image_proof'] as bool? ??
          false,
      status: json['status'] as String? ?? 'active',
      selectedProducts:
          (json['products'] as List?)?.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            map['slug'] ??= '';
            return Product.fromJson(map);
          }).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': titleReason,
      'otp_required': riderOtpRequired,
      'proof_required': riderCustomerImageProof,
      'status': status,
      'product_ids': selectedProducts.map((e) => e.id).toList(),
    };
  }
}
