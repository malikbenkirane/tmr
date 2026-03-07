import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';

class RoutineProgressBar extends StatefulWidget {
  final RoutineSummary routine;

  const RoutineProgressBar({super.key, required this.routine});

  @override
  createState() => _RoutineProgressBarState();
}

class _RoutineProgressBarState extends State<RoutineProgressBar> {
  late Timer _timer;
  late AppLifecycleListener _listener;
  late Duration _spent;

  @override
  initState() {
    super.initState();
    _startTimer();
    _spent = widget.routine.spentAt(DateTime.now());
    _listener = AppLifecycleListener(
      onResume: () {
        setState(() {
          _spent = widget.routine.spentAt(DateTime.now());
        });
      },
    );
  }

  @override
  dispose() {
    _timer.cancel();
    _listener.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _spent = widget.routine.spentAt(DateTime.now());
      });
    });
  }

  @override
  build(BuildContext context) {
    final goalInSeconds = widget.routine.goal.inSeconds;
    final spentInSeconds = _spent.inSeconds;
    final r = goalInSeconds == 0
        ? 0
        : (100 * _spent.inSeconds / widget.routine.goal.inSeconds).toInt();
    final int ratio;
    final int overtime;
    {
      if (r > 100) {
        overtime = (spentInSeconds / goalInSeconds).toInt();
        ratio = (100 * (goalInSeconds * (overtime)) / spentInSeconds).toInt();
      } else {
        ratio = r;
        overtime = 0;
      }
    }
    return goalInSeconds == 0
        ? drawNotPlannedBar(context)
        : overtime > 0
        ? drawOvertimeBar(context, ratio, overtime)
        : drawProgressBar(context, ratio);
  }

  Widget drawNotPlannedBar(BuildContext context) {
    return SizedBox(
      height: 32,
      width: 4,
      child: FractionallySizedBox(
        heightFactor: .1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(2)),
            color: labelColor(context, Label.routineSignalBar),
          ),
        ),
      ),
    );
  }

  Widget drawOvertimeBar(BuildContext context, int ratio, int overtime) {
    return SizedBox(
      height: 32,
      child: Row(
        spacing: 2,
        children: [
          Column(
            children: [
              Flexible(flex: 100 - ratio, child: Container()),
              Flexible(
                flex: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                    color: labelColor(context, Label.routineSignalBar),
                  ),
                  width: 4,
                ),
              ),
            ],
          ),
          ...List.generate(overtime - 1, (_) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(2)),
                color: labelColor(context, Label.routineSignalBar),
              ),
              width: 4,
            );
          }),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              color: labelColor(context, Label.routineToGoalBar),
            ),
            width: 4,
          ),
        ],
      ),
    );
  }

  Widget drawProgressBar(BuildContext context, int ratio) {
    return SizedBox(
      width: 4,
      height: 32,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: ratio <= 5 ? 0 : 2,
        children: [
          Flexible(
            flex: 100 - ratio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                  bottomLeft: ratio == 0 ? Radius.circular(2) : Radius.zero,
                  bottomRight: ratio == 0 ? Radius.circular(2) : Radius.zero,
                ),
                color: labelColor(context, Label.routineSignalBar),
              ),
            ),
          ),
          Flexible(
            flex: ratio,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
                color: labelColor(context, Label.routineToGoalBar),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
