import 'package:flutter/material.dart';

/// Global navigator key for auth expiry redirects and FCM deep links.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppNavigator {
  static NavigatorState? get state => appNavigatorKey.currentState;

  static void pushNamedAndRemoveUntil(String route) {
    state?.pushNamedAndRemoveUntil(route, (_) => false);
  }
}
