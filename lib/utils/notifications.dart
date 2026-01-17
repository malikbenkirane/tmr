import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

const MethodChannel platformNotifications = MethodChannel(
  'com.example.tooManyTabs/local_notifications',
);

const notificationsPortName = 'notification_send_port';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint(
    'notification(${notificationResponse.id}) action tapped:${notificationResponse.actionId} with payload:${notificationResponse.payload}',
  );
  if (notificationResponse.input?.isNotEmpty ?? false) {
    debugPrint('notification typed with input: ${notificationResponse.input}');
  }
}
