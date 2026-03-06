import 'package:flutter/material.dart';

(Color, Color) alternateColors(BuildContext context, int index) {
  final colorScheme = Theme.of(context).colorScheme;
  final background = index % 2 == 1
      ? colorScheme.surfaceContainerLowest
      : colorScheme.surface;
  final foreground = colorScheme.onSurface;
  return (foreground, background);
}
