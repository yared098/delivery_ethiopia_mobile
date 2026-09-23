import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../router/app_router.dart';
import '../router/app_routes.dart';

// ═══════════════════════════════════════════════════════════════
// Top-level handlers (required by plugins)
// ═══════════════════════════════════════════════════════════════

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [bg] message: ${message.messageId} data=${message.data}');
}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  debugPrint('🔔 [bg tap] payload=${response.payload}');
}

// ═══════════════════════════════════════════════════════════════
// PushService
// ═══════════════════════════════════════════════════════════════

class PushService {
  PushService({required this.onToken});

  final Future<void> Function(String token) onToken;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenSub;
  String? _lastToken;                                       // ← ADD

  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High importance';
  static const String _channelDesc = 'Delivery and order updates.';

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final NotificationSettings settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 permission: ${settings.authorizationStatus}');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalTap,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    final RemoteMessage? initial = await _messaging.getInitialMessage();
    if (initial != null) _onMessageOpened(initial);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _fetchAndSendToken();
    _tokenSub = _messaging.onTokenRefresh.listen((String t) async {
      debugPrint('🔔 token rotated');
      _lastToken = t;                                       // ← ADD
      await _safeSend(t);
    });
  }

  Future<void> refreshToken() async {
    await _fetchAndSendToken();
  }

  /// Returns the current FCM token (cached, or fetched fresh).   // ← ADD
  Future<String?> getToken() async {                             // ← ADD
    try {
      final t = await _messaging.getToken();
      if (t != null) _lastToken = t;
      return _lastToken;
    } catch (_) {
      return _lastToken;
    }
  }                                                              // ← ADD

  Future<void> _fetchAndSendToken() async {
    try {
      final String? token = await _messaging.getToken();
      debugPrint('🔔 FCM token: $token');
      if (token != null) {
        _lastToken = token;                                   // ← ADD
        await _safeSend(token);
      }
    } catch (e) {
      debugPrint('🔔 getToken failed: $e');
    }
  }

  Future<void> _safeSend(String token) async {
    try {
      await onToken(token);
    } catch (e) {
      debugPrint('🔔 onToken callback failed: $e');
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final RemoteNotification? n = message.notification;
    if (n == null) return;

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _local.show(
      n.hashCode,
      n.title,
      n.body,
      details,
      payload: _payloadFromData(message.data),
    );
  }

  String? _payloadFromData(Map<String, dynamic> data) {
    if (data.isEmpty) return null;
    final String? route = data['route']?.toString();
    if (route != null && route.isNotEmpty) return route;
    final String? orderId = data['orderId']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      return '/order-detail/$orderId';
    }
    return null;
  }

  void _onMessageOpened(RemoteMessage message) {
    debugPrint('🔔 opened: data=${message.data}');
    final String? route = message.data['route']?.toString() ??
        (message.data['orderId'] != null
            ? '/order-detail/${message.data['orderId']}'
            : null);
    if (route != null && route.isNotEmpty) {
      _navigateToRoute(route);
    }
  }

  void _onLocalTap(NotificationResponse response) {
    final String? payload = response.payload;
    debugPrint('🔔 local tap → payload=$payload');
    if (payload != null && payload.isNotEmpty) {
      _navigateToRoute(payload);
    }
  }

  void _navigateToRoute(String route) {
    try {
      if (route.startsWith('/order-detail/') || route.startsWith('/orders/')) {
        final String id = route.split('/').last;
        AppRouter.router.push(AppRoutes.orderDetail, extra: id);
        return;
      }
      if (route.startsWith('/tracking/')) {
        final String token = route.split('/').last;
        AppRouter.router.push(AppRoutes.tracking, extra: token);
        return;
      }
      if (route == '/home' || route == '/') {
        AppRouter.router.go(AppRoutes.home);
        return;
      }
      debugPrint('🔔 unknown notification route: $route');
    } catch (e) {
      debugPrint('🔔 route navigation failed: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _lastToken = null;                                     // ← ADD (clear cache)
      debugPrint('🔔 token deleted');
    } catch (e) {
      debugPrint('🔔 deleteToken failed: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
  }

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
}
