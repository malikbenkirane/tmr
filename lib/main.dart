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
      onForeground: onForeground,
      onBackground: onIosBackground,
    ),
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      isForegroundMode: true,
      onStart: onForeground,
      notificationChannelId: 'android_foreground',
      foregroundServiceNotificationId: 888,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final DatabaseClient dbc;
  {
    final result = await prepareDatabaseClient();
    switch (result) {
      case Error<DatabaseClient>():
        debugPrint('ERROR prepareDatabaseClient: ${result.error}');
        return;
      case Ok<DatabaseClient>():
        dbc = result.value;
    }
  }

  Timer.periodic(const Duration(minutes: 1), (timer) async {
    if (service is IOSServiceInstance) {
      final RoutineSummary? routine;
      {
        final result = await dbc.getRunningRoutine();
        switch (result) {
          case Error<RoutineSummary?>():
            debugPrint('ERROR getRunningRoutine: ${result.error}');
          case Ok<RoutineSummary?>():
            routine = result.value;
        }
      }
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) async {
    debugPrint(
      [
        'level=${record.level}',
        'time=${record.time}',
        'logger=${record.loggerName}',
        'msg=${record.message}',
      ].join(' '),
    );
  });

  initializeLocalNotifications();

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

void initializeLocalNotifications() async {
  final List<DarwinNotificationCategory> darwinNotificationCategories = [];
  final darwinInitializationSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: darwinNotificationCategories,
  );
  final androidInitializationSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  final initializationSettings = InitializationSettings(
    iOS: darwinInitializationSettings,
    android: androidInitializationSettings,
    macOS: darwinInitializationSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: selectNotificationStream.add,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
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
