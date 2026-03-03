import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/home/view_models/goal_update.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/goal_select.dart';

class GoalPopup extends StatefulWidget {
  GoalPopup({
    super.key,
    required this.routineName,
    required this.running,
    required this.viewModel,
    required this.routineID,
    required this.routineGoal,
    required this.close,
  });

  final void Function() close;
  final String routineName;
  final int routineID;
  final Duration routineGoal;
  final bool running;
  final HomeViewmodel viewModel;

  final _stateKey = GlobalKey<GoalPopupState>();

  void commit() {
    _stateKey.currentState?.commit();
  }

  @override
  get key => _stateKey;

  @override
  createState() => GoalPopupState();
}

class GoalPopupState extends State<GoalPopup> {
  void commit() {
    setter.commit();
  }

  late SetGoal setter;

  @override
  void initState() {
    super.initState();
    setter = SetGoal(
      routineName: widget.routineName,
      running: widget.running,
      viewModel: widget.viewModel,
      routineID: widget.routineID,
      routineGoal: widget.routineGoal,
      close: widget.close,
    );
  }

  @override
  Widget build(BuildContext context) {
    return setter;
  }
}

class SetGoal extends StatefulWidget {
  SetGoal({
    super.key,
    required this.routineName,
    required this.running,
    required this.viewModel,
    required this.routineID,
    required this.routineGoal,
    required this.close,
  });

  final String routineName;
  final int routineID;
  final Duration routineGoal;
  final bool running;
  final HomeViewmodel viewModel;
  final void Function() close;

  final _stateKey = GlobalKey<SetGoalState>();

  void commit() => _stateKey.currentState?.commit();

  @override
  get key => _stateKey;

  @override
  createState() => SetGoalState();
}

class SetGoalState extends State<SetGoal> {
  late GoalSelect select;

  void commit() => select.commit();

  @override
  void initState() {
    super.initState();
    select = GoalSelect(
      step: 30,
      initialDuration: widget.routineGoal,
      close: widget.close,
      onCommit: (duration) async {
        await widget.viewModel.updateRoutineGoal.execute(
          GoalUpdate(routineID: widget.routineID, goal: duration),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: darkMode
              ? [
                  colorScheme.primary,
                  colorScheme.primary,
                  colorScheme.primary,
                  colorScheme.primary,
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                ]
              : [
                  colorScheme.surfaceBright,
                  colorScheme.surfaceBright,
                  colorScheme.surfaceBright,
                  colorScheme.surfaceContainerHighest,
                ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          spacing: 17,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [select],
        ),
      ),
    );
  }
}
