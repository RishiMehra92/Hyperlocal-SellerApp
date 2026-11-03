import 'dart:ui';

class AppConstants {
  //  BASE URL

   static String baseUrl = 'https://api.nezit.in';
  static String get domainUrl => baseUrl;
  static String appName = 'Nezit Merchant';
  // theme related variables
  static String fontFamily = 'Inter';
  static String systemVersion = '3.3.0';
  static const bool isDemoMode = false;
  static final RegExp _baseUrlRegex = RegExp(r'^https://', caseSensitive: false);
  static bool get hasValidBaseUrl => _baseUrlRegex.hasMatch(baseUrl.trim());
  // theme related variables  

  static const Color myprimaryColor = Color(0xFFFF7A2A);

}


