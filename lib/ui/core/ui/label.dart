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
  searchBarBackground,
  noiseBar,
  signalBar,
  routineToGoalBar,
  routineSignalBar,
  verticalRoutineBar,
  searchChipBackground,
  searchChipForeground,
  searchResultBackground,
  searchPopupBackground,
  etaPomodoro,
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
    case Label.searchBarBackground:
      return colorScheme.surfaceContainer;
    case Label.verticalRoutineBar:
      return colorScheme.primary;
    case Label.searchChipBackground:
      return colorScheme.surfaceContainer;
    case Label.searchChipForeground:
      return colorScheme.primary.withValues(alpha: .7);
    case Label.searchResultBackground:
      return colorScheme.surfaceContainerLow;
    case Label.searchPopupBackground:
      return colorScheme.surface;
    case Label.etaPomodoro:
      return darkMode ? colorScheme.onSurface : colorScheme.secondary;
  }
}
