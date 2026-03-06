import 'package:flutter/material.dart';
import 'package:too_many_tabs/ui/core/ui/application_action.dart';

class FloatingAction extends StatelessWidget {
  const FloatingAction({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.colorComposition,
  });

  final ColorComposition colorComposition;
  final void Function() onPressed;
  final IconData icon;

  @override
  build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: colorComposition.action.toString(),
      shape: CircleBorder(),
      foregroundColor: colorComposition.foreground,
      backgroundColor: colorComposition.background,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
