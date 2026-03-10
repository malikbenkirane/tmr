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
import 'package:timeago/timeago.dart' as timeago;

@immutable
class SearchBarWidget extends StatefulWidget {
  final SearchBarViewmodel searchBarViewmodel;
  final Function(String) onQueryChange;

  const SearchBarWidget({
    super.key,
    required this.searchBarViewmodel,
    required this.onQueryChange,
  });

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
                  widget.onQueryChange(text);
                  setState(() {});
                },
                controller: _controller,
              ),
            ),
          ],
        ),
        Expanded(
          child: ListenableBuilder(
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
              child: SingleChildScrollView(
                child: Column(
                  spacing: 6,
                  children: [
                    ...results.map((routine) => _ResultWidget(routine)),
                  ],
                ),
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
  GlobalKey _resultWidgetKey = GlobalKey();
  Size? _resultWidgetSize;

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
        _resultWidgetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    setState(() {
      _resultWidgetSize = renderBox.size;
      _resultWidgetKey = GlobalKey();
    });
  }

  double _barHeight() {
    final double textHeight;
    if (_resultWidgetSize == null) return 0;
    textHeight = _resultWidgetSize!.height;
    final r = textHeight - 16;
    const double minHeight = 24;
    return r < minHeight ? minHeight : r;
  }

  @override
  build(BuildContext context) {
    final chipTextStyle = TextStyle(
      color: labelColor(context, Label.searchChipForeground),
      fontSize: 11,
    );
    final Color barColor;
    final Widget resultWidget, chipWidget;

    switch (widget.result.item) {
      case ResultItem.routine:
        final routine = widget.result.routine!;
        resultWidget = Text(routine.name, key: _resultWidgetKey);
        final String chipText;
        {
          var label = "pending";
          if (routine.lastStarted != null) {
            label = timeago.format(routine.lastStarted!, locale: 'en_short');
            label = '$label ago';
          }
          chipText = label;
        }
        chipWidget = Text(chipText, style: chipTextStyle);
        barColor = labelColor(
          context,
          Label.verticalRoutineBar,
        ).withValues(alpha: .9);
      case ResultItem.note:
        resultWidget = NoteWidget(
          key: _resultWidgetKey,
          note: widget.result.note!.$2,
        );
        final routine = widget.result.note!.$1;
        chipWidget = GestureDetector(
          onTap: () {
            context.go('${Routes.notes}/${routine.id}');
          },
          child: Text(routine.name, style: chipTextStyle),
        );
        barColor = labelColor(
          context,
          Label.verticalRoutineBar,
        ).withValues(alpha: .1);
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
                    Container(width: 2, height: _barHeight(), color: barColor),
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
