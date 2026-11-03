import 'package:flutter/material.dart';

class GlobalKeys {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey authenticatedProvidersKey = GlobalKey();
  static const int perPage = 30;
}
