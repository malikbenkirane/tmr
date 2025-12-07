import 'dart:async';

import 'package:flutter/material.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

class RoutineSpentDynamicLabel extends StatefulWidget {
  const RoutineSpentDynamicLabel({
    super.key,
    required this.spent,
    required this.lastStarted,
    required this.restorationId,
  });

  final Duration spent;
  final DateTime lastStarted;
  final String? restorationId;

  @override
  RoutineSpentDynamicLabelState createState() =>
      RoutineSpentDynamicLabelState();
}

class RoutineSpentDynamicLabelState extends State<RoutineSpentDynamicLabel>
    with RestorationMixin {
  late Timer _timer;

  final _spentMilliseconds = RestorableInt(0);

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_spentMilliseconds, 'spent_milliseconds_value');
  }

  @override
  initState() {
    super.initState();
    _startTimer();
  }

  @override
  dispose() {
    _timer.cancel();
    _spentMilliseconds.dispose();
    super.dispose();
  }

  static const _refreshPeriod = Duration(milliseconds: 20);

  void _startTimer() {
    _timer = Timer.periodic(_refreshPeriod, (timer) {
      setState(() {
        _spentMilliseconds.value =
            widget.spent.inMilliseconds +
            DateTime.now().difference(widget.lastStarted).inMilliseconds;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoutineSpentLabel(
      spent: Duration(milliseconds: _spentMilliseconds.value),
    );
  }
}

class RoutineSpentLabel extends StatelessWidget {
  const RoutineSpentLabel({super.key, required this.spent});
  final Duration spent;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatSpentDuration(spent),
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 11.4,
        fontFamily: 'Mono',
      ),
    );
  }
}
