import 'package:flutter/widgets.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/extensions/translation_extension.dart';

export 'package:hyper_local_seller/extensions/translation_extension.dart';

extension TranslateEnumExtension on BuildContext {
  String translateEnum(String? key) {
    if (key == null || key.isEmpty) return '';
    final localeName = HiveStorage.languageCode;
    switch (key) {
      case 'rider_details':
        return localeName == 'ar'
            ? 'تفاصيل الراكب'
            : (localeName == 'hi' ? 'राइडर विवरण' : 'Rider Details');
      case 'rider_name':
        return localeName == 'ar'
            ? 'اسم الراكب'
            : (localeName == 'hi' ? 'राइडर का नाम' : 'Rider Name');
      case 'delivery_type':
        return localeName == 'ar'
            ? 'نوع التوصيل'
            : (localeName == 'hi' ? 'डिलीवरी प्रकार' : 'Delivery Type');
      case 'pos':
        return localeName == 'ar'
            ? 'POS'
            : (localeName == 'hi' ? 'पीओएस' : 'POS');
      case 'regular':
      case 'delivery':
        return localeName == 'ar'
            ? 'توصيل'
            : (localeName == 'hi' ? 'डिलीवरी' : 'Delivery');
      case 'scheduled':
        return localeName == 'ar'
            ? 'مجدول'
            : (localeName == 'hi' ? 'अनुसूचित' : 'Scheduled');
      case 'scheduled_date':
        return localeName == 'ar'
            ? 'تاريخ الجدولة'
            : (localeName == 'hi' ? 'अनुसूचित तिथि' : 'Scheduled Date');
      case 'scheduled_for':
        return localeName == 'ar'
            ? 'مجدول لـ'
            : (localeName == 'hi' ? 'इसके लिए अनुसूचित' : 'Scheduled for');
      case 'needs_reschedule':
      case 'awaiting_customer_reschedule':
        return localeName == 'ar'
            ? 'بانتظار إعادة الجدولة من العميل'
            : (localeName == 'hi'
                  ? 'ग्राहक पुनर्निर्धारण की प्रतीक्षा है'
                  : 'Awaiting Customer Reschedule');
      case 'slot_unavailable':
        return localeName == 'ar'
            ? 'الفتحة غير متوفرة'
            : (localeName == 'hi' ? 'स्लॉट अनुपलब्ध' : 'Slot Blocked');
      case 'item_out_of_stock':
        return localeName == 'ar'
            ? 'المنتج غير متوفر'
            : (localeName == 'hi'
                  ? 'सामग्री स्टॉक में नहीं है'
                  : 'Item Out of Stock');
      case 'reschedule_deadline_label':
        return localeName == 'ar'
            ? 'الإجراء مطلوب قبل'
            : (localeName == 'hi'
                  ? 'इससे पहले कार्रवाई आवश्यक है'
                  : 'Action needed before');
      case 'pickup':
        return localeName == 'ar'
            ? 'استلام'
            : (localeName == 'hi' ? 'पिकअप' : 'Pickup');
      case 'accepted_by_seller':
        return localeName == 'ar'
            ? 'مقبول من قبل البائع'
            : (localeName == 'hi'
                  ? 'विक्रेता द्वारा स्वीकृत'
                  : 'Accepted by Seller');
      case 'ready_for_pickup':
        return localeName == 'ar'
            ? 'جاهز للاستلام'
            : (localeName == 'hi' ? 'पिकअप के लिए तैयार' : 'Ready for Pickup');
      case 'rejected_by_seller':
        return localeName == 'ar'
            ? 'مرفوض من قبل البائع'
            : (localeName == 'hi'
                  ? 'विक्रेता द्वारा अस्वीकृत'
                  : 'Rejected by Seller');
      case 'simple':
      case 'variant':
      case 'active':
      case 'draft':
      case 'pending_verification':
      case 'rejected':
      case 'approved':
      case 'featured':
      case 'low_stock':
      case 'out_of_stock':
      case 'online':
      case 'offline':
      case 'visible':
      case 'not_approved':
      case 'awaiting_store_response':
      case 'accepted':
      case 'preparing':
      case 'collected':
      case 'delivered':
      case 'returned':
      case 'refunded':
      case 'cancelled':
      case 'failed':
      case 'last_30_minutes':
      case 'last_1_hour':
      case 'last_5_hours':
      case 'last_1_day':
      case 'last_7_days':
      case 'last_30_days':
      case 'last_365_days':
      case 'pending':
        return tr(key);
      case 'pending_approval':
      case 'pending_for_approval':
        return tr('pendingForApproval');
      default:
        final translated = tr(key, fallback: '');
        if (translated.isNotEmpty && translated != key) {
          return translated;
        }
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (str) => str.isNotEmpty
                  ? "${str[0].toUpperCase()}${str.substring(1)}"
                  : "",
            )
            .join(' ');
    }
  }
}

extension NullableTranslateEnumExtension on BuildContext? {
  String translateEnum(String? key) {
    if (this == null) return key ?? '';
    return this!.translateEnum(key);
  }
}
