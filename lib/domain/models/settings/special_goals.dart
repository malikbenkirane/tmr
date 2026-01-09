import 'package:too_many_tabs/domain/models/settings/special_goal.dart';

class SpecialGoals {
  /// Creates a [SpecialGoals] instance.
  ///
  /// All four durations must be supplied.
  SpecialGoals({
    required this.sitBack,
    required this.stoke,
    required this.startSlow,
    required this.slowDown,
  });

  /// How long you “sit back”.
  Duration sitBack;

  /// How long you “stoke”.
  Duration stoke;

  /// How long you “start slow”.
  Duration startSlow;

  /// How long you “slow down”.
  Duration slowDown;

  /// The sum of all four durations.
  Duration get total => sitBack + stoke + startSlow + slowDown;

  Duration of(SpecialGoal goal) {
    switch (goal) {
      // WIP complete this of() function to be used by _refreshEta
      // at lib/ui/home/widgets/header_eta.dart
      case SpecialGoal.sitBack:
      case SpecialGoal.sitBack:
      case SpecialGoal.sitBack:
      case SpecialGoal.sitBack:
    }
  }

  @override
  String toString() =>
      'SpecialGoals('
      'sitBack: $sitBack, '
      'stoke: $stoke, '
      'startSlow: $startSlow, '
      'slowDown: $slowDown'
      ')';
}
