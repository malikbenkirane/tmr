import 'dart:async';
import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/utils/notification_channel.dart';
import 'package:too_many_tabs/utils/pomodoro_trigger.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final selectNotificationStream =
    StreamController<NotificationResponse>.broadcast();

const MethodChannel platformNotifications = MethodChannel(
  'com.example.tooManyTabs/local_notifications',
);

void handleNotificationResponse(HomeViewmodel homeModel) {
  selectNotificationStream.stream.listen((
    NotificationResponse? response,
  ) async {
    debugPrint(
      'notification response stream: ${response?.payload} data ${response?.data}',
    );
    final payload = response?.payload;
    final id = response?.id;
    if (payload != null && id != null) {
      if (id == NotificationChannel.pomodoro.index) {
        final {"onTap": trigger as String} = jsonDecode(payload);
        debugPrint("selectNotificationStream: channel=$id onTap=$trigger");
        switch (trigger.toPomodoroTrigger()) {
          case PomodoroTrigger.breakPeriod:
            homeModel.startOrStopRoutine.execute(homeModel.pinnedRoutine!.id);
          case PomodoroTrigger.workPeriod:
            homeModel.startOrStopRoutine.execute(
              homeModel.lastPinnedRoutine!.id,
            );
        }
      }
      if (id == NotificationChannel.wrapUp.index) {
        await flutterLocalNotificationsPlugin.cancel(id);
      }
    }
  });
}

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
    sound: "spacial.aif",
  );
  final notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: darwinNotificationDetails,
  );

  flutterLocalNotificationsPlugin.periodicallyShowWithDuration(
    channel.index,
    title,
    body,
    Duration(minutes: periodInMinutes),
    notificationDetails,
    payload: jsonEncode({
      'channel_id': channel.index,
      'scheduled_at': DateTime.now().toIso8601String(),
      if (payload != null) ...payload,
    }),
  );
}
