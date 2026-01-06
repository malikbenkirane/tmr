import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:timezone/browser.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/data/repositories/routines/special_session_duration.dart';
import 'package:too_many_tabs/data/repositories/settings/settings_repository.dart';
import 'package:too_many_tabs/domain/models/routines/routine_bin.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/domain/models/settings/settings_summary.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal_session.dart';
import 'package:too_many_tabs/domain/models/settings/special_goals.dart';
import 'package:too_many_tabs/notifications.dart';
import 'package:too_many_tabs/ui/home/view_models/destination_bucket.dart';
import 'package:too_many_tabs/ui/home/view_models/goal_update.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/notification_code.dart';
import 'package:too_many_tabs/utils/result.dart';
import 'package:timezone/timezone.dart' as tz;

class HomeViewmodel extends ChangeNotifier {
  HomeViewmodel({
    required RoutinesRepository routinesRepository,
    required FlutterLocalNotificationsPlugin notificationsPlugin,
    required SettingsRepository settingsRepository,
  }) : _routinesRepository = routinesRepository,
       _notificationsPlugin = notificationsPlugin,
       _settingsRepository = settingsRepository {
    load = Command0(_load)..execute();
    startOrStopRoutine = Command1(_startOrStopRoutine);
    updateRoutineGoal = Command1(_updateRoutineGoal);
    addRoutine = Command1(_createRoutine);
    archiveOrBinRoutine = Command1(_archiveOrBinRoutine);
    updateSpecialSessionStatus = Command1(_updateSpecialSessionStatus);
    toggleSpecialSession = Command1(_toggleSpecialSession);
  }

  final RoutinesRepository _routinesRepository;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final _log = Logger('HomeViewmodel');
  List<RoutineSummary> _routines = [];
  RoutineSummary? _pinnedRoutine;
  int? _lastCreatedRoutineID;

  late Command0 load;
  late Command1<void, int> startOrStopRoutine;
  late Command1<void, GoalUpdate> updateRoutineGoal;
  late Command1<void, String> addRoutine;
  late Command1<void, (int, DestinationBucket)> archiveOrBinRoutine;
  late Command1<void, int> trashRoutine;
  late Command1<void, DateTime> updateSpecialSessionStatus;
  late Command1<void, SpecialGoal> toggleSpecialSession;

  List<RoutineSummary> get routines => _routines;
  RoutineSummary? get pinnedRoutine => _pinnedRoutine;
  int? get lastCreatedRoutineID => _lastCreatedRoutineID;

  bool _newDay = true;
  bool get newDay => _newDay;

  final SettingsRepository _settingsRepository;

