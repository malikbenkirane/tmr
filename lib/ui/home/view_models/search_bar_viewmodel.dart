import 'package:flutter/foundation.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fz;
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/domain/models/routines/routine_bin.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
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

  Future<Result<void>> _load() async {
    try {
      _routines = [];
      {
        for (final bin in RoutineBin.values) {
          final result = await routinesRepository.getRoutinesList(bin);
          switch (result) {
            case Error<List<RoutineSummary>>():
              return Result.error(result.error);
            case Ok<List<RoutineSummary>>():
              for (final routine in result.value) {
                _routines.add(routine);
              }
          }
        }
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  List<RoutineSummary> _routineResults = [];
  List<RoutineSummary> get routines => _routineResults;

  Future<Result<void>> _searchRoutine(String text) async {
    {
      final result = await _load();
      switch (result) {
        case Error<void>():
          return Result.error(result.error);
        default:
      }
    }
    _routineResults = [];
    try {
      final results = fz.extractTop(
        query: text,
        limit: 5,
        cutoff: 50,
        choices: _routines,
        getter: (routine) => routine.name,
      );
      for (final result in results) {
        _routineResults.add(result.choice);
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
