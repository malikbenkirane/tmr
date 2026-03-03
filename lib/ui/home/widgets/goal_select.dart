import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/home/widgets/goal_wheel.dart';

@immutable
class GoalSelect extends StatefulWidget {
  final Duration initialDuration;
  final int step;
  final void Function() close;
  final void Function(Duration) onCommit;

  GoalSelect({
    super.key,
    required this.close,
    required this.onCommit,
    required this.initialDuration,
    required this.step,
  });

  final _stateKey = GlobalKey<GoalSelectState>();

  void commit() {
    _stateKey.currentState?.commit();
  }

  @override
  GlobalKey<GoalSelectState> get key => _stateKey;

  void cancel() => close();

  @override
  createState() => GoalSelectState();
}

class GoalSelectState extends State<GoalSelect> {
  int hoursIndex = 0, minutesIndex = 1;

  @override
  void initState() {
    final initialIndex = indexDuration(widget.initialDuration, widget.step);
    hoursIndex = initialIndex.$1;
    minutesIndex = initialIndex.$2;
    super.initState();
  }

  void commit() {
    widget.onCommit(
      Duration(minutes: minutesIndex * widget.step, hours: hoursIndex),
    );
    widget.close();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    final double fontSize = 42;
    final numbersTextStyle = TextStyle(
      color: darkMode ? colorScheme.onPrimary : colorScheme.onSurface,
      fontWeight: FontWeight.w400,
      fontSize: fontSize,
    );
    final labelsTextStyle = TextStyle(
      color: darkMode ? colorScheme.onPrimaryFixed : colorScheme.onSurface,
      fontWeight: FontWeight.w500,
      fontSize: fontSize / 4,
    );
    final itemExtent = fontSize * 7 / 6 + 2;
    return SizedBox(
      height: 240,
      child: Column(
        spacing: 20,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // goal_wheel.dart
                GoalWheel(
                  onSelected: (index) {
                    setState(() {
                      hoursIndex = index;
                    });
                  },
                  initialItem: hoursIndex,
                  width: fontSize * .63,
                  itemExtent: itemExtent,
                  delegate: ListWheelChildBuilderDelegate(
                    childCount: 5,
                    builder: (_, index) {
                      return Text('$index', style: numbersTextStyle);
                    },
                  ),
                ),
                Text('h', style: labelsTextStyle),
                GoalWheel(
                  onSelected: (index) {
                    setState(() {
                      minutesIndex = index;
                    });
                  },
                  initialItem: minutesIndex,
                  width: fontSize * 1.42,
                  itemExtent: itemExtent,
                  delegate: ListWheelChildBuilderDelegate(
                    childCount: 2,
                    builder: (_, index) {
                      return Text(
                        (index * 30).toString().padLeft(2, '0'),
                        style: numbersTextStyle,
                      );
                    },
                  ),
                ),
                Text('min', style: labelsTextStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

(int, int) indexDuration(Duration duration, int step) {
  if (duration.inMinutes > 0) {
    final hoursIndex = duration.inHours;
    final minutesIndex = duration.inMinutes.remainder(60) ~/ step;
    return (hoursIndex, minutesIndex);
  }
  return (0, 1); // 0h30m
}
