import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:too_many_tabs/routing/routes.dart';
import 'package:too_many_tabs/ui/core/loader.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';
import 'package:too_many_tabs/ui/home/view_models/search_bar_viewmodel.dart';
import 'package:too_many_tabs/ui/home/widgets/search_result.dart';
import 'package:too_many_tabs/ui/home/widgets/result_item.dart';
import 'package:too_many_tabs/ui/notes/widgets/note_widget.dart';

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
              hide: true,
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
                  children: _results(widget.searchBarViewmodel.results),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _results(List<SearchResult> results) {
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
                children: [...results.map((routine) => _ResultWidget(routine))],
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

@immutable
class _ResultWidget extends StatefulWidget {
  final SearchResult result;

  const _ResultWidget(this.result);

  @override
  createState() => _ResultWidgetState();
}

class _ResultWidgetState extends State<_ResultWidget> {
  GlobalKey _resultNameTextKey = GlobalKey();
  Size? _resultNameTextSize;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _updateResultNameTextSize(),
    );

    SchedulerBinding.instance.addPersistentFrameCallback(
      (_) => _updateResultNameTextSize(),
    );
  }

  void _updateResultNameTextSize() {
    final renderBox =
        _resultNameTextKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    setState(() {
      _resultNameTextSize = renderBox.size;
      _resultNameTextKey = GlobalKey();
    });
  }

  double _barHeight() {
    final double textHeight;
    if (_resultNameTextSize == null) return 0;
    textHeight = _resultNameTextSize!.height;
    final r = textHeight - 16;
    const double minHeight = 24;
    return r < minHeight ? minHeight : r;
  }

  @override
  build(BuildContext context) {
    final Widget resultWidget;
    switch (widget.result.item) {
      case ResultItem.routine:
        resultWidget = Text(
          widget.result.routine!.name,
          key: _resultNameTextKey,
        );
      case ResultItem.note:
        resultWidget = NoteWidget(note: widget.result.note!.$2);
    }
    final Widget chipWidget;
    switch (widget.result.item) {
      case ResultItem.routine:
        chipWidget = Text(
          'routine',
          style: TextStyle(
            color: labelColor(context, Label.searchChipForeground),
            fontSize: 11,
          ),
        );
      case ResultItem.note:
        final routine = widget.result.note!.$1;
        chipWidget = GestureDetector(
          onTap: () {
            context.go('${Routes.notes}/${routine.id}');
          },
          child: Text(routine.name),
        );
    }
    return Material(
      color: labelColor(context, Label.searchResultBackground),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          switch (widget.result.item) {
            case ResultItem.routine:
              context.go('/notes/${widget.result.routine!.id}');
            default:
          }
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
                    Expanded(child: resultWidget),
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
                  child: chipWidget,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
