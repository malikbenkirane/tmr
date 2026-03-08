import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';

@immutable
class AddNotePopup extends StatefulWidget {
  final void Function() onCancel;
  final void Function(String) onAdd;

  const AddNotePopup({super.key, required this.onCancel, required this.onAdd});

  @override
  State<AddNotePopup> createState() => AddNotePopupState();
}

class AddNotePopupState extends State<AddNotePopup> {
  final textController = TextEditingController();

  // void commitNote() {
  //   final trimmed = textController.text.trim();
  //   if (trimmed.isEmpty) return;
  //   widget.onClose();
  // }

  // void cancelNote() {
  //   widget.onClose();
  // }

  @override
  build(BuildContext context) {
    return Column(
      spacing: 18,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
            fillColor: labelColor(context, Label.dialogInputBackground),
            filled: true,
            hintText: "Type it...",
          ),
          maxLines: 5,
          controller: textController,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onCancel,
                child: const Text('Never mind'),
              ),
            ),
            SizedBox(
              height: 50,
              width: 125.9,
              child: ElevatedButton(
                onPressed: () => widget.onAdd(textController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: labelColor(context, Label.appBarBackground),
                  foregroundColor: labelColor(context, Label.appBarForeground),
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
