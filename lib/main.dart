import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/routing/router.dart';
import 'package:too_many_tabs/ui/core/ui/scroll_behavior.dart';
import 'package:too_many_tabs/utils/notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
