import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/home/view_models/routine_state.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_progress_bar.dart';
import 'package:too_many_tabs/ui/home/widgets/routine_spent_dynamic_label.dart';

class Routine extends StatelessWidget {
  const Routine({
    super.key,
    required this.routine,
    required this.state,
    required this.archive,
    required this.toggle,
  });

  final RoutineSummary routine;
  final RoutineState state;
  final void Function() archive, toggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dismissibleColors = colorCompositionFromAction(
      context,
      ApplicationAction.toBacklog,
    );
    return Dismissible(
      key: ValueKey(routine.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        archive();
        debugPrint('archive ${routine.id} ${routine.name}');
      },
      background: Container(
        color: dismissibleColors.background,
        child: Padding(
          padding: EdgeInsets.only(left: 25),
          child: Row(
            children: [
              Icon(Icons.archive, color: dismissibleColors.foreground),
            ],
          ),
        ),
      ), // Container
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: routine.running
                    ? BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      )
                    : BoxDecoration(),
              ), // Container
            ),
            InkWell(
              splashColor: colorScheme.primaryContainer,
              onLongPress: toggle,
              onTap: () {
                context.go('${Routes.notes}/${routine.id}');
              },
              child: Padding(
                padding: EdgeInsets.only(
                  top: 2,
                  bottom: 2,
                  left: 15,
                  right: 10,
                ), // EdgeInsets.only
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .5 + 20,
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Container(
                              width: 2,
                              height: 32,
                              decoration: BoxDecoration(
                                // borderRadius: BorderRadius.circular(4),
                                color: routine.running
                                    ? labelColor(context, Label.signalBar)
                                    : labelColor(
                                        context,
                                        Label.noiseBar,
                                      ).withValues(alpha: .2),
                              ), // BoxDecoration
                            ), // Container
                          ), // Padding
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ), // EdgeInsets.symmetric
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      routine.name.trim(),
                                      style: TextStyle(fontSize: 16),
                                      // overflow: TextOverflow.fade,
                                      softWrap: false,
                                    ), // Text
                                  ), // FittedBox
                                  routine.running
                                      ? RoutineSpentDynamicLabel(
                                          restorationId:
                                              'routine_spent_dynamic_label_${routine.id}',
                                          key: ValueKey(routine.id),
                                          spent: routine.spent,
                                          lastStarted: routine.lastStarted!,
                                        ) // RoutineSpentDynamicLabel
                                      : RoutineSpentLabel(
                                          spent: routine.spent,
                                        ), // RoutineSpentLabel
                                ],
                              ), // Column
                            ), // Padding
                          ), // Flexible
                        ],
                      ), // Row
                    ), // SizedBox
                    Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: RoutineProgressBar(
                        routine: routine,
                      ), // RoutineGoalDynamicLabel
                    ), // Padding
                  ],
                ), // Row
              ), // Padding
            ), // InkWell
          ],
        ), // Stack
      ), // Padding
    ); // Dismissible
  }
}
