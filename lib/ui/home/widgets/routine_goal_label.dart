import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class RoutineGoalLabel extends StatelessWidget {
  const RoutineGoalLabel({
    super.key,
    required this.spent,
    required this.goal,
    required this.running,
  });
  final Duration spent, goal;
  final bool running;

  @override
  build(BuildContext context) {
    final done = spent.inMinutes >= goal.inMinutes;

    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    final textStyle = TextStyle(
      color: running
          ? colorScheme.onPrimary
          : (darkMode ? colorScheme.onPrimaryContainer : colorScheme.primary),
      fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
      fontWeight: darkMode
          ? (running ? FontWeight.w500 : FontWeight.w400)
          : (running ? FontWeight.w600 : FontWeight.w300),
    );

    final textStyleDone = TextStyle(
      color: colorScheme.onSurface,
      fontSize: Theme.of(context).textTheme.labelMedium!.fontSize,
      fontWeight: FontWeight.w200,
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: done
            ? colorScheme.surfaceContainerHigh
            : (running
                  ? (darkMode ? colorScheme.primary : colorScheme.primary)
                  : (darkMode
                        ? colorScheme.primaryContainer
                        : colorScheme.secondaryContainer)),
      ),
      child: done
          ? Text('Completed', style: textStyleDone)
          : (!running
                ? Text(formatUntilGoal(goal, spent), style: textStyle)
                : Row(
                    spacing: 4,
                    children: [
                      Text('Done within', style: textStyle),
                      Text(formatUntilGoal(goal, spent), style: textStyle),
                    ],
                  )),
    );
  }
}

class RoutineGoalDynamicLabel extends StatefulWidget {
  const RoutineGoalDynamicLabel({
    super.key,
    required this.spent,
    required this.goal,
    required this.lastStarted,
    required this.running,
    required this.restorationId,
  });

  final Duration spent, goal;
  final DateTime lastStarted;
  final bool running;
  final String? restorationId;

  @override
  createState() => RoutineGoalDynamicLabelState();
}

class RoutineGoalDynamicLabelState extends State<RoutineGoalDynamicLabel>
    with RestorationMixin {
  late Timer _timer;
  final _minutesSpent = RestorableInt(0);

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_minutesSpent, 'minutes_spent_value');
  }

  @override
  initState() {
    super.initState();
    _startTimer();
  }

  @override
  dispose() {
    _timer.cancel();
    _minutesSpent.dispose();
    super.dispose();
  }

  static const _refreshPeriod = Duration(milliseconds: 100);

  void _startTimer() {
    _timer = Timer.periodic(_refreshPeriod, (timer) {
      setState(() {
        _minutesSpent.value =
            widget.spent.inMinutes +
            DateTime.now().difference(widget.lastStarted).inMinutes;
      });
    });
  }

  @override
  build(BuildContext context) {
    return RoutineGoalLabel(
      spent: Duration(minutes: _minutesSpent.value),
      goal: widget.goal,
      running: widget.running,
    );
  }
}
