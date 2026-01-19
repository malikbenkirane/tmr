import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:too_many_tabs/utils/notification_channel.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

const MethodChannel platformNotifications = MethodChannel(
  'com.example.tooManyTabs/local_notifications',
);

const notificationsPortName = 'notification_send_port';

void schedulePeriodicNotification({
  required int periodInMinutes,
  required String title,
  required String body,
  required NotificationChannel channel,
  Map<String, Object>? payload,
}) {
  const androidNotificationDetails = AndroidNotificationDetails(
    'ttt_routines',
    'ttt_routines',
    priority: Priority.max,
    importance: Importance.max,
    fullScreenIntent: true,
  );
  const darwinNotificationDetails = DarwinNotificationDetails(
    interruptionLevel: InterruptionLevel.timeSensitive,
  );
  final notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );

  flutterLocalNotificationsPlugin.periodicallyShowWithDuration(
    channel.index,
    'title',
    'body',
    Duration(minutes: periodInMinutes),
    notificationDetails,
    payload: jsonEncode({
      'channel_id': channel.index,
      'scheduled_at': DateTime.now().toIso8601String(),
      if (payload != null) ...payload,
    }),
  );
}
