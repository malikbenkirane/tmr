import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/ui/notes/widgets/note_widget.dart';

class Note extends StatelessWidget {
  const Note({
    super.key,
    required this.note,
    required this.index,
    required this.count,
    required this.onDismiss,
  });
  final NoteSummary note;
  final int index, count;
  final void Function() onDismiss;
  @override
  build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = 10 ^ (math.log(count) / math.ln10).ceil();
    final uid = base + note.id!;
    // debugPrint(
    //   'note ${note.id} dismissed=${note.dismissed} idx=$index uid=$uid',
    // );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        note.dismissed
            ? _PaddedNote(note: note, top: index == 0)
            : Dismissible(
                key: ValueKey(uid),
                direction: DismissDirection.endToStart,
                background: Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [Icon(Icons.layers_clear)],
                  ),
                ),
                onDismissed: (_) async {
                  onDismiss();
                },
                child: Row(
                  children: [
                    Expanded(
                      child: _PaddedNote(note: note, top: index == 0),
                    ),
                  ],
                ),
              ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: index + 1 == count
              ? SizedBox.shrink()
              : Container(color: cs.primary, height: .2),
        ),
      ],
    );
  }
}

@immutable
class _PaddedNote extends StatelessWidget {
  final bool top;
  final NoteSummary note;
  const _PaddedNote({required this.top, required this.note});

  @override
  build(BuildContext context) {
    return Padding(
      padding: top
          ? EdgeInsets.only(top: 20, bottom: 5, left: 30, right: 30)
          : EdgeInsets.symmetric(vertical: 5, horizontal: 30),
      child: NoteWidget(note: note),
    );
  }
}
