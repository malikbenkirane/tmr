import 'package:flutter/material.dart';
import 'package:too_many_tabs/data/repositories/routines/routines_repository.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/domain/models/routines/routine_summary.dart';
import 'package:too_many_tabs/utils/command.dart';
import 'package:too_many_tabs/utils/result.dart';

class NoteViewmodel extends ChangeNotifier {
  final RoutinesRepository routinesRespository;
  final int noteId;

  NoteViewmodel({required this.routinesRespository, required this.noteId}) {
    load = Command0(_load)..execute();
  }

  late Command0<void> load;

  NoteSummary? _note;
  NoteSummary? get note => _note;

  RoutineSummary? _routine;
  RoutineSummary? get routine => _routine;

  Future<Result<void>> _load() async {
    try {
      final result = await routinesRespository.getNote(noteId);
      switch (result) {
        case Error<NoteSummary>():
          return Result.error(result.error);
        case Ok<NoteSummary>():
          _note = result.value;
          {
            final result = await routinesRespository.getRoutineSummary(
              _note!.routineId,
            );
            switch (result) {
              case Error<RoutineSummary>():
                return Result.error(result.error);
              case Ok<RoutineSummary>():
                _routine = result.value;
            }
          }
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }
}
