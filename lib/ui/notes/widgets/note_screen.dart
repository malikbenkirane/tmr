import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/notes/view_models/note_viewmodel.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/notes/widgets/note_widget.dart';

class NoteScreen extends StatelessWidget {
  final NoteViewmodel viewModel;

  const NoteScreen({super.key, required this.viewModel});

  @override
  build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(40),
              child: ListenableBuilder(
                listenable: viewModel.load,
                builder: (context, child) {
                  return Loader(
                    error: viewModel.load.error,
                    running: viewModel.load.running,
                    onError: viewModel.load.execute,
                    child: child!,
                  );
                },
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) {
                    final note = viewModel.note;
                    if (note == null) return SizedBox.shrink();
                    return (NoteWidget(note: note));
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final note = viewModel.note;
                          if (note == null) return;
                        },
                        child: ListenableBuilder(
                          listenable: viewModel,
                          builder: (context, _) {
                            final routine = viewModel.routine;
                            final note = viewModel.note;
                            if (routine == null || note == null) {
                              return SizedBox.shrink();
                            }
                            return Text(routine.name);
                          },
                              context.push('${Routes.notes}/${note.routineId}');
                        ),
                      ),
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
}
