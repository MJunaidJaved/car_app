import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../services/session_storage.dart';
import '../utils/helpers.dart';
import '../widgets/request_toast.dart';
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

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleMessage(initial);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
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

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final type = (data['type'] ?? '').toString();
    final role = await SessionStorage.getRole();

    if (role == 'captain') {
      final toast = _captainToastForType(type, message, data);
      if (toast != null) {
        RequestToast.show(
          passengerName: toast.$1,
          route: toast.$2,
          fareLabel: toast.$3,
          subtitle: toast.$4,
          actionLabel: toast.$5,
          onView: toast.$6,
        );
        return;
      }
    }

    final title = message.notification?.title ?? 'ShareWay';
    final body = message.notification?.body ?? '';
    _showForegroundBanner(title, body);
    debugPrint('FCM foreground: $title — $body');
  }

  static (String, String, String, String?, String, VoidCallback)?
      _captainToastForType(
    String type,
    RemoteMessage message,
    Map<String, dynamic> data,
  ) {
    final title = message.notification?.title ?? 'ShareWay';
    final body = message.notification?.body ?? '';
    void go(String route, [Object? args]) {
      if (args != null) {
        AppNavigator.state?.pushNamed(route, arguments: args);
      } else {
        AppNavigator.state?.pushNamed(route);
      }
    }

    switch (type) {
      case 'customer_request':
      case 'customer_request_accepted':
        final fare = data['desiredFare'] ?? data['fare'];
        final fareLabel = fare != null ? 'Rs $fare' : 'Open request';
        final route = body.isNotEmpty
            ? body
            : '${data['startLocation'] ?? ''} → ${data['endLocation'] ?? ''}';
        return (
          title,
          route,
          fareLabel,
          type == 'customer_request_accepted'
              ? 'Your offer was accepted.'
              : null,
          type == 'customer_request_accepted' ? 'View Details' : 'View Request',
          () => go('/customer-requests'),
        );
      case 'new_deal':
        return (
          title,
          body.isNotEmpty ? body : 'New booking request',
          'Tap to review',
          null,
          'View Requests',
          () {
            final rideId = data['rideId']?.toString();
            if (rideId != null && rideId.isNotEmpty) {
              go('/requests', rideId);
            } else {
              go('/my-rides');
            }
          },
        );
      case 'deal_confirmed':
        return (
          title,
          body.isNotEmpty ? body : 'Deal confirmed',
          'Confirmed',
          null,
          'My Rides',
          () => go('/my-rides'),
        );
      case 'deal_counter':
        return (
          title,
          body.isNotEmpty ? body : 'Passenger countered fare',
          'Counter offer',
          null,
          'View Deal',
          () => go('/my-rides'),
        );
      case 'ride_started':
        return (
          title,
          body.isNotEmpty ? body : 'Ride started',
          'In progress',
          null,
          'Active Ride',
          () {
            final rideId = data['rideId']?.toString();
            final dealId = data['dealId']?.toString();
            if (rideId != null &&
                rideId.isNotEmpty &&
                dealId != null &&
                dealId.isNotEmpty) {
              go('/active-ride', {'rideId': rideId, 'dealId': dealId});
            } else {
              go('/my-rides');
            }
          },
        );
      case 'ride_completed':
        return (
          title,
          body.isNotEmpty ? body : 'Ride completed',
          'Completed',
          null,
          'Earnings',
          () => go('/earnings'),
        );
      default:
        return null;
    }
  }

  static void _showForegroundBanner(String title, String body) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    AppHelpers.showSnackBar(
      ctx,
      body.isNotEmpty ? '$title\n$body' : title,
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
