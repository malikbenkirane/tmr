import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:too_many_tabs/data/repositories/routines/special_session_duration.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/domain/models/settings/special_goals.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class HeaderRoutinesDynamicGoalLabel extends StatefulWidget {
  const HeaderRoutinesDynamicGoalLabel({
    super.key,
    required this.routines,
    required this.specialGoals,
    required this.specialSessionState,
  });

  final List<RoutineSummary> routines;
  final SpecialGoals specialGoals;
  final SpecialSessionDuration specialSessionState;

  @override
  createState() => _HeaderRoutinesDynamicGoalLabelState();
}

class _HeaderRoutinesDynamicGoalLabelState
    extends State<HeaderRoutinesDynamicGoalLabel> {
  late Timer _timer;
  bool _ticking = false;
  late Duration _goal;
  late Duration _goalSpecial;

  @override
  void dispose() {
    if (_ticking) _timer.cancel();
    super.dispose();
  }

  void _refreshGoal() {
    var inPause = true;
    var goal = Duration();
    for (final routine in widget.routines) {
      if (routine.running) {
        inPause = false;
        var spent = routine.spent;
        if (routine.lastStarted != null) {
          spent += DateTime.now().difference(routine.lastStarted!);
        }
        final left = routine.goal - spent;
        if (left > Duration()) {
          goal += left;
        }
        continue;
      }
      if (routine.lastStarted == null) {
        goal += routine.goal;
        continue;
      }
      final left = routine.goal - routine.spent;
      if (left > Duration()) {
        goal += left;
      }
    }
    var goalSpecial = Duration();
    for (final goalSetting in [
      widget.specialGoals.sitBack,
      widget.specialGoals.startSlow,
      widget.specialGoals.stoke,
      widget.specialGoals.slowDown,
    ]) {
      goalSpecial += goalSetting;
    }
    goalSpecial -= widget.specialSessionState.duration;
    if (widget.specialSessionState.current != null) {
      goalSpecial -= DateTime.now().difference(
        widget.specialSessionState.current!,
      );
      inPause = false;
    }
    if (goalSpecial < Duration()) {
      goalSpecial = Duration();
    }
    if (inPause && _ticking) {
      _ticking = false;
      _timer.cancel();
    }
    if (!inPause && !_ticking) {
      _ticking = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _refreshGoal();
      });
    }
    setState(() {
      _goal = goal;
      _goalSpecial = goalSpecial;
      // debugPrint('$goal $goalSpecial');
    });
  }

  @override
  build(BuildContext context) {
    _refreshGoal();
    final left = formatUntilGoal(_goal, Duration(), forceSuffix: false);
    final leftSpecial = formatUntilGoal(
      _goalSpecial,
      Duration(),
      forceSuffix: false,
    );
    return Row(
      spacing: 5,
      children: [
        ...[
          (Symbols.more_time, leftSpecial),
          (Symbols.rewarded_ads, left),
        ].map((item) => _GoalDisplay(icon: item.$1, text: item.$2)),
      ],
    );
  }
}

@immutable
class _GoalDisplay extends StatelessWidget {
  const _GoalDisplay({required this.text, required this.icon});
  final String text;
  final IconData icon;
  @override
  build(BuildContext context) {
    final definitiveTextStyle = TextStyle(
      color: labelColor(context, Label.homeScreenGoalTotal),
      fontWeight: FontWeight.w500,
      fontSize: 10.5,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 2,
      children: [
        Text(text == "done" ? "done" : text, style: definitiveTextStyle),
        Icon(
          icon,
          size: 16,
          color: labelColor(
            context,
            Label.homeScreenGoalTotal,
          ).withValues(alpha: .6),
        ),
      ],
    );
  }
}
