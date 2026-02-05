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
      return darkMode ? colorScheme.primary : colorScheme.surface;
    case Label.homeAppBarBackground:
    case Label.appBarBackground:
      return darkMode ? colorScheme.onPrimary : colorScheme.onSurface;
  }
}
