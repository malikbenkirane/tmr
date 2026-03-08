import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/home/view_models/home_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/add_note_popup.dart';
import 'package:too_many_tabs/ui/home/widgets/goal_popup.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';
import 'package:too_many_tabs/ui/notes/view_models/pomodoro_payload.dart';
import 'package:too_many_tabs/ui/notes/widgets/note.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:clipboard/clipboard.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:duration/duration.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.notesViewmodel,
    required this.homeViewmodel,
    required this.pomodoroPayload,
  });

  final NotesViewmodel notesViewmodel;
  final HomeViewmodel homeViewmodel;
  final PomodoroPayload? pomodoroPayload;

  @override
  createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool showActionButtons = true;

  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget _goalLabel({
    required Duration routineGoal,
    required Duration dayGoal,
  }) {
    final foreground = labelColor(context, Label.appBarForeground);
    final Text routineGoalText;
    if (routineGoal == Duration.zero) {
      routineGoalText = Text(
        'set goal',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: foreground,
        ),
      );
    } else {
      routineGoalText = Text(
        routineGoal.pretty(abbreviated: true, tersity: DurationTersity.minute),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: foreground,
        ),
      );
    }
    final Text dayGoalText;
    if (dayGoal == Duration.zero) {
      dayGoalText = Text(
        '/ no goal',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w300,
          color: foreground,
        ),
      );
    } else {
      dayGoalText = Text(
        '/ ${dayGoal.pretty(abbreviated: true, tersity: DurationTersity.minute)}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w300,
          color: foreground,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [routineGoalText, dayGoalText],
    );
  }

  Widget _goalSection(RoutineSummary routine) {
    final foreground = labelColor(context, Label.appBarForeground);
    return GestureDetector(
      child: ListenableBuilder(
        listenable: widget.homeViewmodel,
        builder: (context, _) {
          final routineUpdate = _getRoutine(routine.id);
          var dayGoal = Duration.zero;
          for (final routine in widget.homeViewmodel.routines) {
            dayGoal += routine.$1.goal;
          }
          if (routineUpdate == null) {
            return SizedBox.shrink();
          }
          final goal = routineUpdate.goal;
          if (goal == Duration.zero) {
            return Row(
              children: [
                Stack(
                  alignment: AlignmentGeometry.center,
                  children: [
                    Icon(
                      Symbols.trophy,
                      size: 30,
                      color: foreground.withValues(alpha: .4),
                    ),
                    Icon(
                      Symbols.close,
                      size: 50,
                      weight: .2,
                      color: foreground,
                    ),
                  ],
                ),
                _goalLabel(dayGoal: dayGoal, routineGoal: goal),
              ],
            );
          }
          return Row(
            spacing: 2,
            children: [
              _goalLabel(dayGoal: dayGoal, routineGoal: goal),
              Icon(Symbols.trophy, size: 30, color: foreground),
            ],
          );
        },
      ),
      onTap: () {
        _goalPopup();
      },
    );
  }

  Widget _sessionSection(RoutineSummary routine) {
    return ListenableBuilder(
      listenable: widget.homeViewmodel,
      builder: (context, _) {
        final r = widget.notesViewmodel.routine;
        if (r == null) return SizedBox.shrink();
        final u = _getRoutine(r.id);
        if (u == null) return SizedBox.shrink();
        if (!u.running) {
          return Text(
            'total spent: ${routine.spent.pretty(tersity: DurationTersity.minute, abbreviated: true)}',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: labelColor(context, Label.appBarForeground),
              fontSize: 12,
            ),
          );
        }
        final start = u.lastStarted;
        if (start == null) return SizedBox.shrink();
        timeago.setLocaleMessages('en', _MyCustomMessages());
        return Text(
          'started ${timeago.format(start)}',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 12,
            color: labelColor(context, Label.appBarForeground),
          ),
        );
      },
    );
  }

  @override
  build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notesViewmodel.load,
      builder: (context, child) {
        final running = widget.notesViewmodel.load.running,
            error = widget.notesViewmodel.load.error;
        return Loader(
          running: running,
          error: error,
          onError: widget.notesViewmodel.load.execute,
          child: child!,
        );
      },
      child: ListenableBuilder(
        listenable: widget.notesViewmodel,
        builder: (context, child) {
          final count = widget.notesViewmodel.notes.length;
          final routine = widget.notesViewmodel.routine;
          final foreground = labelColor(context, Label.appBarForeground);
          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: labelColor(context, Label.appBarBackground),
              title: routine == null
                  ? SizedBox.shrink()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(child: _sessionSection(routine)),
                        Expanded(
                          child: Text(
                            routine.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: foreground),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [_goalSection(routine)],
                          ),
                        ),
                      ],
                    ),
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .8, 1],
                        colors: [
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ScrollablePositionedList.builder(
                      itemCount: count,
                      padding: EdgeInsets.only(bottom: 140),
                      itemBuilder: (_, index) {
                        final note = widget.notesViewmodel.notes[index];
                        return InkWell(
                          onTap: (Platform.isIOS || Platform.isAndroid)
                              ? null
                              : () async {
                                  await FlutterClipboard.copy(note.text);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        spacing: 2,
                                        children: [
                                          Icon(Symbols.assignment),
                                          const Text(
                                            'Your note’s now on the clipboard',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                          child: Note(
                            count: count,
                            index: index,
                            note: note,
                            onDismiss: () {
                              widget.notesViewmodel.dismissNote.execute(
                                note.id!,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [..._actionButtons(context)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  RoutineSummary? _getRoutine(int id) {
    final routineId = id;
    RoutineSummary? routineUpdate;
    for (final routineCandidate in widget.homeViewmodel.routines) {
      if (routineCandidate.$1.id == routineId) {
        routineUpdate = routineCandidate.$1;
        break;
      }
    }
    return routineUpdate;
  }

  Widget _etaWidget() {
    return ListenableBuilder(
      listenable: widget.notesViewmodel,
      builder: (context, _) {
        final eta = widget.notesViewmodel.eta;
        if (eta == null) {
          return SizedBox.shrink();
        }
        if (eta.isBefore(DateTime.now())) {
          return SizedBox.shrink();
        }
        return GestureDetector(
          onTap: () {
            final ref = widget.notesViewmodel.etaRef;
            if (ref == null) return;
            context.push('/notes/${ref.id}');
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Icon(Symbols.keyboard_double_arrow_right),
              Text(DateFormat.jm().format(eta)),
            ],
          ),
        );
      },
    );
  }

  void _startOrStopRoutine() async {
    final routine = widget.notesViewmodel.routine;
    if (routine == null) return;
    await widget.homeViewmodel.startOrStopRoutine.execute(routine.id);
    await widget.notesViewmodel.updatePomoEta.execute(DateTime.now());
  }

  List<Widget> _actionButtons(BuildContext context) {
    return showActionButtons
        ? [
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  FloatingAction(
                    onPressed: _notePopup,
                    icon: Icon(Icons.add),
                    colorComposition: colorCompositionFromAction(
                      context,
                      ApplicationAction.addNote,
                    ),
                  ),
                  ListenableBuilder(
                    listenable: widget.homeViewmodel,
                    builder: (context, _) {
                      final RoutineSummary routine;
                      {
                        final r = widget.notesViewmodel.routine;
                        if (r == null) {
                          return SizedBox.shrink();
                        }
                        final u = _getRoutine(r.id);
                        if (u == null) {
                          return SizedBox.shrink();
                        }
                        routine = u;
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingAction(
                            onPressed: _startOrStopRoutine,
                            icon: Icon(
                              routine.running
                                  ? Symbols.pause
                                  : Symbols.play_arrow,
                              fill: 1,
                            ),
                            colorComposition: colorCompositionFromAction(
                              context,
                              routine.running
                                  ? ApplicationAction.stopRoutine
                                  : ApplicationAction.startRoutine,
                            ),
                          ),
                          _etaWidget(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: FloatingAction(
                onPressed: () => context.go(Routes.home),
                icon: Icon(Icons.home),
                colorComposition: colorCompositionFromAction(
                  context,
                  ApplicationAction.toHome,
                ),
              ),
            ),
          ]
        : [];
  }

  void _toggleActionButtons() {
    setState(() {
      showActionButtons = !showActionButtons;
    });
  }

  void _goalPopup() async {
    final routine = widget.notesViewmodel.routine!;
    final popup = GoalPopup(
      routineName: routine.name,
      running: routine.running,
      viewModel: widget.homeViewmodel,
      routineID: routine.id,
      routineGoal: routine.goal,
      close: () {},
    );
    _toggleActionButtons();
    final colors = colorCompositionFromAction(
      context,
      ApplicationAction.setGoal,
    );
    await showDialog(
      fullscreenDialog: true,
      context: context,
      builder: (context) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Scaffold(
            appBar: AppBar(title: const Text("Set daily goal")),
            backgroundColor: Colors.black.withValues(alpha: 0),
            body: Stack(
              children: [
                popup,
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Material(
                      borderRadius: BorderRadius.circular(100),
                      color: colors.background,
                      elevation: 4,
                      child: InkWell(
                        onTap: () {
                          popup.commit();
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'Update',
                            style: TextStyle(
                              color: colors.foreground,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    _toggleActionButtons();
  }

  void _notePopup() {
    _toggleActionButtons();
    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 20,
                children: [
                  AddNotePopup(
                    onCancel: () {
                      Navigator.pop(context);
                      setState(() => showActionButtons = true);
                    },
                    onAdd: (note) async {
                      final routine = widget.notesViewmodel.routine;
                      if (routine == null) return;
                      await widget.notesViewmodel.addNote.execute(
                        NoteSummary(
                          note: note,
                          createdAt: DateTime.now(),
                          routineId: routine.id,
                          dismissed: false,
                        ),
                      );
                      await widget.notesViewmodel.load.execute();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      setState(() => showActionButtons = true);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MyCustomMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';
  @override
  String prefixFromNow() => '';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'now';
  @override
  String aboutAMinute(int minutes) => '${minutes}m ago';
  @override
  String minutes(int minutes) => '${minutes}m ago';
  @override
  String aboutAnHour(int minutes) => '${minutes}m ago';
  @override
  String hours(int hours) => '${hours}h ago';
  @override
  String aDay(int hours) => '${hours}h ago';
  @override
  String days(int days) => '${days}d ago';
  @override
  String aboutAMonth(int days) => '${days}d ago';
  @override
  String months(int months) => '${months}mo ago';
  @override
  String aboutAYear(int year) => '${year}y ago';
  @override
  String years(int years) => '${years}y ago';
  @override
  String wordSeparator() => ' ';
}
