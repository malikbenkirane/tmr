import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/home/view_models/search_bar_viewmodel.dart';

@immutable
class SearchBarWidget extends StatefulWidget {
  final SearchBarViewmodel searchBarViewmodel;

  const SearchBarWidget({super.key, required this.searchBarViewmodel});

  @override
  State<StatefulWidget> createState() => _SearchBarText();
}

class _SearchBarText extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 9,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  fillColor: labelColor(context, Label.searchBarBackground),
                  filled: true,
                  hintText: 'Search...',
                  prefixIcon: Icon(Symbols.manage_search_sharp),
                ),
                onChanged: (text) {
                  widget.searchBarViewmodel.searchRoutine.execute(text);
                  setState(() {});
                },
                controller: _controller,
              ),
            ),
          ],
        ),
        ListenableBuilder(
          listenable: widget.searchBarViewmodel.load,
          builder: (context, child) {
            return Loader(
              error: widget.searchBarViewmodel.load.error,
              running: widget.searchBarViewmodel.load.running,
              onError: widget.searchBarViewmodel.load.execute,
              child: child!,
            );
          },
          child: ListenableBuilder(
            listenable: widget.searchBarViewmodel,
            builder: (context, _) {
              return Animate(
                effects: [FadeEffect()],
                child: Row(
                  children: _results(widget.searchBarViewmodel.routines),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _results(List<RoutineSummary> results) {
    if (_controller.text.isEmpty || results.isEmpty) {
      return [];
    }
    return [
      Expanded(
        child: Animate(
          effects: [
            FadeEffect(),
            ScaleEffect(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 200),
            ),
          ],
          child: Material(
            elevation: 1,
            color: labelColor(context, Label.searchPopupBackground),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                spacing: 6,
                children: [
                  ...results.map((routine) => _RoutineResultWidget(routine)),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

@immutable
class _RoutineResultWidget extends StatefulWidget {
  final RoutineSummary routine;

  const _RoutineResultWidget(this.routine);

  @override
  createState() => _RoutineResultWidgetState();
}

class _RoutineResultWidgetState extends State<_RoutineResultWidget> {
  GlobalKey _routineNameTextKey = GlobalKey();
  Size? _routineNameTextSize;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _updateRoutineNameTextSize(),
    );

    SchedulerBinding.instance.addPersistentFrameCallback(
      (_) => _updateRoutineNameTextSize(),
    );
  }

  void _updateRoutineNameTextSize() {
    final renderBox =
        _routineNameTextKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    setState(() {
      _routineNameTextSize = renderBox.size;
      _routineNameTextKey = GlobalKey();
    });
  }

  double _barHeight() {
    final double textHeight;
    if (_routineNameTextSize == null) return 0;
    textHeight = _routineNameTextSize!.height;
    final r = textHeight - 16;
    const double minHeight = 24;
    return r < minHeight ? minHeight : r;
  }

  @override
  build(BuildContext context) {
    return Material(
      color: labelColor(context, Label.searchResultBackground),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          context.go('/notes/${widget.routine.id}');
        },
        child: Padding(
          padding: EdgeInsets.only(left: 18, right: 10, top: 10, bottom: 13),
          child: Row(
            spacing: 20,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Row(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 2,
                      height: _barHeight(),
                      color: labelColor(
                        context,
                        Label.verticalRoutineBar,
                      ).withValues(alpha: .9),
                    ),
                    Expanded(
                      child: Text(
                        widget.routine.name,
                        key: _routineNameTextKey,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                elevation: 1,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: Text(
                    'routine',
                    style: TextStyle(
                      color: labelColor(context, Label.searchChipForeground),
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
