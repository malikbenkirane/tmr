import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/archives/view_models/archives_viewmodel.dart';
import 'package:too_many_tabs/ui/archives/widgets/routine.dart';
import 'package:too_many_tabs/ui/core/loader.dart';

class ArchivesScreen extends StatelessWidget {
  const ArchivesScreen({super.key, required this.viewModel});

  final ArchivesViewmodel viewModel;

  @override
  build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkMode
            ? colorScheme.primaryContainer
            : colorScheme.primaryFixed,
        title: Padding(
          padding: EdgeInsets.only(left: 5),
          child: Row(
            children: [
              Text(
                'Archives',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                  color: darkMode
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onPrimaryFixed,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            color: darkMode
                ? colorScheme.onPrimaryContainer
                : colorScheme.onPrimaryFixed,
            onPressed: () {
              context.go(Routes.home);
            },
            icon: Icon(Icons.home),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel.load,
          builder: (context, child) {
            final running = viewModel.load.running,
                error = viewModel.load.error;
            return Loader(
              error: error,
              running: running,
              onError: viewModel.load.execute,
              child: child!,
            );
          },
          child: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              return CustomScrollView(
                slivers: [
                  SliverList.builder(
                    itemCount: viewModel.routines.length,
                    itemBuilder: (_, index) {
                      return Routine(
                        index: index,
                        key: ValueKey(viewModel.routines[index].id),
                        routine: viewModel.routines[index],
                        restore: (context) async {
                          await viewModel.restore.execute(
                            viewModel.routines[index].id,
                          );
                          if (context.mounted) {
                            context.go(Routes.home);
                          }
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
