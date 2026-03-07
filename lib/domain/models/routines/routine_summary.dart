import 'package:too_many_tabs/domain/models/routines/routine_bin.dart';
import 'package:too_many_tabs/ui/home/view_models/routine_state.dart';

class RoutineSummary {
  RoutineSummary({
    required int id,
    required String name,
    required int goal, // expected daily duration as multiple of 30m
    required bool running,
    required Duration spent,
    required DateTime? lastStarted, // last time the routine was started
    required RoutineBin bin,
  }) : _id = id,
       _goal = goal,
       _name = name,
       _spent = spent,
       _running = running,
       _bin = bin,
       _lastStarted = lastStarted;

  final int _id, _goal;
  final String _name;
  final Duration _spent;
  final bool _running;
  final DateTime? _lastStarted;
  final RoutineBin _bin;

  int get id => _id;
  String get name => _name;
  Duration get goal => Duration(minutes: 30) * _goal;
  Duration get spent => _spent;
  bool get running => _running;
  DateTime? get lastStarted => _lastStarted;
  RoutineBin get bin => _bin;

  Duration spentAt(DateTime at) {
    if (_lastStarted == null || !_running) {
      return _spent;
    }
    return at.difference(_lastStarted) + _spent;
  }

  RoutineState state(DateTime at) {
    final spent = spentAt(at);
    if (running) {
      if (spent >= goal) {
        return RoutineState.overRun;
      }
      return RoutineState.isRunning;
    }
    if (goal == Duration.zero) {
      return RoutineState.noPlannedGoal;
    }
    if (spent <= Duration(minutes: 5)) {
      return RoutineState.notStarted;
    }
    if (spent >= goal) {
      return RoutineState.goalReached;
    }
    return RoutineState.inProgress;
  }

  @override
  String toString() {
    return [
      'RoutineSummary(',
      [
        'name="$_name"',
        'id=$_id',
        'goal=${Duration(minutes: _goal * 30)}',
        'spent=$_spent',
        'running=$_running',
        'lastStarted=$_lastStarted',
        'bin=${_bin.toStringValue()}',
      ].join(' '),
      ')',
    ].join('');
  }
}
