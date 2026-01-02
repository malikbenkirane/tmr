import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/domain/models/settings/special_goals.dart';

class SettingsSummary {
  const SettingsSummary({
    required bool overwriteDatabase,
    required SpecialGoals specialGoals,
  }) : _overwriteDatabase = overwriteDatabase,
       _specialGoals = specialGoals;

  final bool _overwriteDatabase;
  final SpecialGoals _specialGoals;

  bool get overwriteDatabase => _overwriteDatabase;
  SpecialGoals get specialGoals => _specialGoals;

  void set(SpecialGoal setting, Duration goal) {
    switch (setting) {
      case SpecialGoal.sitBack:
        _specialGoals.sitBack = goal;
      case SpecialGoal.stoke:
        _specialGoals.stoke = goal;
      case SpecialGoal.slowDown:
        _specialGoals.slowDown = goal;
      case SpecialGoal.startSlow:
        _specialGoals.startSlow = goal;
    }
  }

  @override
  String toString() {
    // Build a list of the key‑value pairs you want to display.
    final parts = <String>[
      'overwriteDatabase: $overwriteDatabase',
      'specialGoals: $specialGoals',
    ];

    // Join them with commas and wrap in curly braces.
    return '{${parts.join(', ')}}';
  }
}
