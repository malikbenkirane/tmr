import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';
import 'package:too_many_tabs/ui/notes/view_models/note_viewmodel.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';

class NoteScreen extends StatelessWidget {
  final NoteViewmodel viewModel;

  const NoteScreen({super.key, required this.viewModel});

  @override
  build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingAction(
                      onPressed: () => context.go(Routes.home),
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.toHome,
                      ),
                      icon: Icon(Symbols.home),
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
