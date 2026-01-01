import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/result.dart';

class NotesViewmodel extends ChangeNotifier {
  NotesViewmodel({required RoutinesRepository repo, int? routineId})
    : _repo = repo,
      _routineId = routineId {
    load = Command0(_load)..execute();
    addNote = Command1(_addNote);
  }

  final RoutinesRepository _repo;
  final int? _routineId;
  final _log = Logger('NotesViewmodel');

  late Command0 load;
  late Command1<void, NoteSummary> addNote;

  RoutineSummary? _routine;
  List<NoteSummary> _notes = [];

  RoutineSummary? get routine => _routine;
  List<NoteSummary> get notes => _notes;

  Future<Result> _load() async {
    try {
      if (_routineId == null) {
        return Result.ok(null);
      }
      final resultRoutineSummary = await _repo.getRoutineSummary(_routineId);
      switch (resultRoutineSummary) {
        case Error<RoutineSummary>():
          _log.warning(
            '_load: getRoutineSummary: ${resultRoutineSummary.error}',
          );
          return Result.error(resultRoutineSummary.error);
        case Ok<RoutineSummary>():
          _routine = resultRoutineSummary.value;
          _log.fine('_load: getRoutineSummary: $_routine');
      }
      final resultNotes = await _repo.getNotes(_routineId);
      switch (resultNotes) {
        case Error<List<NoteSummary>>():
          _log.warning('_load: getNotes: ${resultNotes.error}');
          return Result.error(resultNotes.error);
        case Ok<List<NoteSummary>>():
          _log.fine(
            '_load: getNotes: ${resultNotes.value.length} notes loaded',
          );
          _notes = resultNotes.value;
      }
      return resultRoutineSummary;
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _addNote(NoteSummary note) async {
    try {
      final result = await _repo.addNote(
        note: note.text,
        createdAt: note.createdAt,
        routineId: note.routineId,
      );
      switch (result) {
        case Ok<void>():
          _log.fine('_addNote: $note');
        case Error<void>():
          _log.warning('_addNote $note: ${result.error}');
      }
      return result;
    } finally {
      notifyListeners();
    }
  }
}
