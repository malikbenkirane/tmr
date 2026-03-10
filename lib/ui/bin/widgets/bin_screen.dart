import 'dart:io' show Platform;
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/bin/widgets/routine.dart';
import 'package:too_many_tabs/ui/bin/view_models/bin_viewmodel.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/floating_action.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';

class BinScreen extends StatefulWidget {
  const BinScreen({super.key, required this.viewModel});

  final BinViewmodel viewModel;

  @override
  createState() => _ArchivesScreenState();
}

class _ArchivesScreenState extends State<BinScreen> {
  late final AppLifecycleListener _listener;
  final _controller = ScrollController();

  @override
  void initState() {
    _listener = AppLifecycleListener(
      onResume: () async {
        await widget.viewModel.load.execute();
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _listener.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: widget.viewModel.load,
              builder: (context, child) {
                final running = widget.viewModel.load.running,
                    error = widget.viewModel.load.error;
                return Loader(
                  error: error,
                  running: running,
                  onError: widget.viewModel.load.execute,
                  child: child!,
                );
              },
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) {
                  return FadingEdgeScrollView.fromScrollView(
                    gradientFractionOnEnd: 0.8,
                    gradientFractionOnStart: 0,
                    child: CustomScrollView(
                      controller: _controller,
                      slivers: [
                        SliverSafeArea(
                          minimum: EdgeInsets.only(bottom: 120),
                          sliver: SliverList.builder(
                            itemCount: widget.viewModel.routines.length,
                            itemBuilder: (_, index) {
                              return Routine(
                                index: index,
                                key: ValueKey(
                                  widget.viewModel.routines[index].id,
                                ),
                                routine: widget.viewModel.routines[index],
                                restore: () async {
                                  await widget.viewModel.restore.execute(
                                    widget.viewModel.routines[index].id,
                                  );
                                  await widget.viewModel.load.execute();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: Platform.isIOS || Platform.isAndroid ? 0 : 20,
                horizontal: 30,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FloatingAction(
                      onPressed: () => context.go(Routes.archives),
                      icon: Icon(Icons.menu),
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.backlogRoutine,
                      ),
                    ),
                    FloatingAction(
                      onPressed: () => context.go(Routes.home),
                      icon: Icon(Icons.home),
                      colorComposition: colorCompositionFromAction(
                        context,
                        ApplicationAction.toHome,
                      ),
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
