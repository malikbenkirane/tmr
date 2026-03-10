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
          limit: 4,
          cutoff: 50,
          choices: _routines,
          getter: (routine) => routine.name,
        );
        for (final result in results) {
          _results.add(SearchResult(routineResult: result.choice));
        }
      }
      {
        final List<(RoutineSummary, NoteSummary)> notes = [];
        _notes.forEach((routine, routineNotes) {
          for (final note in routineNotes) {
            notes.add((routine, note));
          }
        });
        final results = fz.extractAllSorted(
          query: text,
          cutoff: 10,
          choices: notes,
          getter: (n) => n.$2.text,
        );
        for (final result in results) {
          _results.add(SearchResult(noteResult: result.choice));
        }
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
