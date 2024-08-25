import 'dart:async';

import 'package:chucker_flutter/src/view/helper/chucker_ui_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Initialization of [NotificationService]
class NotificationService {
  /// Constructor of [NotificationService]
  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();
  static final NotificationService _notificationService =
      NotificationService._internal();

  /// Initialization of [FlutterLocalNotificationsPlugin]
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Setting up Local Notification
  static Future<void> init({
    required NavigatorObserver navigatorObserver,
  }) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    unawaited(
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission(),
    );
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final initializationSettingsIOS = DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) {
        openChucker();
      },
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveNotificationResponse,
    );
  }

  /// Triggered when notification clicked
  static void onDidReceiveNotificationResponse(NotificationResponse details) {
    openChucker();
  }

  /// Open chucker with
  static void openChucker() {
    ChuckerUiHelper.showChuckerScreen();
  }

  /// Show Notification
  static bool showNotification(
    int id,
    String title,
    String body,
    NotificationDetails notificationDetails, {
    required String payload,
  }) {
    flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
    return true;
  }
}
