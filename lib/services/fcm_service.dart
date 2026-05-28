import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.data}');
}

class FcmService {
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    await _registerToken();

    messaging.onTokenRefresh.listen((token) async {
      try {
        await ApiService.patch('/auth/fcm-token', {'fcmToken': token});
      } catch (e) {
        debugPrint('FCM token refresh upload failed: $e');
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? 'CarPool';
      final body = message.notification?.body ?? '';
      _showForegroundBanner(title, body);
      debugPrint('FCM foreground: $title — $body');
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleMessage(initial);
    }
  }

  static Future<void> _registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService.patch('/auth/fcm-token', {'fcmToken': token});
      }
    } catch (e) {
      debugPrint('FCM token register failed: $e');
    }
  }

  static void _showForegroundBanner(String title, String body) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(body.isNotEmpty ? '$title\n$body' : title),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {},
        ),
      ),
    );
  }

  static void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final screen = (data['screen'] ?? '').toString();
    final type = data['type'] ?? '';
    final rideId = data['rideId'];
    final dealId = data['dealId'];

    if (screen == 'find-ride') {
      AppNavigator.state?.pushNamed('/find-ride');
      return;
    }
    if (screen == 'my-rides') {
      AppNavigator.state?.pushNamed('/my-rides');
      return;
    }
    if (screen == 'customer-requests') {
      AppNavigator.state?.pushNamed('/customer-requests');
      return;
    }

    switch (type) {
      case 'new_deal':
        if (rideId != null && rideId.isNotEmpty) {
          AppNavigator.state?.pushNamed('/requests', arguments: rideId);
        } else {
          AppNavigator.state?.pushNamed('/my-rides');
        }
        break;
      case 'deal_confirmed':
      case 'deal_cancelled':
      case 'deal_counter':
        AppNavigator.state?.pushNamed('/my-bookings');
        break;
      case 'ride_started':
        if (rideId != null &&
            rideId.isNotEmpty &&
            dealId != null &&
            dealId.isNotEmpty) {
          AppNavigator.state?.pushNamed('/active-ride', arguments: {
            'rideId': rideId,
            'dealId': dealId,
          });
        } else {
          AppNavigator.state?.pushNamed('/my-bookings');
        }
        break;
      case 'ride_completed':
        if (dealId != null && dealId.isNotEmpty) {
          AppNavigator.state?.pushNamed('/rate-review', arguments: dealId);
        } else {
          AppNavigator.state?.pushNamed('/my-bookings');
        }
        break;
      case 'deal_message':
        if (dealId != null && dealId.isNotEmpty) {
          AppNavigator.state?.pushNamed('/my-bookings');
        }
        break;
      case 'customer_request':
      case 'customer_counter':
      case 'customer_request_accepted':
        AppNavigator.state?.pushNamed('/customer-requests');
        break;
      case 'customer_offer':
        AppNavigator.state?.pushNamed('/customer-request');
        break;
      default:
        AppNavigator.state?.pushNamed('/notifications');
    }
  }
}

