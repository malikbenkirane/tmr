import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/ui/label.dart';

class NewRoutine extends StatefulWidget {
  const NewRoutine({super.key, required this.onAdd, required this.onCancel});

  final void Function(String) onAdd;
  final void Function() onCancel;

  @override
  createState() => _NewRoutineState();
}

class _NewRoutineState extends State<NewRoutine> {
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

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
            hintText: "Name it! 🚀",
          ),
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
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
