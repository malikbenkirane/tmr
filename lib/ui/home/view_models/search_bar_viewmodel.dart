import 'package:flutter/foundation.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fz;
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/domain/models/routines/routine_bin.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/ui/home/widgets/search_result.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/result.dart';

class SearchBarViewmodel extends ChangeNotifier {
  final RoutinesRepository routinesRepository;
  SearchBarViewmodel({required this.routinesRepository}) {
    load = Command0(_load)..execute();
    searchRoutine = Command1(_searchRoutine);
  }

  late Command0<void> load;
  late Command1<void, String> searchRoutine;

  List<RoutineSummary> _routines = [];
  Map<RoutineSummary, List<NoteSummary>> _notes = {};

  Future<Result<void>> _load() async {
    try {
      _routines = [];
      _notes = {};
      {
        for (final bin in RoutineBin.values) {
          final result = await routinesRepository.getRoutinesList(bin: bin);
          switch (result) {
            case Error<List<RoutineSummary>>():
              return Result.error(result.error);
            case Ok<List<RoutineSummary>>():
              for (final routine in result.value) {
                _routines.add(routine);
                {
                  final result = await routinesRepository.getNotes(routine.id);
                  switch (result) {
                    case Error<List<NoteSummary>>():
                      return Result.error(result.error);
                    case Ok<List<NoteSummary>>():
                      _notes.putIfAbsent(routine, () => []);
                      _notes[routine] = result.value;
                  }
                }
              }
          }
        }
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  List<SearchResult> _results = [];
  List<SearchResult> get results => _results;

  Future<Result<void>> _searchRoutine(String text) async {
    {
      final result = await _load();
      switch (result) {
        case Error<void>():
          return Result.error(result.error);
        default:
      }
    }
    _results = [];
    try {
      {
        final results = fz.extractTop(
          query: text,
          limit: 3,
          cutoff: 80,
          choices: _routines,
          getter: (routine) => routine.name,
        );
        for (final result in results) {
          _results.add(
            SearchResult(routineResult: result.choice, score: result.score),
          );
        }
        _results.sort();
        for (final result in _results) {
          debugPrint('${result.routine!.name} ${result.routine!.lastStarted}');
        }
      }
      {
        List<(RoutineSummary, NoteSummary)> notes = [];
        _notes.forEach((routine, routineNotes) {
          for (final note in routineNotes) {
            notes.add((routine, note));
          }
        });

        final List<SearchResult> noteSearchResults = [];

        List<(String, RoutineSummary, NoteSummary, int)> choices = [];

        for (final note in notes) {
          for (final word in note.$2.text.split(RegExp(r'\s+'))) {
            choices.add((word, note.$1, note.$2, 0));
          }
        }
        debugPrint('$text: ${choices.length} choices, ${notes.length} notes');

        final expr = text.trim().split(RegExp(r'\s+'));

        for (final text in expr) {
          final results = fz.extractAllSorted(
            query: text,
            cutoff: 80,
            choices: choices,
            getter: (choice) => choice.$1,
          );

          choices = [];
          for (final result in results) {
            for (final word in result.choice.$3.text.split(RegExp(r'\s+'))) {
              final routine = result.choice.$2,
                  note = result.choice.$3,
                  score = result.choice.$4;
              choices.add((word, routine, note, score));
            }
          }
          debugPrint(
            '$text: ${choices.length} choices, ${results.length} results',
          );
        }

        for (final choice in choices) {
          noteSearchResults.add(
            SearchResult.noteResult(
              score: choice.$4,
              note: choice.$3,
              routine: choice.$2,
            ),
          );
        }

        noteSearchResults.sort();
        _results.addAll(noteSearchResults);
      }
      // debugPrint(
      //   '_searchRoutine: text=$text results=${results.length} routines=${_routines.length}',
      // );
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }
}
