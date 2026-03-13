import 'package:flutter/foundation.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/home/widgets/result_item.dart';

@immutable
class SearchResult {
  final RoutineSummary? routine;
  final (RoutineSummary, NoteSummary)? note;
  final int score;

  const SearchResult({
    RoutineSummary? routineResult,
    (RoutineSummary, NoteSummary)? noteResult,
    required this.score,
  }) : routine = routineResult,
       note = noteResult;

  ResultItem get item => () {
    assert(routine != null || note != null);
    if (routine == null) return ResultItem.note;
    return ResultItem.routine;
  }();
}
