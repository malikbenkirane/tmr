import 'package:too_many_tabs/domain/models/settings/special_goal.dart';
import 'package:too_many_tabs/domain/models/settings/special_goals.dart';

class SettingsSummary {
  const SettingsSummary({
    required bool overwriteDatabase,
    required SpecialGoals specialGoals,
    required double signalNoiseRatio,
  }) : _overwriteDatabase = overwriteDatabase,
       _specialGoals = specialGoals,
       _signalNoiseRatio = signalNoiseRatio;

  final bool _overwriteDatabase;
  final SpecialGoals _specialGoals;
  final double _signalNoiseRatio;

  bool get overwriteDatabase => _overwriteDatabase;
  SpecialGoals get specialGoals => _specialGoals;
  double get signalNoiseRatio => _signalNoiseRatio;
  int get noise => () {
    return (100 / (1 + signalNoiseRatio)).toInt();
  }();

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
      'signalNoiseRatio: $signalNoiseRatio',
    ];

    // Join them with commas and wrap in curly braces.
    return '{${parts.join(', ')}}';
  }
}
