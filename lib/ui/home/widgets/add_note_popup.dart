import 'package:flutter/material.dart';
import 'package:too_many_tabs/domain/models/notes/note_summary.dart';
import 'package:too_many_tabs/ui/notes/view_models/notes_viewmodel.dart';

class AddNotePopup extends StatefulWidget {
  const AddNotePopup({
    super.key,
    required this.onClose,
    required this.viewModel,
    required this.routineId,
  });

  final void Function() onClose;
  final NotesViewmodel viewModel;
  final int routineId;

  @override
  createState() => _AddNotePopupState();
}

class _AddNotePopupState extends State<AddNotePopup> {
  final noteTextController = TextEditingController();

  @override
  build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: darkMode ? colors.surface : colors.surfaceContainer,
        ),
        child: Column(
          spacing: 20,
          children: [
            Text('Add Note', style: TextStyle(color: colors.primary)),
            TextField(
              controller: noteTextController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: widget.onClose,
                  child: const Text('Never mind'),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.viewModel.addNote.execute(
                      NoteSummary(
                        note: noteTextController.text,
                        createdAt: DateTime.now(),
                        routineId: widget.routineId,
                      ),
                    );
                    widget.onClose();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
