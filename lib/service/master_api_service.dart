import 'package:flutter/material.dart';
import 'package:hyper_local_seller/screen/more_page/view/subscription_plans/service/subscription_reminder_service.dart';

class MasterApiService {
  /// Called after successful login to refresh ALL data for the new user.

  /// Called on logout to clear ALL cached/session data from every BLoC.
  /// This ensures no stale data from user A is visible when user B logs in.
  static void clearAllApisData(BuildContext context) {
    debugPrint('[MasterApiService] clearAllApisData triggered');

    // Reset subscription reminder service session (singleton)
    SubscriptionReminderService().resetSession();

    // Note: All other blocs are now automatically disposed and garbage collected
    // because they are scoped to the AuthenticatedShellRoute in GoRouter.
  }
}