  Future<Result> _load() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final bin in [
        RoutineBin.today,
        RoutineBin.archives,
        RoutineBin.backlog,
      ]) {
        final result = await _routinesRepository.getRoutinesList(bin);
        switch (result) {
          case Error<List<RoutineSummary>>():
            _log.warning(
              '_load: getRoutinesList(${bin.toStringValue()}) ${result.error}',
            );
            return result;
          case Ok<List<RoutineSummary>>():
            for (final routine in result.value) {
              if (routine.lastStarted != null &&
                  routine.lastStarted!.isAfter(today)) {
                _newDay = false;
              }
            }
            _log.fine(
              '_load: getRoutinesList(${bin.toStringValue()}): ${result.value.length} routines loaded',
            );
            if (bin == RoutineBin.today) {
              _routines = _listRoutines(result.value);
            }
        }
      }

      await _updateNotifications();
      await _updateSpecialSessionStatus(DateTime.now());

      return await _updateRunningRoutine();
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _archiveOrBinRoutine(
    (int, DestinationBucket) archiveOrBin,
  ) async {
    final id = archiveOrBin.$1;
    final destination = archiveOrBin.$2;
    try {
      final resultRunning = await _routinesRepository.getRunningRoutine();
      switch (resultRunning) {
        case Error<RoutineSummary?>():
          _log.warning(
            '_archiveOrBinRoutine: failed to get running routine: ${resultRunning.error}',
          );
        case Ok<RoutineSummary?>():
          if (resultRunning.value != null && resultRunning.value!.id == id) {
            final resultStop = await _routinesRepository.logStop(
              resultRunning.value!.id,
              DateTime.now(),
            );
            switch (resultStop) {
              case Error<void>():
                _log.warning(
                  '_archiveOrBinRoutine: failed to stop $id: ${resultStop.error}',
                );
                return resultStop;
              case Ok<void>():
                _log.fine('_archiveOrBinRoutine: stopped $id');
                _pinnedRoutine = null;
            }
          }
      }

      final Result<void> resultAction;
      if (destination == DestinationBucket.archives) {
        resultAction = await _routinesRepository.binRoutine(id);
      } else {
        resultAction = await _routinesRepository.archiveRoutine(id);
      }
      switch (resultAction) {
        case Error<void>():
          _log.warning(
            '_archiveOrBinRoutine: action(${destination.destination}) $id: ${resultAction.error}',
          );
          return resultAction;
        case Ok<void>():
          _log.fine(
            '_archiveOrBinRoutine: action(${destination.destination}) $id',
          );
      }

      await _load();

      return Result.ok(null);
    } on Exception catch (e) {
      _log.warning('_archiveOrBinRoutine: $e');
      return Result.error(e);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _createRoutine(String name) async {
    try {
      final resultAdd = await _routinesRepository.addRoutine(name);
      switch (resultAdd) {
        case Error<int>():
          _log.warning('_createRoutine add routine: ${resultAdd.error}');
          return Result.error(resultAdd.error);
        case Ok<int>():
          _lastCreatedRoutineID = resultAdd.value;
          _log.fine(
            '_createRoutine added routine $name id=$_lastCreatedRoutineID',
          );
      }

      return _load();
    } on Exception catch (e) {
      _log.warning('_createRoutine: _load: $e');
      return Result.error(e);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _updateSpecialNotifications(SpecialGoals settings) async {
    try {
      for (final code in [
        NotificationCode.specialGoalStoke50,
        NotificationCode.specialGoalStoke90,
        NotificationCode.specialGoalSitback5,
        NotificationCode.specialGoalSitback15,
        NotificationCode.specialGoalSitback50,
        NotificationCode.specialGoalSitback100,
        NotificationCode.specialGoalStartSlow33,
        NotificationCode.specialGoalStartSlow66,
        NotificationCode.specialGoalStartSlow100,
      ]) {
        await _notificationsPlugin.cancel(code.code);
      }

      SpecialSessionDuration session;
      {
        final result = await _routinesRepository
            .currentSpecialSessionDuration();
        switch (result) {
          case Error<SpecialSessionDuration?>():
            _log.warning(
              '_updateSpecialNotifications: currentSpecialSessionDuration: ${result.error}',
            );
            return;
          case Ok<SpecialSessionDuration?>():
            if (result.value == null) return;
            session = result.value!;
        }
      }

      final spent =
          session.duration +
          (session.current != null
              ? DateTime.now().difference(session.current!)
              : Duration());
      final now = DateTime.now();

      final scheduled = <TZDateTime>[];

      switch (_runningSpecialSession!) {
        case SpecialGoal.stoke:
          final goal = settings.stoke.inMinutes;
          final ratio = spent.inMinutes / goal;

          if (ratio <= .9) {
            scheduled.add(
              await scheduleNotification(
                title: 'Stoke 90%',
                body: 'Belly is full... Time to get back to work.',
                id: NotificationCode.specialGoalStoke90,
                schedule: now.add(
                  Duration(minutes: ((.9 - ratio) * goal).ceil()),
                ),
              ),
            );
          }

          if (ratio <= .5) {
            scheduled.add(
              await scheduleNotification(
                title: 'Soke 50%',
                body: 'Bong Appetite!',
                id: NotificationCode.specialGoalStoke50,
                schedule: now.add(
                  Duration(minutes: ((.5 - ratio) * goal).ceil()),
                ),
              ),
            );
          }

          break;
        case SpecialGoal.sitBack:
          scheduled.add(
            await scheduleNotification(
              title: 'Nice breeze!',
              body: '5min sit back and counting...',
              id: NotificationCode.specialGoalSitback5,
              schedule: now.add(Duration(minutes: 5)),
            ),
          );
          scheduled.add(
            await scheduleNotification(
              title: 'What a break',
              body: '15min sit back and counting...',
              id: NotificationCode.specialGoalSitback15,
              schedule: now.add(Duration(minutes: 15)),
            ),
          );

          final goal = settings.sitBack.inMinutes;
          final ratio = spent.inMinutes / goal;

          if (ratio <= 1) {
            scheduled.add(
              await scheduleNotification(
                title: 'Total allowed sit back time reached',
                body: 'No more sweet time for today, unless you insist',
                id: NotificationCode.specialGoalSitback100,
                schedule: now.add(
                  Duration(minutes: ((1 - ratio) * goal).ceil()),
                ),
              ),
            );
          }

          if (ratio <= .5) {
            scheduled.add(
              await scheduleNotification(
                title: 'Total allowed sit back time reached 50%',
                body: 'Use your rest time carefully or the day will get longer',
                id: NotificationCode.specialGoalSitback50,
                schedule: now.add(
                  Duration(minutes: ((.5 - ratio) * goal).ceil()),
                ),
              ),
            );
          }

          break;
        case SpecialGoal.startSlow:
          final goal = settings.startSlow.inMinutes;
          final ratio = spent.inMinutes / goal;

          if (ratio <= .33) {
            scheduled.add(
              await scheduleNotification(
                title: 'No need to hurry, take it easy.',
                body: 'Try to ready in ${(goal * .66).ceil()} minutes',
                id: NotificationCode.specialGoalStartSlow33,
                schedule: now.add(
                  Duration(minutes: ((.33 - ratio) * goal).ceil()),
                ),
              ),
            );
          }

          if (ratio <= .66) {
            final at = now.add(
              Duration(minutes: ((.66 - ratio) * goal).ceil()),
            );
            scheduled.add(
              await scheduleNotification(
                title: "🌈 Let's go we're about to have a beautiful day",
                body: 'Time to get ready for ${DateFormat.jm(at)}',
                id: NotificationCode.specialGoalStartSlow66,
                schedule: at,
              ),
            );
          }

          if (ratio <= 1) {
            final at = now.add(Duration(minutes: ((1 - ratio) * goal).ceil()));
            scheduled.add(
              await scheduleNotification(
                title: "Start Slow at 100%",
                body: "🏎️Let's go!",
                id: NotificationCode.specialGoalStartSlow100,
                schedule: at,
              ),
            );
          }
        default:
      }

      _log.fine('_updateSpecialNotifications: new schedule');
      for (final scheduled in scheduled) {
        _log.fine(
          '_updateSpecialNotifications: notification scheduled at $scheduled',
        );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> _updateNotifications() async {
    try {
      _log.fine('_updateNotifications: tz.local: ${tz.local}');
      for (final code in [
        NotificationCode.routineCompletedGoal,
        NotificationCode.routineHalfGoal,
        NotificationCode.routineGoalIn10Minutes,
        NotificationCode.routineGoalIn5Minutes,
        NotificationCode.routineSettleCheck,
      ]) {
        await _notificationsPlugin.cancel(code.code);
      }
      if (_pinnedRoutine == null) return;
      final left = _pinnedRoutine!.goal - _pinnedRoutine!.spent;
      final untilHalfWay = Duration(minutes: left.inMinutes ~/ 2);
      final roundedLastStarted = _pinnedRoutine!.lastStarted!.add(
        // e.g. if started at 12:00:40 rounded would be 12:01:00
        // and therefore notification is delayed by 20 seconds
        Duration(seconds: 60 - _pinnedRoutine!.lastStarted!.second),
      );
      final halfWay = roundedLastStarted.add(untilHalfWay);
      final scheduleHalfWay =
          untilHalfWay.inMinutes >= 20 && halfWay.isAfter(DateTime.now());
      if (scheduleHalfWay) {
        try {
          await scheduleNotification(
            title: _pinnedRoutine!.name,
            body: "Halfway there! ${untilHalfWay.inMinutes}min left.",
            id: NotificationCode.routineHalfGoal,
            schedule: halfWay,
          );
        } catch (e) {
          _log.warning('_updateNotifications: schedule routineHalfGoal: $e');
        }
      }
      if (!scheduleHalfWay && left.inMinutes >= 30) {
        try {
          final t = roundedLastStarted.add(Duration(minutes: 10));
          await scheduleNotification(
            title: _pinnedRoutine!.name,
            body: "Settle in! ${left.inMinutes - 10}m left.",
            id: NotificationCode.routineSettleCheck,
            schedule: t,
          );
        } catch (e) {
          _log.warning('_updateNotifications: routineSettleCheck: $e');
        }
      }

      final done = roundedLastStarted.add(
        _pinnedRoutine!.goal - _pinnedRoutine!.spent,
      );
      final scheduleDone = done.isAfter(DateTime.now());
      if (scheduleDone) {
        try {
          await scheduleNotification(
            title: _pinnedRoutine!.name,
            body: 'We\'re Done!',
            id: NotificationCode.routineCompletedGoal,
            schedule: done,
          );
        } catch (e) {
          _log.warning(
            '_updateNotifications: schedule routineCompletedGoal: $e',
          );
        }
      }

      final goalIn10 = roundedLastStarted.add(
        _pinnedRoutine!.goal - Duration(minutes: 10) - _pinnedRoutine!.spent,
      );
      final scheduleGoalIn10 = goalIn10.isAfter(DateTime.now());
      if (scheduleGoalIn10) {
        try {
          await scheduleNotification(
            title: _pinnedRoutine!.name,
            body: 'Time to wrap up! 10 mins left.',
            id: NotificationCode.routineGoalIn10Minutes,
            schedule: goalIn10,
          );
        } catch (e) {
          _log.warning(
            '_updateNotifications: schedule routineGoalIn10Minutes: $e',
          );
        }
      }
    } on Exception catch (e) {
      _log.severe('_updateNotifications: $e');
    }
  }

  Future<Result<void>> _updateRoutineGoal(GoalUpdate request) async {
    try {
      final goal30 = request.goal.inMinutes ~/ 30;

      final resultSetGoal = await _routinesRepository.setGoal(
        request.routineID,
        goal30,
      );
      switch (resultSetGoal) {
        case Error<void>():
          _log.warning(
            'set goal routine ${request.routineID}: ${resultSetGoal.error}',
          );
          return Result.error(resultSetGoal.error);
        case Ok<void>():
          _log.fine('_updateRoutineGoal: goal set for ${request.routineID}');
      }

      final resultGetRoutine = await _routinesRepository.getRoutineSummary(
        request.routineID,
      );
      switch (resultGetRoutine) {
        case Error<RoutineSummary>():
          _log.warning(
            '_updateRoutineGoal: get summary of routine ${request.routineID}: ${resultGetRoutine.error}',
          );
          return Result.error(resultGetRoutine.error);
        case Ok<RoutineSummary>():
          _log.fine(
            '_updateRoutineGoal: resultGetRoutine: ${resultGetRoutine.value}',
          );
          final resultRunning = await _routinesRepository.getRunningRoutine();
          switch (resultRunning) {
            case Error<RoutineSummary?>():
              _log.warning(
                '_updateRoutineGoal: getRunningRoutine: ${resultRunning.error}',
              );
              return Result.error(resultRunning.error);
            case Ok<RoutineSummary?>():
              _pinnedRoutine = resultRunning.value;
              _log.fine('_updateRoutineGoal: _pinnedRoutine: $_pinnedRoutine');
          }
          _routines = _routines.map((routine) {
            if (routine.id == request.routineID) {
              return resultGetRoutine.value;
            }
            return routine;
          }).toList();
      }

      await _updateNotifications();

      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<RoutineSummary?>> _updateRunningRoutine() async {
    try {
      final resultRunning = await _routinesRepository.getRunningRoutine();
      switch (resultRunning) {
        case Error<RoutineSummary?>():
          _log.warning('_load get running routine: ${resultRunning.error}');
        case Ok<RoutineSummary?>():
          _pinnedRoutine = resultRunning.value;
          await _updateNotifications();
      }
      return resultRunning;
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _startOrStopRoutine(int id) async {
    try {
      final resultRoutine = await _routinesRepository.getRoutineSummary(id);
      switch (resultRoutine) {
        case Error<RoutineSummary>():
          _log.warning(
            'Failed to get summary of routine $id',
            resultRoutine.error,
          );
          return resultRoutine;
        case Ok<RoutineSummary>():
      }

      _log.fine('_startOrStopRoutine: routine ${resultRoutine.value}');

      final now = DateTime.now();

      final Result<void> resultSwitch;
      final String action;

      bool started = false;

      if (resultRoutine.value.running) {
        resultSwitch = await _routinesRepository.logStop(id, now);
        action = 'Stopped';
      } else {
        resultSwitch = await _routinesRepository.logStart(id, now);
        action = 'Started';
        started = true;
      }

      switch (resultSwitch) {
        case Error<void>():
          _log.warning('$action failed routine[id=$id]', resultSwitch.error);
          return resultSwitch;
        case Ok<void>():
          _log.fine('$action routine $id');
      }

      if (started && _runningSpecialSession != null) {
        _toggleSpecialSession(_runningSpecialSession!);
      }

      // _routines = _listRoutines(
      //   _routines.map((routine) {
      //     if (routine.id == id) {
      //       return routine.from(
      //         setRunning: started,
      //         setLastStarted: started ? now : null,
      //       );
      //     }
      //     if (routine.running) {
      //       return routine.from(setRunning: false);
      //     }
      //     return routine;
      //   }).toList(),
      // );
      //
      // Can't do this as repository getRoutinesList does more than listing routines
      // especially "daily check".
      final resultList = await _routinesRepository.getRoutinesList(
        RoutineBin.today,
      );
      switch (resultList) {
        case Error<List<RoutineSummary>>():
          _log.warning(
            '_startOrStopRoutine: getRoutinesList: ${resultList.error}',
          );
          return Result.error(resultList.error);
        case Ok<List<RoutineSummary>>():
          _routines = _listRoutines(resultList.value);
      }

      return await _updateRunningRoutine();
    } finally {
      notifyListeners();
    }
  }

  List<RoutineSummary> _listRoutines(List<RoutineSummary> routines) {
    final List<RoutineSummary> sortedRoutines = [];
    final List<RoutineSummary> completedRoutines = [];
    final List<RoutineSummary> remainingRoutines = [];
    for (final routine in routines) {
      final completed = routine.goal <= routine.spent;
      if (routine.running) {
        _pinnedRoutine = routine;
        sortedRoutines.add(routine);
        _log.fine('running $_pinnedRoutine');
        continue;
      }
      if (completed) {
        completedRoutines.add(routine);
      } else {
        remainingRoutines.add(routine);
      }
    }
    sortedRoutines.addAll(remainingRoutines);
    sortedRoutines.addAll(completedRoutines);
    return sortedRoutines;
  }

  SpecialSessionDuration? _specialSessionStatus;
  SpecialSessionDuration? get specialSessionStatus => _specialSessionStatus;

  Future<Result<void>> _updateSpecialSessionStatus(DateTime day) async {
    try {
      final resultCurrent = await _routinesRepository.currentSpecialSession();
      switch (resultCurrent) {
        case Error<SpecialGoalSession?>():
          _log.warning(
            '_updateSpecialSessionStatus: currentSpecialSession: ${resultCurrent.error}',
          );
          return Result.error(resultCurrent.error);
        case Ok<SpecialGoalSession?>():
          _log.fine(
            '_updateSpecialSessionStatus: currentSpecialSession: ${resultCurrent.value}',
          );
      }

      _runningSpecialSession = resultCurrent.value?.goal;
      SpecialGoals goalSettings;
      {
        final result = await _settingsRepository.getSettings();
        switch (result) {
          case Error<SettingsSummary>():
            _log.warning(
              '_updateSpecialSessionStatus: getSettings: ${result.error}',
            );
            return Result.error(result.error);
          case Ok<SettingsSummary>():
            goalSettings = result.value.specialGoals;
        }
      }
      await _updateSpecialNotifications(goalSettings);

      final result = await _routinesRepository.sumSpecialSessionDurations(day);
      switch (result) {
        case Error<SpecialSessionDuration>():
          _log.warning(
            '_updateSpecialSessionStatus: sumSpecialSessionDurations: ${result.error}',
          );
          return Result.error(result.error);
        case Ok<SpecialSessionDuration>():
          _log.fine('_updateSpecialSessionStatus: ${result.value}');
          _specialSessionStatus = result.value;
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  SpecialGoal? _runningSpecialSession;
  SpecialGoal? get runningSpecialSession => _runningSpecialSession;

  RoutineSummary? _lastPinnedRoutine;

  Future<Result<void>> _toggleSpecialSession(SpecialGoal goal) async {
    try {
      final now = DateTime.now();
      final resultToggle = await _routinesRepository.toggleSpecialSession(
        goal,
        now,
      );
      switch (resultToggle) {
        case Error<(SpecialGoalSession?, SpecialGoalSession?)>():
          _log.warning(
            '_toggleSpecialSession: toggleSpecialSession: ${resultToggle.error}',
          );
          return Result.error(resultToggle.error);
        case Ok<(SpecialGoalSession?, SpecialGoalSession?)>():
      }

      final started = resultToggle.value.$2, stopped = resultToggle.value.$1;

      if (started != null) {
        _log.fine('started $started');
      }
      if (stopped != null) {
        _log.fine('stopped $stopped');
      }

      _updateSpecialSessionStatus(now);

      _log.fine(
        '_toggleSpecialSession: _runningSpecialSession: $_runningSpecialSession',
      );

      if (stopped != null && _lastPinnedRoutine != null) {
        final id = _lastPinnedRoutine!.id;
        _startOrStopRoutine(id);
        _lastPinnedRoutine = null;
        _log.fine(
          '_toggleSpecialSession: ${goal.column} started: _startOrStopRoutine($id) _lastPinnedRoutine<-null',
        );
      } else if (started != null && _pinnedRoutine != null) {
        _lastPinnedRoutine = _pinnedRoutine;
        final id = _pinnedRoutine!.id;
        _startOrStopRoutine(id);
        _log.fine(
          '_toggleSpecialSession: ${goal.column} started: refresh _lastPinnedRoutine then _startOrStopRoutine($id)',
        );
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }
}
