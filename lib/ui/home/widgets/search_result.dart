import 'package:flutter/foundation.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/home/widgets/result_item.dart';

@immutable
class SearchResult implements Comparable<SearchResult> {
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

  SearchResult inc(int s) {
    return SearchResult(
      routineResult: routine,
      noteResult: note,
      score: score + s,
    );
  }

  static SearchResult noteResult({
    required int score,
    required NoteSummary note,
    required RoutineSummary routine,
  }) {
    return SearchResult(score: score, noteResult: (routine, note));
  }

  @override
  int compareTo(SearchResult other) {
    switch (kind) {
      case SearchResultKind.routine:
        if (other.routine == null) {
          debugPrint('[WARN] comparing incompatible search results');
          return 0;
        }
        final result = routine!, otherResult = other.routine!;
        final lastStarted = result.lastStarted,
            otherLastStarted = otherResult.lastStarted;
        if (lastStarted == null && otherLastStarted == null) {
          return 0;
        }
        final now = DateTime.now();
        if (lastStarted == null) {
          return otherLastStarted!.compareTo(now);
        }
        if (otherLastStarted == null) {
          return now.compareTo(lastStarted);
        }
        return otherLastStarted.compareTo(lastStarted);

      case SearchResultKind.note:
        return other.score.compareTo(score);
    }
  }

  SearchResultKind get kind =>
      note == null ? SearchResultKind.routine : SearchResultKind.note;
}

enum SearchResultKind { note, routine }

enum SearchResultWord { hyperlink, text }
