import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/data/repositories/routines/special_session_duration.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/domain/models/settings/special_goals.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/home/widgets/header_routines_dynamic_goal_label.dart';

class HeaderEta extends StatefulWidget {
  const HeaderEta({
    super.key,
    required this.routines,
    required this.specialGoals,
    required this.specialSessions,
  });

  final List<RoutineSummary> routines;
  final SpecialGoals specialGoals;
  final Map<SpecialGoal, SpecialSessionDuration> specialSessions;

  @override
  createState() => _HeaderEtaSTate();
}

class _HeaderEtaSTate extends State<HeaderEta> {
  late final AppLifecycleListener _listener;

  DateTime _eta = DateTime.now();
  late Timer _timer;
  bool _ticking = false;

  @override
  initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _refreshEta);
  }

  @override
  dispose() {
    _listener.dispose();
    if (_ticking) _timer.cancel();
    super.dispose();
  }

  void _refreshEta() {
    final now = DateTime.now();
    var eta = DateTime.now();
    var inPause = true;
    for (final routine in widget.routines) {
      if (routine.running) inPause = false;
      if (routine.lastStarted == null) {
        eta = eta.add(routine.goal);
      } else {
        final left =
            routine.goal -
            routine.spent -
            (routine.running
                ? now.difference(routine.lastStarted!)
                : Duration());
        if (left > Duration()) {
          eta = eta.add(left);
        }
      }
    }

    for (final goal in widget.specialSessions.keys) {
      final session = widget.specialSessions[goal]!;
      final g = widget.specialGoals.of(goal);
      final left = g - session.spentAt(now);
      final leftAbs = left < Duration.zero ? Duration.zero : left;
      if (session.current != null) inPause = false;
      eta = eta.add(leftAbs);
    }
    setState(() {
      _eta = eta;
    });

    if (inPause && !_ticking) {
      _ticking = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _refreshEta();
      });
    }
    if (!inPause && _ticking) {
      _ticking = false;
      _timer.cancel();
    }
  }

  @override
  build(BuildContext context) {
    _refreshEta();
    return Column(
      spacing: 2,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          spacing: 2,
          children: [
            Icon(
              Icons.alarm,
              size: 19,
              color: labelColor(
                context,
                Label.homeScreenDayETA,
              ).withValues(alpha: .8),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  _format(_eta),
                  style: TextStyle(
                    fontSize: 18,
                    color: labelColor(context, Label.homeScreenDayETA),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    (_eta.hour >= 12 ? "pm" : "am").toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: labelColor(context, Label.homeScreenDayETA),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        HeaderRoutinesDynamicGoalLabel(
          routines: widget.routines,
          specialGoals: widget.specialGoals,
          specialSessionState: widget.specialSessions,
        ),
      ],
    );
  }

  String _format(DateTime t) {
    var h = t.hour;
    if (h == 0 || h == 12) {
      h = 12;
    } else {
      h = h.remainder(12);
    }
    return '$h:${t.minute.toString().padLeft(2, "0")}';
  }
}
