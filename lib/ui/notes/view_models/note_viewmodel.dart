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
    addComment = Command1(_addComment);
  }

  late Command0<void> load;
  late Command1<void, String> addComment;

  NoteSummary? _note;
  NoteSummary? get note => _note;

  List<NoteSummary> _comments = [];
  List<NoteSummary> get comments => _comments;

  RoutineSummary? _routine;
  RoutineSummary? get routine => _routine;

  Future<Result<void>> _load() async {
    _comments = [];
    try {
      {
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
      }
      {
        final result = await routinesRespository.listNoteComments(
          noteId: noteId,
        );
        switch (result) {
          case Error<List<NoteSummary>>():
            return Result.error(result.error);
          case Ok<List<NoteSummary>>():
            _comments.addAll(result.value);
        }
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }

  Future<Result<void>> _addComment(String note) async {
    try {
      if (_note == null) {
        return Result.error(Exception('null note: _load not completed'));
      }
      final int commentId;
      {
        final result = await routinesRespository.commentNote(
          note: _note!,
          comment: note,
          at: DateTime.now(),
        );
        switch (result) {
          case Error<int>():
            return Result.error(result.error);
          case Ok<int>():
            commentId = result.value;
        }
      }
      final result = await routinesRespository.getNote(commentId);
      switch (result) {
        case Error<NoteSummary>():
          return Result.error(result.error);
        case Ok<NoteSummary>():
          _comments.insert(0, result.value);
      }
      return Result.ok(null);
    } finally {
      notifyListeners();
    }
  }
}
