import 'package:too_many_tabs/domain/models/settings/special_goal.dart';

class SpecialGoalSettingUpdate {
  const SpecialGoalSettingUpdate({required this.setting, required this.goal});

  final SpecialGoal setting;
  final Duration goal;

  @override
  String toString() {
    return 'SpecialGoalSettingUpdate(setting: $setting, goal: $goal)';
  }
}
