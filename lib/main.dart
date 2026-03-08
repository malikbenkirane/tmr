import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/routing/router.dart';
import 'package:too_many_tabs/ui/core/ui/scroll_behavior.dart';
import 'package:too_many_tabs/utils/result.dart';
import 'package:timeago/timeago.dart' as timeago;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
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

  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      isForegroundMode: true,
      onStart: onStart,
      notificationChannelId: 'android_foreground',
      foregroundServiceNotificationId: 888,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final DatabaseClient conn;
  {
    final result = await prepareDatabaseClient();
    switch (result) {
      case Error<DatabaseClient>():
        return true;
      case Ok<DatabaseClient>():
        conn = result.value;
    }
  }

  final RoutineSummary? running;
  {
    final result = await conn.getRunningRoutine();
    switch (result) {
      case Error<RoutineSummary?>():
        return true;
      case Ok<RoutineSummary?>():
        running = result.value;
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final int? id;
  final String? name;
  if (running == null) {
    id = prefs.getInt('lastRunningId');
    name = prefs.getString('lastRunningName');
  } else {
    id = running.id;
    prefs.setInt('lastRunningId', id);
    name = running.name;
    prefs.setString('lastRunningName', name);
  }

  if (id == null || name == null) return true;

  String? message;
  if (running == null) {
    final DateTime? lastStopAt;
    {
      final result = await conn.lastLog(id, RoutineState.stopped);
      switch (result) {
        case Error<DateTime?>():
          return true;
        case Ok<DateTime?>():
          lastStopAt = result.value;
      }
    }
    if (lastStopAt == null) return true;
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
          return true;
        case Ok<DateTime?>():
          lastStartAt = result.value;
      }
    }
    if (lastStartAt == null) return true;
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

  if (message == null) return true;

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

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

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
