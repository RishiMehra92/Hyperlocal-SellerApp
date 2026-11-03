import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
class ValidatorUtils {
  static String? validateEmpty(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('fieldRequired');
    }
    return null;
  }

  static String? validateEmail(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('fieldRequired');
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return context.tr('invalidEmail');
    }
    return null;
  }

  static String? validatePhone(BuildContext context, String? value) {
    final l10n = context;
    if (value == null || value.trim().isEmpty) {
      return l10n.tr('pleaseEnterYourPhoneNumber');
    }
    final trimmed = value.trim();
    if (trimmed.length < 5) return l10n.tr('phoneNumberTooShort');
    if (trimmed.length > 16) return l10n.tr('phoneNumberTooLong');
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) return l10n.tr('onlyNumbersAllowed');
    return null;
  }

  static String? validatePassword(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('fieldRequired');
    }
    if (value.length < 8) {
      return context.tr('passwordTooShort');
    }
    return null;
  }

  static String? validateConfirmPassword(BuildContext context, String? value, String? password) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('fieldRequired');
    }
    if (value != password) {
      return context.tr('passwordsDoNotMatch');
    }
    return null;
  }

  static String? validateFile(BuildContext context, String? fileName) {
    if (fileName == null || fileName.isEmpty) {
      return context.tr('pleaseSelectFile');
    }
    return null;
  }

  static String? validateUrl(BuildContext context, String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr('fieldRequired');
    }
    final urlRegExp = RegExp(r'^(https?:\/\/)?([\w\-]+(\.[\w\-]+)+)([\w\-\.,@?^=%&:/~\+#]*[\w\-\@?^=%&/~\+#])?$');
    if (!urlRegExp.hasMatch(value)) {
      return context.tr('invalidUrl');
    }
    return null;
  }
}
