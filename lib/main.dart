import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:too_many_tabs/config/dependencies.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/data/services/database/database_prepare.dart';
import 'package:too_many_tabs/data/services/database/shared_database_service.dart';
import 'package:too_many_tabs/routing/router.dart';
import 'package:too_many_tabs/ui/core/themes/theme.dart';
import 'package:too_many_tabs/ui/core/ui/scroll_behavior.dart';
import 'package:too_many_tabs/utils/result.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final resultDatabase = await prepareDatabase();
  final Database db;
  switch (resultDatabase) {
    case Error<Database>():
      return;
    case Ok<Database>():
  }
  db = resultDatabase.value;

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
    final client = DatabaseClient(db: db);
    if (record.level >= Level.INFO) {
      client.log(
        level: record.level.name,
        time: record.time,
        logger: record.loggerName,
        message: record.message,
      );
    }
  });

  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final notificationsPluginDarwinSettings = DarwinInitializationSettings();
  final notificationsInitializationSettings = InitializationSettings(
    iOS: notificationsPluginDarwinSettings,
  );
  await notificationsPlugin.initialize(
    notificationsInitializationSettings,
    onDidReceiveNotificationResponse: (notification) {},
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await _configureLocalTimeZone();

  final sds = SharedDatabaseService();
  await sds.initialize();

  runApp(
    MultiProvider(
      providers: providerLocal(
        db: db,
        notificationsPlugin: notificationsPlugin,
      ),
      child: const RootRestorationScope(
        restorationId: 'root',
        child: MainApp(),
      ),
    ),
  );
}

// https://github.com/MaikuB/flutter_local_notifications/blob/30813e25acd2557a923506958ec26afd49a7e808/flutter_local_notifications/example/lib/main.dart#L189
Future<void> _configureLocalTimeZone() async {
  final log = Logger('_configureLocalTimeZone');
  tz.initializeTimeZones();
  //final timeZoneInfo = await FlutterTimezone.getLocalTimezone('UTC+1');
  tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));
  log.info('timeZoneInfo: ${tz.local}');
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForSharedDatabase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for shared database when app comes to foreground
      _checkForSharedDatabase();
    }
  }

  Future<void> _checkForSharedDatabase() async {
    final sharedPath = await SharedDatabaseService().checkForSharedDatabase();

    if (sharedPath != null) {
      _showImportDialog(sharedPath);
    }
  }

  void _showImportDialog(String sharedPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Import Database'),
        content: Text(
          'A shared database file has been detected. Do you want to replace your current database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _importDatabase(sharedPath);
            },
            child: Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _importDatabase(String sharedPath) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    await SharedDatabaseService().importSharedDatabase(
      sharedPath: sharedPath,
      currentDatabasePath:
          await databasePath(), // Replace with your actual database path
      onSuccess: () {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database imported successfully!')),
        );
        // Reload your app data here
      },
      onError: (error) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $error')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scrollBehavior: AppCustomScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router(),
      restorationScopeId: 'app',
    );
  }
}
