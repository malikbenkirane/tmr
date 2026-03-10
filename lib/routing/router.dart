import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite/sqflite.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository_local.dart';
import 'package:too_many_tabs/data/repositories/settings/settings_repository_sqlite.dart';
import 'package:too_many_tabs/data/repositories/signal_ratio/signal_ratio_repository_local.dart';
import 'package:too_many_tabs/data/services/database/database_client.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/archives/view_models/archives_viewmodel.dart';
import 'package:too_many_tabs/ui/archives/widgets/archives_screen.dart';
import 'package:too_many_tabs/ui/bin/view_models/bin_viewmodel.dart';
import 'package:too_many_tabs/ui/bin/widgets/bin_screen.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/view_models/search_bar_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/home_screen.dart';
import 'package:too_many_tabs/ui/load/widgets/error_screen.dart';
import 'package:too_many_tabs/ui/load/widgets/load_screen.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';
import 'package:too_many_tabs/ui/notes/view_models/pomodoro_payload.dart';
import 'package:too_many_tabs/ui/notes/widgets/notes_screen.dart';
import 'package:too_many_tabs/ui/settings/view_models/settings_viewmodel.dart';
import 'package:too_many_tabs/ui/settings/widgets/settings_screen.dart';
import 'package:too_many_tabs/utils/result.dart';
import 'package:too_many_tabs/data/services/database/database_prepare.dart';
import 'package:logging/logging.dart';

Future<Result<(DatabaseClient, Duration)>> prepareDatabaseClient() async {
  final trace = DateTime.now();
  final result = await prepareDatabase();
  final Database db;
  switch (result) {
    case Error<Database>():
      return Result.error(result.error);
    case Ok<Database>():
  }
  db = result.value;
  final client = DatabaseClient(db: db);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) async {
    if (record.level >= Level.INFO) {
      client.log(
        level: record.level.name,
        time: record.time,
        logger: record.loggerName,
        message: record.message,
      );
    }
  });
  return Result.ok((client, DateTime.now().difference(trace)));
}

GoRouter router() => GoRouter(
  restorationScopeId: 'router',
  initialLocation: Routes.home,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) =>
          FutureBuilder<Result<(DatabaseClient, Duration)>>(
            future: prepareDatabaseClient(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return LoadScreen();
              }
              final result = snapshot.data!;
              switch (result) {
                case Error<(DatabaseClient, Duration)>():
                  return ErrorScreen();
                case Ok<(DatabaseClient, Duration)>():
                  debugPrint(
                    '[trace] prepareDatabaseClient: ${result.value.$2}',
                  );
              }
              final databaseClient = result.value.$1;
              final routinesRepository = RoutinesRepositoryLocal(
                databaseClient: databaseClient,
              );
              final settingsRepository = SettingsRepositorySqlite(
                db: databaseClient,
              );
              final signalRatioRepository = SignalRatioRepositoryLocal(
                databaseClient: result.value.$1,
              );
              final homeViewmodel = HomeViewmodel(
                signalRatioRepository: signalRatioRepository,
                routinesRepository: routinesRepository,
                settingsRepository: settingsRepository,
              );
              final notesViewmodel = NotesViewmodel(repo: routinesRepository);
              final settingsViewmodel = SettingsViewmodel(
                repository: settingsRepository,
              );
              final searchBarViewmodel = SearchBarViewmodel(
                routinesRepository: routinesRepository,
              );
              return HomeScreen(
                homeModel: homeViewmodel,
                notesModel: notesViewmodel,
                settingsModel: settingsViewmodel,
                searchModel: searchBarViewmodel,
              );
            },
          ),
    ),
    GoRoute(
      path: Routes.archives,
      builder: (context, state) => FutureBuilder(
        future: prepareDatabaseClient(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadScreen();
          }
          final result = snapshot.data!;
          switch (result) {
            case Error<(DatabaseClient, Duration)>():
              return ErrorScreen();
            case Ok<(DatabaseClient, Duration)>():
              debugPrint('[trace] prepareDatabaseClient: ${result.value.$2}');
          }
          final databaseClient = result.value.$1;
          final routinesRepository = RoutinesRepositoryLocal(
            databaseClient: databaseClient,
          );
          final viewModel = ArchivesViewmodel(
            routinesRepository: routinesRepository,
          );
          return ArchivesScreen(viewModel: viewModel);
        },
      ),
    ),
    GoRoute(
      path: Routes.bin,
      builder: (context, state) => FutureBuilder(
        future: prepareDatabaseClient(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadScreen();
          }
          final result = snapshot.data!;
          switch (result) {
            case Error<(DatabaseClient, Duration)>():
              return ErrorScreen();
            case Ok<(DatabaseClient, Duration)>():
              debugPrint('[trace]: prepareDatabaseClient: ${result.value.$2}');
          }
          final databaseClient = result.value.$1;
          final routinesRepository = RoutinesRepositoryLocal(
            databaseClient: databaseClient,
          );
          final viewModel = BinViewmodel(
            routinesRepository: routinesRepository,
          );
          return BinScreen(viewModel: viewModel);
        },
      ),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => FutureBuilder(
        future: prepareDatabaseClient(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadScreen();
          }
          final result = snapshot.data!;
          switch (result) {
            case Error<(DatabaseClient, Duration)>():
              return ErrorScreen();
            case Ok<(DatabaseClient, Duration)>():
              debugPrint('[trace] prepareDatabaseClient: ${result.value.$2}');
          }
          final databaseClient = result.value.$1;
          final settingsRepository = SettingsRepositorySqlite(
            db: databaseClient,
          );
          final viewModel = SettingsViewmodel(repository: settingsRepository);
          return SettingsScreen(viewModel: viewModel);
        },
      ),
    ),
    GoRoute(
      path: '${Routes.notes}/:routineId',
      builder: (context, state) => FutureBuilder(
        future: prepareDatabaseClient(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadScreen();
          }
          final result = snapshot.data!;
          switch (result) {
            case Error<(DatabaseClient, Duration)>():
              return ErrorScreen();
            case Ok<(DatabaseClient, Duration)>():
              debugPrint('[trace] prepareDatabaseClient: ${result.value.$2}');
          }
          final databaseClient = result.value.$1;
          // debugPrint('${state.pathParameters}');
          final routineId = state.pathParameters['routineId']!;

          final routinesRepository = RoutinesRepositoryLocal(
            databaseClient: databaseClient,
          );
          final settingsRepository = SettingsRepositorySqlite(
            db: databaseClient,
          );
          final viewModel = NotesViewmodel(
            repo: routinesRepository,
            routineId: int.parse(routineId),
          );
          final signalRatioRepository = SignalRatioRepositoryLocal(
            databaseClient: databaseClient,
          );
          final homeViewmodel = HomeViewmodel(
            signalRatioRepository: signalRatioRepository,
            routinesRepository: routinesRepository,
            settingsRepository: settingsRepository,
          );
          PomodoroPayload? pomodoroPayload;
          if (state.extra != null) {
            pomodoroPayload = state.extra as PomodoroPayload;
          }
          return NotesScreen(
            notesViewmodel: viewModel,
            homeViewmodel: homeViewmodel,
            pomodoroPayload: pomodoroPayload,
          );
        },
      ),
    ),
  ],
);
