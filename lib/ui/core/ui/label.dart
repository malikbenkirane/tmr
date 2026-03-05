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
  noiseBar,
  signalBar,
  routineToGoalBar,
  routineSignalBar,
}

Color labelColor(BuildContext context, Label label) {
  final colorScheme = Theme.of(context).colorScheme;
  final darkMode = Theme.of(context).brightness == Brightness.dark;
  switch (label) {
    case Label.homeScreenNumberOfPlannedRoutines:
    case Label.homeScreenRoutinesPlannedToday:
    case Label.homeScreenDayETA:
    case Label.homeScreenSpecialGoalTitle:
    case Label.homeScreenGoalTotal:
    case Label.homeScreenSettingsWheel:
    case Label.appBarForeground:
    case Label.signalBar:
      return darkMode ? colorScheme.primary : colorScheme.surface;
    case Label.routineSignalBar:
      return colorScheme.tertiary.withValues(alpha: .5);
    case Label.noiseBar:
    case Label.routineToGoalBar:
      return darkMode
          ? colorScheme.secondary.withValues(alpha: .6)
          : colorScheme.secondary;
    case Label.homeAppBarBackground:
    case Label.appBarBackground:
      return darkMode ? colorScheme.onPrimary : colorScheme.onSurface;
  }
}
