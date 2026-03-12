import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/routing/router.dart';
import 'package:too_many_tabs/ui/core/ui/scroll_behavior.dart';
import 'package:too_many_tabs/utils/preferences.dart';
import 'package:too_many_tabs/utils/result.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:workmanager/workmanager.dart';

Future<void> initializeService() async {
  await FlutterLocalNotificationsPlugin().cancelAllPendingNotifications();

  Workmanager().initialize(callbackDispatcher);

  Workmanager().registerPeriodicTask(
    "pomo_reminder",
    "pomo_reminder",
    frequency: const Duration(minutes: 15),
  );

  const channel = AndroidNotificationChannel(
    'android_foreground',
    'Android Foreground Service',
  );
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "pomo_reminder":
        await _backgroundPomoCheck();
      default:
        break;
    }

    return Future.value(true);
  });
}

Future<void> _backgroundPomoCheck() async {
  final DatabaseClient conn;
  {
    final result = await prepareDatabaseClient();
    switch (result) {
      case Error<(DatabaseClient, Duration)>():
        return;
      case Ok<(DatabaseClient, Duration)>():
        conn = result.value.$1;
    }
  }
  final RoutineSummary? running;
  {
    final result = await conn.getRunningRoutine();
    switch (result) {
      case Error<RoutineSummary?>():
        return;
      case Ok<RoutineSummary?>():
        running = result.value;
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final int? id;
  final String? name;
  if (running == null) {
    id = prefs.getInt(Preferences.lastRunningId);
    name = prefs.getString(Preferences.lastRunningName);
  } else {
    id = running.id;
    name = running.name;
  }

  if (id == null || name == null) return;

  String? message;
  if (running == null) {
    final DateTime? lastStopAt;
    {
      final result = await conn.lastLog(id, RoutineState.stopped);
      switch (result) {
        case Error<DateTime?>():
          return;
        case Ok<DateTime?>():
          lastStopAt = result.value;
      }
    }
    if (lastStopAt == null) return;
    {
      final now = DateTime.now();
      const pomo = Duration(minutes: 5);
      final session = now.difference(lastStopAt);
      if (DateTime.now().difference(lastStopAt) > const Duration(minutes: 5)) {
        final t = timeago.format(now.subtract(session - pomo));
        message = 'Your break should have ended $t';
      }
    }
  } else {
    final DateTime? lastStartAt;
    {
      final result = await conn.lastLog(id, RoutineState.started);
      switch (result) {
        case Error<DateTime?>():
          return;
        case Ok<DateTime?>():
          lastStartAt = result.value;
      }
    }
    if (lastStartAt == null) return;
    {
      const pomo = Duration(minutes: 20);
      final now = DateTime.now();
      final session = now.difference(lastStartAt);
      if (session > pomo) {
        final t = timeago.format(now.subtract(session - pomo));
        message = 'A break was supposed to start $t';
      }
    }
  }

  if (message == null) return;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin.show(
    0,
    name,
    message,
    NotificationDetails(
      iOS: DarwinNotificationDetails(
        sound: 'spacial.aif',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isIOS || Platform.isAndroid) {
    await initializeService();
  }

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) async {
    // debugPrint(
    //   [
    //     'level=${record.level}',
    //     'time=${record.time}',
    //     'logger=${record.loggerName}',
    //     'msg=${record.message}',
    //   ].join(' '),
    // );
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const RootRestorationScope(restorationId: 'root', child: MainApp()));
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint(
    'notification(${notificationResponse.id}) action tapped: '
    '${notificationResponse.actionId} with'
    ' payload: ${notificationResponse.payload}',
  );
  if (notificationResponse.input?.isNotEmpty ?? false) {
    debugPrint(
      'notification action tapped with input: ${notificationResponse.input}',
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seedColor = Colors.black;
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
    );
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
    );

    return MaterialApp.router(
      scrollBehavior: AppCustomScrollBehavior(),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router(),
      restorationScopeId: 'app',
    );
  }
}
