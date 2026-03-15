import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/home/widgets/add_note_popup.dart';
import 'package:too_many_tabs/ui/notes/view_models/note_viewmodel.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/notes/widgets/note_widget.dart';

class NoteScreen extends StatelessWidget {
  final NoteViewmodel noteViewmodel;

  const NoteScreen({super.key, required this.noteViewmodel});

  Widget _notes(BuildContext context, NoteSummary note) {
    return Column(
      spacing: 13,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 13),
                  child: NoteWidget(note: note),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 26),
            child: ListView.separated(
              itemCount: noteViewmodel.comments.length,
              separatorBuilder: (context, _) {
                return Row(
                  children: [
                    SizedBox(
                      width: 116,
                      height: 1,
                      child: Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                      ),
                    ),
                  ],
                );
              },
              itemBuilder: (context, index) {
                final note = noteViewmodel.comments[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          child: InkWell(
                            onTap: () {
                              context.push('${Routes.note}/${note.id}');
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 9,
                                horizontal: 14,
                              ),
                              child: NoteWidget(note: note),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(40),
              child: ListenableBuilder(
                listenable: noteViewmodel.load,
                builder: (context, child) {
                  return Loader(
                    error: noteViewmodel.load.error,
                    running: noteViewmodel.load.running,
                    onError: noteViewmodel.load.execute,
                    child: child!,
                  );
                },
                child: ListenableBuilder(
                  listenable: noteViewmodel,
                  builder: (context, _) {
                    final note = noteViewmodel.note;
                    if (note == null) return SizedBox.shrink();
                    return noteViewmodel.parentNote == null
                        ? _notes(context, note)
                        : Column(
                            spacing: 20,
                            children: [
                              _ParentWidget(note: noteViewmodel.parentNote!),
                              Expanded(child: _notes(context, note)),
                            ],
                          );
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Platform.isIOS || Platform.isAndroid ? 0 : 20,
                  horizontal: 30,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingAction(
                      onPressed: () => _notePopup(context),
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.addNote,
                      ),
                      icon: Icon(Symbols.add),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Material(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadiusGeometry.circular(18),
                          elevation: 1,
                          child: InkWell(
                            onTap: () {
                              final note = noteViewmodel.note;
                              if (note == null) return;
                              context.push('${Routes.notes}/${note.routineId}');
                            },
                            child: ListenableBuilder(
                              listenable: noteViewmodel,
                              builder: (context, _) {
                                final routine = noteViewmodel.routine;
                                final note = noteViewmodel.note;
                                if (routine == null || note == null) {
                                  return SizedBox.shrink();
                                }
                                return SizedBox(
                                  height: 41,
                                  child: Center(child: Text(routine.name)),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    FloatingAction(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.navPop,
                      ),
                      icon: Icon(Symbols.arrow_back),
                    ),
                    FloatingAction(
                      onPressed: () => context.push(Routes.home),
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.toHome,
                      ),
                      icon: Icon(Icons.home),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _notePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: AddNotePopup(
                onCancel: () {
                  Navigator.pop(context);
                },
                onAdd: (note) {
                  noteViewmodel.addComment.execute(note);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ParentWidget extends StatefulWidget {
  final NoteSummary note;

  const _ParentWidget({required this.note});

  @override
  State<StatefulWidget> createState() => _ParentWidgetState();
}

class _ParentWidgetState extends State<_ParentWidget> {
  GlobalKey _rowKey = GlobalKey();
  Size? _rowSize;

  void _updateRowSize() {
    final renderBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    setState(() {
      _rowSize = renderBox.size;
      _rowKey = GlobalKey();
    });
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _updateRowSize());
  }

  @override
  build(BuildContext context) {
    final sideVerticalBar = _sideVerticalBarWidget();
    return Row(
      key: _rowKey,
      spacing: 2,
      children: [
        sideVerticalBar,
        Expanded(
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(5),
            child: InkWell(
              borderRadius: BorderRadius.circular(5),
              onTap: () {
                context.push('${Routes.note}/${widget.note.id}');
              },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 13),
                child: NoteWidget(note: widget.note),
              ),
            ),
          ),
          // child: Container(
          //   decoration: BoxDecoration(
          //     borderRadius: BorderRadius.circular(5),
          //     color: Theme.of(context).colorScheme.surfaceContainer,
          //   ),
          // ),
        ),
        sideVerticalBar,
      ],
    );
  }

  Widget _sideVerticalBarWidget() {
    final size = _rowSize;
    if (size == null) {
      return SizedBox.shrink();
    }
    final height = size.height < 4 ? 0.0 : size.height - 4;
    return SizedBox(
      height: height,
      width: 7,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
