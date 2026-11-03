import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local_seller/bloc/store_switcher/store_switcher_cubit.dart';
import 'package:hyper_local_seller/config/global_keys.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/router/app_routes.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/home_page/home_page_bloc.dart';
import 'package:hyper_local_seller/screen/home_page/bloc/notification/notification_list_bloc.dart';
import 'package:hyper_local_seller/screen/order_page/bloc/orders/orders_bloc.dart';
import 'package:hyper_local_seller/utils/image_path.dart';
import 'package:hyper_local_seller/widgets/ui/order_notification_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Skip if it's a silent notification (no notification object)
  if (message.notification == null && message.data.isEmpty) {
    log('Ignoring silent push notification (likely auth related)');
    return;
  }

  log('Handling background notification: ${message.messageId}');

  // Ongoing functionality: Flag for refresh in AppLifecycleObserverWidget
  try {
    await Hive.initFlutter();
    final type = message.data['type']?.toString().toLowerCase();
    final orderId = message.data['seller_order_id']?.toString() ?? message.data['order_id']?.toString();

    final isOrderNotification =
        type == 'order' ||
        type == 'orders' ||
        type == 'order_update' ||
        type == 'new_order' ||
        type == 'return_order' ||
        type == 'return_order_update' ||
        (orderId != null && orderId.isNotEmpty && type == null);

    final box = await Hive.openBox('notificationRefreshBox');
    if (isOrderNotification) {
      await box.put('pendingOrderRefresh', true);
      log('[BG Handler] Order notification received — pendingOrderRefresh set to true');
    }
    // Always mark that notification count needs refresh
    await box.put('pendingNotificationCountRefresh', true);
  } catch (e) {
    log('❌ Error in background handler Hive storage: $e');
  }
}

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Channel IDs — use versioned IDs so Android recreates channels with updated settings
  static const String _orderChannelId = 'order_notification_channel_v1';
  static const String _orderChannelName = 'Order Notifications';
  static const String _generalChannelId = 'general_notification_channel_v1';
  static const String _generalChannelName = 'General Notifications';

  RemoteMessage? _pendingMessage;
  bool _initialized = false;

  bool get hasPendingNotification => _pendingMessage != null;

  Future<void> initialize() async {
    if (_initialized) {
      log('⚠️ NotificationManager already initialized');
      return;
    }

    try {
      log('🔔 Initializing NotificationManager...');

      // Request permission
      await requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();

      // Handle terminated state (initial message)
      // Store it for SplashScreen to handle properly
      _pendingMessage = await _firebaseMessaging.getInitialMessage();
      if (_pendingMessage != null) {
        log('🚀 Terminated state message found: ${_pendingMessage!.messageId}');
      }

      // Get and save FCM token
      await _retrieveAndSaveFCMToken();

      _initialized = true;
      log('✅ NotificationManager initialization complete');
    } catch (e) {
      log('❌ NotificationManager initialization error: $e');
      rethrow;
    }
  }

  void handlePendingNotification(BuildContext context) {
    if (_pendingMessage != null) {
      log('🚀 Handling pending notification from SplashScreen');
      _handleNotificationTap(_pendingMessage!, fromTerminated: true);
      _pendingMessage = null;
      _refreshAllBlocs();
    }
  }

  Future<void> requestPermission() async {
    try {
      log('📱 Requesting notification permission...');

      NotificationSettings settings = await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (Platform.isIOS) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
      log('📱 Permission status: ${settings.authorizationStatus}');
    } catch (e) {
      log('❌ Error requesting permission: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Delete old channel to clear cached sound settings
      await androidPlugin.deleteNotificationChannel(channelId: 'high_importance_channel');
      await androidPlugin.deleteNotificationChannel(channelId: 'order_notification_channel_v1');
      await androidPlugin.deleteNotificationChannel(channelId: 'general_notification_channel_v1');

      // Order channel — plays custom sound from res/raw/new_order_foreground_sound.mp3
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _orderChannelId,
          _orderChannelName,
          description: 'Notifications for orders.',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('new_order_foreground_sound'),
          enableVibration: true,
          enableLights: true,
        ),
      );

      // General channel — plays custom sound from res/raw/notification_sound.wav
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _generalChannelId,
          _generalChannelName,
          description: 'General app notifications.',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
          enableLights: true,
        ),
      );
    }
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('📨 Foreground message received: ${message.messageId}');

      final type = message.data['type']?.toString().toLowerCase();

      _refreshAllBlocs();

      // Check if this is a new order notification (plays ringtone and shows bottom sheet)
      if (_isNewOrderType(type)) {
        // Play custom new order ringtone from assets/audio
        _playNewOrderNotificationSound();

        // Check if the order status is 'Awaiting store response'
        final status = message.data['status']?.toString().toLowerCase() ?? '';
        final isAwaitingStoreResponse = status == 'awaiting store response' || status == 'awaiting_store_response';

        if (isAwaitingStoreResponse) {
          // Also show the order acceptance bottom sheet (do NOT show local notification)
          final context = GlobalKeys.authenticatedProvidersKey.currentContext ?? GlobalKeys.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            Map<String, dynamic> payload = Map.from(message.data);
            payload['title'] = message.notification?.title ?? payload['title'] ?? '';
            payload['body'] = message.notification?.body ?? payload['body'] ?? '';

            OrderNotificationHandler.showOrderAcceptanceBottomSheet(context, payload);
          }
          return;
        }
      }

      // Rest play notification_sound.mp3 and show local notification banner
      _playInAppNotificationSound();
      _showLocalNotification(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('📬 Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message);
      _refreshAllBlocs();
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _retrieveAndSaveFCMToken() async {
    try {
      log('🔑 Retrieving tokens...');

      // APNs Token for iOS
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        int retryCount = 0;
        const maxRetries = 10;
        while (apnsToken == null && retryCount < maxRetries) {
          log('Waiting for APNs token... attempt ${retryCount + 1}');
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await _firebaseMessaging.getAPNSToken();
          retryCount++;
        }
        if (apnsToken != null) {
          await HiveStorage.setApnsToken(apnsToken);
          log('✅ APNs token saved');
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      // FCM Token
      String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await HiveStorage.setFcmToken(fcmToken);
        log('✅ FCM Token saved: $fcmToken');
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        log('🔄 FCM Token refreshed: $newToken');
        await HiveStorage.setFcmToken(newToken);
      });
    } catch (e) {
      log('❌ Error retrieving tokens: $e');
    }
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = Platform.isIOS
          ? await getTemporaryDirectory()
          : await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';

      final Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 15);

      await dio.download(url, filePath);
      return filePath;
    } catch (e) {
      log('❌ Error downloading file: $e');
      return '';
    }
  }

  /// Plays the in-app notification sound from assets/audio (for non-order notifications)
  static void _playInAppNotificationSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.play(AssetSource(AudioPath.inAppNotificationSound));
    } catch (e) {
      log('Error playing in-app notification sound: $e');
    }
  }

  /// Plays the new order notification sound from assets/audio
  static void _playNewOrderNotificationSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(AudioPath.newOrderNotificationSound));
    } catch (e) {
      log('Error playing new order notification sound: $e');
    }
  }

  /// Stops any currently playing notification sound
  static void stopNotificationSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      log('Error stopping notification sound: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    String title = notification.title ?? 'Notification';
    String body = notification.body ?? '';
    String? imageUrl = notification.android?.imageUrl ?? notification.apple?.imageUrl;

    BigPictureStyleInformation? bigPictureStyleInformation;
    List<DarwinNotificationAttachment>? attachments;
    String? localImagePath;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final String fileName = 'notification_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String filePath = await _downloadAndSaveFile(imageUrl, fileName);
        if (filePath.isNotEmpty) {
          log('✅ Notification image downloaded to: $filePath');
          localImagePath = filePath;

          bigPictureStyleInformation = BigPictureStyleInformation(
            FilePathAndroidBitmap(filePath),
            largeIcon: FilePathAndroidBitmap(filePath),
            contentTitle: title,
            summaryText: body,
            hideExpandedLargeIcon: false,
          );

          attachments = [DarwinNotificationAttachment(filePath)];
        }
      } catch (e) {
        log('❌ Error processing notification image: $e');
      }
    }

    final type = message.data['type']?.toString().toLowerCase();
    final orderId = message.data['order_id']?.toString() ?? message.data['seller_order_id']?.toString();
    final isOrderNotification = _isOrderRelatedType(type, orderId);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      isOrderNotification ? _orderChannelId : _generalChannelId,
      isOrderNotification ? _orderChannelName : _generalChannelName,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      largeIcon: localImagePath != null ? FilePathAndroidBitmap(localImagePath) : null,
      // Sound is already played via AudioPlayer in foreground, so keep it silent here to avoid overlap
      sound: null,
      playSound: false,
      enableVibration: true,
      enableLights: true,
      styleInformation: bigPictureStyleInformation ?? BigTextStyleInformation(body),
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      subtitle: '',
      threadIdentifier: 'foreground_threat',
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
      sound: null,
      attachments: attachments,
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _flutterLocalNotificationsPlugin.show(
      // ignore: dead_null_aware_expression
      id: notification.hashCode,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> payloadData = jsonDecode(response.payload!);
        final type = payloadData['type']?.toString().toLowerCase();
        handleTypeRedirection(type, payloadData);
      } catch (e) {
        log('❌ Error parsing tap payload: $e');
      }
    }
  }

  void _handleNotificationTap(RemoteMessage message, {bool fromTerminated = false}) {
    final type = message.data['type']?.toString().toLowerCase();
    handleTypeRedirection(type, message.data, fromTerminated: fromTerminated);
  }

  void handleTypeRedirection(String? type, Map<String, dynamic> metadata, {bool fromTerminated = false}) {
    log('🧭 Redirecting for type: $type');
    final context = GlobalKeys.navigatorKey.currentContext;
    if (context == null) return;

    String? orderId = metadata['order_id']?.toString() ?? metadata['seller_order_id']?.toString();

    try {
      switch (type) {
        case 'wallet_transaction':
          context.push(AppRoutes.wallet);
          break;
        case 'refer_transaction':
          context.push(AppRoutes.transactionHistory);
          break;
        case 'withdrawal_request':
        case 'withdrawal_process':
          context.push(AppRoutes.withdrawHistory);
          break;
        case 'settlement_process':
        case 'settlement_create':
          context.push(AppRoutes.earnings);
          break;
        case 'order_ready_for_pickup':
        case 'delivery':
          // Redirecting to orders since 'feed' doesn't exist in this project
          context.go(AppRoutes.orders);
          break;
        case 'return_order_available':
        case 'return_order':
          context.go(AppRoutes.orders);
          break;
        case 'order_update':
          if (orderId != null && orderId.isNotEmpty) {
            if (fromTerminated) {
              _handleTerminatedOrderNavigation(context, orderId);
            } else {
              context.push('${AppRoutes.orderDetails}/$orderId');
            }
          }
          break;
        default:
          if (_isOrderRelatedType(type, orderId)) {
            if (orderId != null && orderId.isNotEmpty) {
              if (fromTerminated) {
                _handleTerminatedOrderNavigation(context, orderId);
              } else {
                context.push('${AppRoutes.orderDetails}/$orderId');
              }
            } else {
              context.go(AppRoutes.orders);
            }
          } else {
            log('⚠️ Unknown notification type: $type, navigating home');
            context.push(AppRoutes.notifications);
          }
      }
    } catch (e) {
      log('❌ Redirection error: $e');
      context.go(AppRoutes.home);
    }
  }

  void _handleTerminatedOrderNavigation(BuildContext context, String orderId) {
    context.go(AppRoutes.home);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (context.mounted) {
        context.push('${AppRoutes.orderDetails}/$orderId');
      }
    });
  }

  bool _isOrderRelatedType(String? type, String? orderId) {
    return type == 'order' ||
        type == 'orders' ||
        type == 'order_update' ||
        type == 'new_order' ||
        type == 'return_order' ||
        type == 'return_order_update' ||
        (orderId != null && orderId.isNotEmpty && type == null);
  }

  bool _isNewOrderType(String? type) {
    final lowerType = type?.toLowerCase();
    return lowerType == 'new_order' || lowerType == 'order' || lowerType == 'orders';
  }

  void _refreshAllBlocs() {
    final context = GlobalKeys.authenticatedProvidersKey.currentContext ?? GlobalKeys.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    try {
      context.read<OrdersBloc>().add(RefreshOrders());
      context.read<NotificationListBloc>().add(FetchUnreadCount());

      final switcherState = context.read<StoreSwitcherCubit>().state;
      if (switcherState.selectedStore != null) {
        context.read<HomePageBloc>().add(FetchHomePageData(storeId: switcherState.selectedStore!.id));
      }
      log('✅ Blocs refreshed from NotificationManager');
    } catch (e) {
      log('❌ Error refreshing blocs: $e');
    }
  }
}
