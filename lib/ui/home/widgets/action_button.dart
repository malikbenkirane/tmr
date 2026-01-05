import 'package:flutter/material.dart';

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.highlight,
    this.secondary,
  });

  final void Function() onPressed;
  final IconData icon;
  final bool? highlight;
  final bool? secondary;

  @override
  build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: secondary ?? false
          ? theme.colorScheme.secondaryContainer
          : highlight ?? false
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.primary,
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: secondary ?? false
              ? theme.colorScheme.onSecondaryContainer
              : highlight ?? false
              ? theme.colorScheme.primary
              : theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
