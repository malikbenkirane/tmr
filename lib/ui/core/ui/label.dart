import 'package:flutter/material.dart';

enum Label {
  homeScreenNumberOfPlannedRoutines,
  homeScreenDayETA,
  homeScreenRoutinesPlannedToday,
  homeScreenGoalTotal,
  homeScreenSpecialGoalTitle,
  homeAppBarBackground,
  homeScreenSettingsWheel,
  appBarForeground,
  appBarBackground,
  dialogInputBackground,
  noiseBar,
  signalBar,
  routineToGoalBar,
  routineSignalBar,
}

Color labelColor(BuildContext context, Label label) {
  final colorScheme = Theme.of(context).colorScheme;
  final darkMode = Theme.of(context).brightness == Brightness.dark;
  switch (label) {
    case Label.dialogInputBackground:
      return colorScheme.surface;
    case Label.homeScreenNumberOfPlannedRoutines:
    case Label.homeScreenRoutinesPlannedToday:
    case Label.homeScreenDayETA:
    case Label.homeScreenSpecialGoalTitle:
    case Label.homeScreenGoalTotal:
    case Label.homeScreenSettingsWheel:
    case Label.appBarForeground:
      return darkMode ? colorScheme.primary : colorScheme.surface;
    case Label.noiseBar:
    case Label.routineSignalBar:
      return darkMode
          ? colorScheme.tertiary.withValues(alpha: .2)
          : colorScheme.tertiary.withValues(alpha: .5);
    case Label.signalBar:
    case Label.routineToGoalBar:
      return darkMode ? colorScheme.secondary : colorScheme.secondary;
    case Label.homeAppBarBackground:
    case Label.appBarBackground:
      return darkMode ? colorScheme.onPrimary : colorScheme.onSurface;
  }
}
