import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:chucker_flutter/src/helpers/extensions.dart';
import 'package:chucker_flutter/src/helpers/notification_service.dart';
import 'package:chucker_flutter/src/helpers/shared_preferences_manager.dart';
import 'package:chucker_flutter/src/localization/localization.dart';

import 'package:chucker_flutter/src/models/settings.dart';
import 'package:chucker_flutter/src/view/chucker_page.dart';
import 'package:chucker_flutter/src/view/helper/chucker_button.dart';
import 'package:chucker_flutter/src/view/widgets/notification.dart'
    as notification;
import 'package:flutter/cupertino.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

///[ChuckerUiHelper] handles the UI part of `chucker_flutter`
///
///You must initialize ChuckerObserver in the `MaterialApp`
///of your application as it is required to show notification and the screens
///of `chucker_flutter`
class ChuckerUiHelper {
  static final List<OverlayEntry?> _overlayEntries = List.empty(growable: true);

  ///Only for testing
  static bool notificationShown = false;

  ///Only for testing
  static ShowNotificationOptions showNotificationOptions =
      ShowNotificationOptions.toast;

  ///[settings] to modify ui behaviour of chucker screens and notification
  static Settings settings = Settings.defaultObject();

  /// Notification Channel ID
  static const channelId = 'Chucker';

  /// Notification Channel Name
  static const channelName = 'Chucker';

  /// Notification Channel Description
  static const channelDescription = 'Chucker';

  ///[showNotification] shows the rest api [method] (GET, POST, PUT, etc),
  ///[statusCode] (200, 400, etc) response status and [path]
  static Future<bool> showNotification({
    required String method,
    required int statusCode,
    required String path,
    required DateTime requestTime,
  }) async {
    if (ChuckerUiHelper.settings.showNotification &&
        ChuckerFlutter.navigatorObserver.navigator != null) {
      final overlay = ChuckerFlutter.navigatorObserver.navigator!.overlay;
      if (ChuckerFlutter.showNotificationOptions ==
          ShowNotificationOptions.notification) {
        final responses =
            await SharedPreferencesManager.getInstance().getAllApiResponses();
        notificationShown = NotificationService.showNotification(
          0,
          channelName,
          responses
              .map(
                (e) =>
                    'Method: ${e.method}\nStatus Code: ${e.statusCode}\nPath:'
                    ' ${e.path}\n\n',
              )
              .join(),
          NotificationDetails(
            android: androidNotificationDetails,
            iOS: iosNotificationDetails,
          ),
          payload: '',
        );
      } else {
        final entry =
            _createOverlayEntry(method, statusCode, path, requestTime);
        _overlayEntries.add(entry);
        overlay?.insert(entry);
        notificationShown = true;
      }
      return true;
    }
    notificationShown = false;
    showNotificationOptions = ChuckerFlutter.showNotificationOptions;
    return false;
  }

  /// [AndroidNotificationDetails] give many
  /// options for displaying android notifications
  static AndroidNotificationDetails androidNotificationDetails =
      const AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    ticker: 'ticker',
    groupKey: channelId,
    enableVibration: false,
    styleInformation: BigTextStyleInformation(''),
    groupAlertBehavior: GroupAlertBehavior.children,
  );

  /// [DarwinNotificationDetails] give many
  /// options for displaying iOS notifications
  static DarwinNotificationDetails iosNotificationDetails =
      const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: false,
    threadIdentifier: 'requests',
  );

  static OverlayEntry _createOverlayEntry(
    String method,
    int statusCode,
    String path,
    DateTime requestTime,
  ) {
    return OverlayEntry(
      builder: (context) {
        return Align(
          alignment: settings.notificationAlignment,
          child: notification.Notification(
            statusCode: statusCode,
            method: method,
            path: path,
            removeNotification: _removeNotification,
            requestTime: requestTime,
          ),
        );
      },
    );
  }

  static void _removeNotification() {
    for (final entry in _overlayEntries) {
      if (entry != null) {
        entry.remove();
      }
    }
    _overlayEntries.clear();
  }

  ///[showChuckerScreen] shows the screen containing the list of recored
  ///api requests
  static void showChuckerScreen() {
    SharedPreferencesManager.getInstance().getSettings();
    ChuckerFlutter.navigatorObserver.navigator!.push(
      MaterialPageRoute<void>(
        builder: (context) => MaterialApp(
          key: const Key('chucker_material_app'),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
          ],
          supportedLocales: Localization.supportedLocales,
          locale: Localization.currentLocale,
          theme: ThemeData(
            tabBarTheme: TabBarTheme(
              labelColor: Colors.white,
              labelStyle: context.textTheme.bodySmall,
            ),
            colorScheme: context.theme.colorScheme.copyWith(
              background: Colors.white,
            ),
          ),
          home: const ChuckerPage(),
        ),
      ),
    );
  }
}

///[ChuckerFlutter] is a helper class to initialize the library
///
///[chuckerButton] and notifications only be visible in debug mode
class ChuckerFlutter {
  ///[navigatorObserver] observes the navigation of your app. It must be
  ///referenced in your MaterialApp widget
  static final navigatorObserver = NavigatorObserver();

  ///[showOnRelease] decides whether to allow Chucker Flutter working in release
  ///mode or not.
  ///By default its value is `false`
  static bool showOnRelease = false;

  ///[isDebugMode] A wrapper of Flutter's `kDebugMode` constant
  static bool isDebugMode = kDebugMode;

  ///[ChuckerButton] can be placed anywhere in the UI to open Chucker Screen
  static final chuckerButton = isDebugMode || ChuckerFlutter.showOnRelease
      ? ChuckerButton.getInstance()
      : const SizedBox.shrink();

  ///[showNotificationOptions] show notification on toast or notification bar.
  static ShowNotificationOptions showNotificationOptions =
      ShowNotificationOptions.toast;

  /// init [NotificationService] for showing notification
  static void withLocalNotification() {
    showNotificationOptions = !kIsWeb
        ? ShowNotificationOptions.notification
        : ShowNotificationOptions.toast;
    if (showNotificationOptions == ShowNotificationOptions.notification) {
      NotificationService.init(
        navigatorObserver: ChuckerFlutter.navigatorObserver,
      );
    }
  }
}
